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
source "$SCRIPT_DIR/load_config.sh"

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

# standard 模式上限 100（swagger 硬约束）
if [[ "$MODE" == "standard" && "$LIMIT" -gt 100 ]]; then
    echo '{"error": "limit must be <= 100 for --mode standard; use --mode bulk for larger queries"}' >&2
    exit 1
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
    standard)
        s2_rate_limit_wait

        API_URL="${S2_BASE_URL}/graph/v1/paper/search"
        FIELDS="paperId,title,year,authors,venue,journal,citationCount,externalIds,url,abstract"
        PARAMS="query=${ENCODED_QUERY}&limit=${LIMIT}&fields=${FIELDS}"
        [[ -n "$YEAR_RANGE" ]] && PARAMS="${PARAMS}&year=${YEAR_RANGE}"

        RESPONSE=$(curl -s -w "\n%{http_code}" \
            "${API_URL}?${PARAMS}" \
            ${S2_API_KEY:+-H "$S2_API_KEY_HEADER: $S2_API_KEY"} \
            --max-time 30 2>/dev/null)

        HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
        BODY=$(echo "$RESPONSE" | sed '$d')

        case "$HTTP_CODE" in
            200)
                echo "$BODY" | jq --arg threshold "$ARXIV_THRESHOLD" \
                    ".data[]? | $S2_FORMAT_JQ"
                ;;
            429)
                echo '{"error": "Rate limit exceeded. Wait 1-2 seconds and retry, or use --mode bulk / --mode crossref"}' >&2
                exit 1
                ;;
            *)
                echo "{\"error\": \"HTTP $HTTP_CODE: $(echo "$BODY" | jq -r '.message // .error // "Unknown error"')\"}" >&2
                exit 1
                ;;
        esac
        ;;

    bulk)
        # bulk 端点不接受 limit，最多每页 1000；用 token 分页直到拿够 LIMIT 或没下一页
        # 注：每页落到临时文件而不是 shell 变量，否则 1000 篇 JSON 通过 --argjson
        #     传给 jq 时会撑爆 Windows 32KB 命令行上限
        API_URL="${S2_BASE_URL}/graph/v1/paper/search/bulk"
        FIELDS="title,year,authors,venue,journal,citationCount,externalIds,url,abstract"

        TMPDIR=$(mktemp -d)
        trap 'rm -rf "$TMPDIR"' EXIT

        TOKEN=""
        PAGES=0
        TOTAL_REPORTED=0
        COLLECTED_LEN=0

        while :; do
            s2_rate_limit_wait

            PAGE_PARAMS="query=${ENCODED_QUERY}&fields=${FIELDS}"
            [[ -n "$YEAR_RANGE" ]] && PAGE_PARAMS="${PAGE_PARAMS}&year=${YEAR_RANGE}"
            [[ -n "$TOKEN" ]]      && PAGE_PARAMS="${PAGE_PARAMS}&token=${TOKEN}"

            RESPONSE=$(curl -s -w "\n%{http_code}" \
                "${API_URL}?${PAGE_PARAMS}" \
                ${S2_API_KEY:+-H "$S2_API_KEY_HEADER: $S2_API_KEY"} \
                --max-time 60 2>/dev/null)

            HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
            BODY=$(echo "$RESPONSE" | sed '$d')

            case "$HTTP_CODE" in
                200)
                    PAGE_FILE="$TMPDIR/page_$(printf '%04d' "$PAGES").json"
                    echo "$BODY" | jq '.data // []' > "$PAGE_FILE"
                    PAGE_LEN=$(jq 'length' "$PAGE_FILE")
                    COLLECTED_LEN=$((COLLECTED_LEN + PAGE_LEN))
                    TOTAL_REPORTED=$(echo "$BODY" | jq -r '.total // 0')
                    TOKEN=$(echo "$BODY" | jq -r '.token // ""')
                    PAGES=$((PAGES + 1))
                    ;;
                429)
                    if [[ $PAGES -gt 0 ]]; then
                        echo "{\"warning\": \"Rate limit hit after ${PAGES} pages; returning partial results (${COLLECTED_LEN} papers)\"}" >&2
                        break
                    fi
                    echo '{"error": "Rate limit exceeded. Wait 60 seconds and retry"}' >&2
                    exit 1
                    ;;
                *)
                    if [[ $PAGES -gt 0 ]]; then
                        echo "{\"warning\": \"HTTP $HTTP_CODE after ${PAGES} pages; returning partial results (${COLLECTED_LEN} papers)\"}" >&2
                        break
                    fi
                    echo "{\"error\": \"HTTP $HTTP_CODE: $(echo "$BODY" | jq -r '.message // .error // "Unknown error"')\"}" >&2
                    exit 1
                    ;;
            esac

            # 停机条件：够了 / 没下一页 / 这一页空了
            [[ $COLLECTED_LEN -ge $LIMIT ]] && break
            [[ -z "$TOKEN" ]]               && break
            [[ $PAGE_LEN -eq 0 ]]           && break
        done

        echo "{\"total\": $TOTAL_REPORTED, \"returned\": $COLLECTED_LEN, \"pages\": $PAGES}" >&2
        if [[ $PAGES -gt 0 ]]; then
            jq -s 'add' "$TMPDIR"/page_*.json \
                | jq --arg threshold "$ARXIV_THRESHOLD" --argjson req_limit "$LIMIT" \
                    ".[:\$req_limit][]? | $S2_FORMAT_JQ"
        fi
        ;;

    crossref)
        API_URL="${CROSSREF_BASE_URL}/works"
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
