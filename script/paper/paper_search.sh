#!/bin/bash
# 论文搜索（合并 s2_search + s2_bulk_search + crossref_search）
# 用法:
#   bash script/paper/paper_search.sh "query" [--mode standard|bulk|crossref|verify] [--year 2020-] [--limit N]
#   bash script/paper/paper_search.sh --mode verify --input <(echo '{"title":"...","doi":"..."}')
# 示例:
#   bash script/paper/paper_search.sh "deep learning"                              # 默认 standard，limit=20
#   bash script/paper/paper_search.sh "deep learning" --mode bulk --year 2020- --limit 50
#   bash script/paper/paper_search.sh "deep learning" --mode crossref --limit 20
#
# 四种模式语义不同，不要混淆:
#   standard : Semantic Scholar /paper/search    （相关性排序，limit ≤ 100）
#   bulk     : Semantic Scholar /paper/search/bulk（支持 year 过滤，limit ≤ 1000，无相关性排序）
#   crossref : CrossRef API（无严格速率限制，作为 S2 429 时的 fallback）
#   verify   : S2 Tier 0 引用校验（DOI 反查 + 标题搜索，NDJSON 输出）

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
INPUT_FILE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode)      MODE="$2"; shift 2 ;;
        --mode=*)    MODE="${1#--mode=}"; shift ;;
        --year)      YEAR_RANGE="$2"; shift 2 ;;
        --year=*)    YEAR_RANGE="${1#--year=}"; shift ;;
        --limit)     LIMIT="$2"; shift 2 ;;
        --limit=*)   LIMIT="${1#--limit=}"; shift ;;
        --input)     INPUT_FILE="$2"; shift 2 ;;
        --input=*)   INPUT_FILE="${1#--input=}"; shift ;;
        *)
            if [[ -z "$QUERY" ]]; then
                QUERY="$1"
            fi
            shift
            ;;
    esac
done

if [[ -z "$QUERY" && "$MODE" != "verify" ]]; then
    echo '{"error": "Usage: paper_search.sh \"query\" [--mode standard|bulk|crossref|verify] [--year 2020-] [--limit N]"}' >&2
    exit 1
fi
if [[ "$MODE" == "verify" && -z "$INPUT_FILE" ]]; then
    echo '{"error": "--mode verify requires --input <file_or_fifo>"}' >&2
    exit 1
fi

# 默认 limit 按 mode 不同
case "$MODE" in
    standard) LIMIT="${LIMIT:-20}" ;;
    bulk)     LIMIT="${LIMIT:-50}" ;;
    crossref) LIMIT="${LIMIT:-20}" ;;
    verify)   LIMIT="" ;;
    *)
        echo "{\"error\": \"Invalid --mode: $MODE (expected standard|bulk|crossref|verify)\"}" >&2
        exit 1
        ;;
esac

if [[ "$MODE" != "verify" ]]; then
    if ! [[ "$LIMIT" =~ ^[1-9][0-9]*$ ]]; then
        echo '{"error": "limit must be a positive integer"}' >&2
        exit 1
    fi
    if [[ "$MODE" == "standard" && "$LIMIT" -gt 100 ]]; then
        echo '{"error": "limit must be <= 100 for --mode standard; use --mode bulk for larger queries"}' >&2
        exit 1
    fi
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

# ---- Levenshtein 相似度计算 ----
# 实现: perl 纯函数 — Python 在 Windows 上可能只有 Store stub
# 阈值来源: PaperOrchestra (Song et al., 2026) 附录 D.3
levenshtein_similarity() {
    local s1="$1" s2="$2"
    perl -e '
use strict;
my ($a, $b) = (lc($ARGV[0]), lc($ARGV[1]));
$a =~ s/^\s+|\s+$//g;
$b =~ s/^\s+|\s+$//g;
if ($a eq "" && $b eq "") { print "1.0"; exit; }
if ($a eq "" || $b eq "") { print "0.0"; exit; }
my @a = split //, $a;
my @b = split //, $b;
my $m = scalar @a;
my $n = scalar @b;
my @dp;
$dp[$_][0] = $_ for 0..$m;
$dp[0][$_] = $_ for 0..$n;
for my $i (1..$m) {
    for my $j (1..$n) {
        $dp[$i][$j] = ($a[$i-1] eq $b[$j-1])
            ? $dp[$i-1][$j-1]
            : 1 + ($dp[$i-1][$j] < $dp[$i][$j-1]
                   ? ($dp[$i-1][$j] < $dp[$i-1][$j-1] ? $dp[$i-1][$j] : $dp[$i-1][$j-1])
                   : ($dp[$i][$j-1] < $dp[$i-1][$j-1] ? $dp[$i][$j-1] : $dp[$i-1][$j-1]));
    }
}
my $mx = $m > $n ? $m : $n;
printf "%.4f", 1 - $dp[$m][$n] / $mx;
' "$s1" "$s2" 2>/dev/null || echo "0.0"
}

# ---- Rate limiting (仅 S2 模式)----
s2_rate_limit_wait() {
    local rate_file="/tmp/.s2_rate_limit"
    local min_interval="${S2_RATE_LIMIT_MIN_INTERVAL:-1}"
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

# S2 认证 header 值（返回 "Header: Value" 字符串，调用方用 -H "..." 包裹）
s2_auth_header_val() {
    if [[ -n "${S2_API_KEY:-}" ]]; then
        echo "${S2_API_KEY_HEADER}: ${S2_API_KEY}"
    fi
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

    verify)
        # S2 Tier 0 引用校验 — 每条 citation 一个 NDJSON verdict
        # 输入: NDJSON, 每行 {"title":"...", "doi":"...", "year":"...", "authors":"..."}
        # 输出: NDJSON, 每行 {"input_title":"...", "verdict":"...", "s2_id":"...", "match_score":N, "hallucination_class":"..."|null, "notes":"..."}
        S2_VERIFY_FIELDS="paperId,title,year,authors,externalIds,venue,citationCount"

        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ -z "$line" ]] && continue

            INPUT_TITLE=$(echo "$line" | jq -r '.title // ""')
            INPUT_DOI=$(echo "$line" | jq -r '.doi // ""' 2>/dev/null || echo "")
            INPUT_YEAR=$(echo "$line" | jq -r '.year // ""' 2>/dev/null || echo "")

            # 清理空值和 null 字符串
            [[ -z "$INPUT_TITLE" || "$INPUT_TITLE" == "null" ]] && continue
            [[ "$INPUT_DOI" == "null" || "$INPUT_DOI" == "None" || "$INPUT_DOI" == "" ]] && INPUT_DOI=""

            VERDICT="S2_NOT_FOUND"
            S2_ID="null"
            MATCH_SCORE="0.0"
            HALLUCINATION_CLASS="null"
            NOTES=""

            if [[ -n "$INPUT_DOI" ]]; then
                # Pattern 2: DOI Lookup
                s2_rate_limit_wait
                AUTH_H=$(s2_auth_header_val)

                RESPONSE=$(curl -s -w "\n%{http_code}" \
                    "${S2_BASE_URL}/graph/v1/paper/DOI:${INPUT_DOI}?fields=${S2_VERIFY_FIELDS}" \
                    ${AUTH_H:+-H "$AUTH_H"} \
                    --max-time 15 2>/dev/null) || true

                HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
                BODY=$(echo "$RESPONSE" | sed '$d')

                if [[ "$HTTP_CODE" == "200" ]] && echo "$BODY" | jq -e '.paperId' > /dev/null 2>&1; then
                    S2_TITLE=$(echo "$BODY" | jq -r '.title // ""')
                    S2_PAPERID=$(echo "$BODY" | jq -r '.paperId // ""')
                    SCORE=$(levenshtein_similarity "$INPUT_TITLE" "$S2_TITLE")
                    MATCH_SCORE="$SCORE"

                    if awk -v s="$SCORE" 'BEGIN { exit (s >= 0.70) ? 0 : 1 }' 2>/dev/null; then
                        VERDICT="VERIFIED"
                        S2_ID="\"$S2_PAPERID\""
                    else
                        VERDICT="DOI_MISMATCH"
                        HALLUCINATION_CLASS='"PAC"'
                        NOTES="DOI resolves but title mismatch (score=$SCORE)"
                    fi
                elif [[ "$HTTP_CODE" == "404" ]]; then
                    VERDICT="S2_NOT_FOUND"
                    NOTES="DOI not found in S2: $INPUT_DOI"
                else
                    VERDICT="S2_UNAVAILABLE"
                    NOTES="S2 API returned HTTP $HTTP_CODE for DOI lookup"
                fi
            else
                # Pattern 1: Title Search
                s2_rate_limit_wait
                AUTH_H=$(s2_auth_header_val)
                ENCODED_TITLE=$(printf '%s' "$INPUT_TITLE" | jq -sRr @uri)

                RESPONSE=$(curl -s -w "\n%{http_code}" \
                    "${S2_BASE_URL}/graph/v1/paper/search?query=${ENCODED_TITLE}&limit=5&fields=${S2_VERIFY_FIELDS}" \
                    ${AUTH_H:+-H "$AUTH_H"} \
                    --max-time 15 2>/dev/null) || true

                HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
                BODY=$(echo "$RESPONSE" | sed '$d')

                if [[ "$HTTP_CODE" == "200" ]]; then
                    RESULT_COUNT=$(echo "$BODY" | jq '.data // [] | length' 2>/dev/null || echo "0")

                    if [[ "$RESULT_COUNT" -gt 0 ]]; then
                        # Compute Levenshtein for all results, pick best
                        BEST_SCORE="0.0"
                        BEST_S2_ID="null"

                        for ((i=0; i<RESULT_COUNT; i++)); do
                            R_TITLE=$(echo "$BODY" | jq -r ".data[$i].title // \"\"")
                            R_SCORE=$(levenshtein_similarity "$INPUT_TITLE" "$R_TITLE")
                            R_YEAR=$(echo "$BODY" | jq -r ".data[$i].year // \"\"")
                            R_ID=$(echo "$BODY" | jq -r ".data[$i].paperId // \"\"")

                            # Prefer higher score; on tie prefer year match
                            IS_BETTER=$(awk -v best="$BEST_SCORE" -v curr="$R_SCORE" -v y1="$INPUT_YEAR" -v y2="$R_YEAR" \
                                'BEGIN { yr = (y1 != "" && y2 != "" && y1 == y2) ? 1 : 0; print (curr > best + 0.0001 || (curr - best >= -0.0001 && curr - best <= 0.0001 && yr)) ? "0" : "1" }')

                            if [[ "$IS_BETTER" == "0" ]]; then
                                BEST_SCORE="$R_SCORE"
                                BEST_S2_ID="\"$R_ID\""
                            fi
                        done

                        MATCH_SCORE="$BEST_SCORE"
                        if awk -v s="$BEST_SCORE" 'BEGIN { exit (s >= 0.70) ? 0 : 1 }' 2>/dev/null; then
                            VERDICT="VERIFIED"
                            S2_ID="$BEST_S2_ID"
                        else
                            VERDICT="S2_NOT_FOUND"
                            NOTES="No result with Levenshtein >= 0.70, best=$BEST_SCORE"
                        fi
                    else
                        VERDICT="S2_NOT_FOUND"
                        NOTES="S2 returned 0 results for title"
                    fi
                else
                    VERDICT="S2_UNAVAILABLE"
                    NOTES="S2 API returned HTTP $HTTP_CODE for title search"
                fi
            fi

            # Output NDJSON
            printf '{"input_title": %s, "verdict": "%s", "s2_id": %s, "match_score": %s, "hallucination_class": %s, "notes": "%s"}\n' \
                "$(echo "$INPUT_TITLE" | jq -Rs '.[:-1]')" \
                "$VERDICT" \
                "$S2_ID" \
                "$MATCH_SCORE" \
                "$HALLUCINATION_CLASS" \
                "$NOTES"
        done < "$INPUT_FILE"
        ;;
esac
