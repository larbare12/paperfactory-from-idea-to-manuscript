#!/bin/bash
# 论文搜索（合并 s2_search + s2_bulk_search + crossref_search）
# 用法:
#   bash script/paper/paper_search.sh "query" [--mode standard|bulk|crossref] [--year 2020-] [--limit N]
# 示例:
#   bash script/paper/paper_search.sh "deep learning"                              # 默认 standard，limit=20
#   bash script/paper/paper_search.sh "deep learning" --mode bulk --year 2020- --limit 50
#   bash script/paper/paper_search.sh "deep learning" --mode crossref --limit 20
#
# 三种模式语义不同，不要混淆:
#   standard : Semantic Scholar /paper/search    （相关性排序，limit ≤ 100）
#   bulk     : Semantic Scholar /paper/search/bulk（支持 year 过滤，limit ≤ 1000，无相关性排序）
#   crossref : CrossRef API（无严格速率限制，作为 S2 429 时的 fallback）

set -e

# 初始化（脚本位置: <PROJECT_ROOT>/script/paper/）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PAPER_SKILL_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# 加载配置
if [[ -f "$PROJECT_ROOT/.env" ]]; then
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
fi

# 解析参数
QUERY=""
MODE="standard"
YEAR_RANGE=""
LIMIT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode)      MODE="$2"; shift 2 ;;
        --mode=*)    MODE="${1#--mode=}"; shift ;;
        --year)      YEAR_RANGE="$2"; shift 2 ;;
        --year=*)    YEAR_RANGE="${1#--year=}"; shift ;;
        --limit)     LIMIT="$2"; shift 2 ;;
        --limit=*)   LIMIT="${1#--limit=}"; shift ;;
        *)
            if [[ -z "$QUERY" ]]; then
                QUERY="$1"
            fi
            shift
            ;;
    esac
done

if [[ -z "$QUERY" ]]; then
    echo '{"error": "Usage: bash script/paper/paper_search.sh \"query\" [--mode standard|bulk|crossref] [--year 2020-] [--limit N]"}' >&2
    exit 1
fi

# 默认 limit 按 mode 不同
case "$MODE" in
    standard) LIMIT="${LIMIT:-20}" ;;
    bulk)     LIMIT="${LIMIT:-50}" ;;
    crossref) LIMIT="${LIMIT:-20}" ;;
    *)
        echo "{\"error\": \"Invalid --mode: $MODE (expected standard|bulk|crossref)\"}" >&2
        exit 1
        ;;
esac

if ! [[ "$LIMIT" =~ ^[1-9][0-9]*$ ]]; then
    echo '{"error": "limit must be a positive integer"}' >&2
    exit 1
fi

# year_range 仅对 bulk 模式有效
if [[ -n "$YEAR_RANGE" && "$MODE" != "bulk" ]]; then
    echo "{\"warning\": \"--year is only supported in --mode bulk; ignored\"}" >&2
    YEAR_RANGE=""
fi

ARXIV_THRESHOLD="${ARXIV_CITATION_THRESHOLD:-100}"

# URL 编码查询
ENCODED_QUERY=$(printf '%s' "$QUERY" | jq -sRr @uri)

# ---- arXiv 判断 + 输出格式化（S2 共享 jq 片段）----
S2_FORMAT_JQ='
    (.venue // .journal // "") as $venue |
    ($venue | test("(?i)arxiv")) as $is_arxiv |
    (if $is_arxiv and .citationCount < ($threshold | tonumber) then
        "caution"
     elif $is_arxiv and .citationCount >= ($threshold | tonumber) then
        "recommended"
     else
        "normal"
     end) as $arxiv_status |
    (if $arxiv_status == "caution" then
        "⚠️ arXiv 低引用(" + (.citationCount | tostring) + ")，谨慎引用"
     elif $arxiv_status == "recommended" then
        "✅ 高影响力 arXiv (" + (.citationCount | tostring) + " 引用)"
     else
        "✅ 正式发表"
     end) as $recommendation |
    {
        title: .title,
        year: .year,
        venue: ($venue // "N/A"),
        citations: .citationCount,
        doi: .externalIds.DOI,
        arxiv_id: .externalIds.ArXiv,
        url: .url,
        abstract: (.abstract // ""),
        is_arxiv: $is_arxiv,
        arxiv_status: $arxiv_status,
        recommendation: $recommendation,
        authors: [.authors[]? | {name: .name, id: .authorId}][:3]
    }
'

# ---- Rate limiting (仅 S2 模式)----
s2_rate_limit_wait() {
    local rate_file="/tmp/.s2_rate_limit"
    local min_interval="${S2_MIN_INTERVAL:-1}"
    if [[ -f "$rate_file" ]]; then
        local last_time current_time elapsed
        last_time=$(cat "$rate_file" 2>/dev/null || echo "0")
        current_time=$(date +%s)
        elapsed=$((current_time - last_time))
        if [[ $elapsed -lt $min_interval ]]; then
            sleep $((min_interval - elapsed))
        fi
    fi
    date +%s > "$rate_file"
}

# ---- 按 mode 分发 ----

case "$MODE" in
    standard|bulk)
        s2_rate_limit_wait

        if [[ "$MODE" == "standard" ]]; then
            API_URL="https://api.semanticscholar.org/graph/v1/paper/search"
            FIELDS="paperId,title,year,authors,venue,journal,citationCount,externalIds,url,abstract"
            PARAMS="query=${ENCODED_QUERY}&limit=${LIMIT}&fields=${FIELDS}"
            CURL_TIMEOUT=30
            RATE_LIMIT_HINT="Wait 1-2 seconds and retry, or use --mode bulk / --mode crossref"
        else
            API_URL="https://api.semanticscholar.org/graph/v1/paper/search/bulk"
            FIELDS="title,year,authors,venue,journal,citationCount,externalIds,url,abstract"
            PARAMS="query=${ENCODED_QUERY}&limit=${LIMIT}&fields=${FIELDS}"
            [[ -n "$YEAR_RANGE" ]] && PARAMS="${PARAMS}&year=${YEAR_RANGE}"
            CURL_TIMEOUT=60
            RATE_LIMIT_HINT="Wait 60 seconds and retry"
        fi

        RESPONSE=$(curl -s -w "\n%{http_code}" \
            "${API_URL}?${PARAMS}" \
            ${S2_API_KEY:+-H "x-api-key: $S2_API_KEY"} \
            --max-time "$CURL_TIMEOUT" 2>/dev/null)

        HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
        BODY=$(echo "$RESPONSE" | sed '$d')

        case "$HTTP_CODE" in
            200)
                if [[ "$MODE" == "bulk" ]]; then
                    TOTAL=$(echo "$BODY" | jq -r '.total // 0')
                    RETURNED=$(echo "$BODY" | jq -r '.data | length')
                    echo "{\"total\": $TOTAL, \"returned\": $RETURNED}" >&2
                    echo "$BODY" | jq --arg threshold "$ARXIV_THRESHOLD" --argjson req_limit "$LIMIT" \
                        ".data[:\$req_limit][]? | $S2_FORMAT_JQ"
                else
                    echo "$BODY" | jq --arg threshold "$ARXIV_THRESHOLD" \
                        ".data[]? | $S2_FORMAT_JQ"
                fi
                ;;
            429)
                echo "{\"error\": \"Rate limit exceeded. ${RATE_LIMIT_HINT}\"}" >&2
                exit 1
                ;;
            *)
                echo "{\"error\": \"HTTP $HTTP_CODE: $(echo "$BODY" | jq -r '.message // .error // "Unknown error"')\"}" >&2
                exit 1
                ;;
        esac
        ;;

    crossref)
        API_URL="https://api.crossref.org/works"
        FIELDS="DOI,title,author,published-print,published-online,container-title,is-referenced-by-count,URL"

        RESPONSE=$(curl -s \
            "${API_URL}?query=${ENCODED_QUERY}&rows=${LIMIT}&select=${FIELDS}" \
            --max-time 30 2>/dev/null)

        if [[ -z "$RESPONSE" ]] || echo "$RESPONSE" | jq -e '.message == null' > /dev/null 2>&1; then
            echo '{"error": "CrossRef API request failed"}' >&2
            exit 1
        fi

        echo "$RESPONSE" | jq '.message.items[]? | {
            title: (.title[0] // "N/A"),
            year: ((.["published-print"]["date-parts"][0][0] // .["published-online"]["date-parts"][0][0]) // null),
            venue: (.["container-title"][0] // "N/A"),
            citations: (.["is-referenced-by-count"] // 0),
            doi: .DOI,
            url: .URL,
            authors: ([.author[]? | ((.given // "") + " " + (.family // ""))][:3] | if length > 0 then join(", ") + (if length > 3 then " et al." else "" end) else "N/A" end)
        }'
        ;;
esac
