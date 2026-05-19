#!/bin/bash
# 期刊/会议信息查询（合并 ccf_lookup + if_lookup + venue_info）
# 用法:
#   bash skills/citation-search/scripts/venue_lookup.sh "venue_name" [--mode ccf|if|all]
# 示例:
#   bash skills/citation-search/scripts/venue_lookup.sh "TMI"                    # 默认 all：CCF + IF
#   bash skills/citation-search/scripts/venue_lookup.sh "Nature Medicine" --mode if
#   bash skills/citation-search/scripts/venue_lookup.sh "TMI" --mode ccf
# 返回: JSON 格式

set -e

# 初始化（脚本位置: <PROJECT_ROOT>/scripts/，sqlite 位于 <PROJECT_ROOT>/data/）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PAPER_SKILL_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
DATA_DIR="$PROJECT_ROOT/data"

# 解析参数
NAME=""
MODE="all"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode)
            MODE="$2"
            shift 2
            ;;
        --mode=*)
            MODE="${1#--mode=}"
            shift
            ;;
        *)
            if [[ -z "$NAME" ]]; then
                NAME="$1"
            fi
            shift
            ;;
    esac
done

if [[ -z "$NAME" ]]; then
    echo '{"error": "Usage: bash skills/citation-search/scripts/venue_lookup.sh \"venue_name\" [--mode ccf|if|all]"}' >&2
    exit 1
fi

case "$MODE" in
    ccf|if|all) ;;
    *)
        echo "{\"error\": \"Invalid --mode: $MODE (expected ccf|if|all)\"}" >&2
        exit 1
        ;;
esac

# 数据库路径
CCF_DB="$DATA_DIR/ccf_2026.sqlite"
IF_DB="$DATA_DIR/impact_factor.sqlite3"

# ---- 查询函数 ----

query_ccf() {
    # 输出：JSON 数组
    local limit="${1:-5}"
    if [[ ! -f "$CCF_DB" ]]; then
        echo '[]'
        return
    fi
    local res
    res=$(sqlite3 "$CCF_DB" -json \
        "SELECT acronym, name, rank, field, type, publisher, url
         FROM ccf_2026
         WHERE acronym_alnum LIKE '%${NAME}%'
            OR name LIKE '%${NAME}%'
         LIMIT ${limit};" 2>/dev/null)
    echo "${res:-[]}"
}

query_if() {
    local limit="${1:-5}"
    if [[ ! -f "$IF_DB" ]]; then
        echo '[]'
        return
    fi
    local res
    res=$(sqlite3 "$IF_DB" -json \
        "SELECT journal, factor, jcr, zky
         FROM factor
         WHERE journal LIKE '%${NAME}%'
         ORDER BY factor DESC
         LIMIT ${limit};" 2>/dev/null)
    echo "${res:-[]}"
}

# ---- 按 mode 分发 ----

case "$MODE" in
    ccf)
        if [[ ! -f "$CCF_DB" ]]; then
            echo "{\"error\": \"CCF database not found at $CCF_DB\"}" >&2
            exit 1
        fi
        query_ccf 5 | jq '.[]?'
        ;;

    if)
        if [[ ! -f "$IF_DB" ]]; then
            echo "{\"error\": \"Impact factor database not found. Download from: https://github.com/suqingdong/impact_factor\"}" >&2
            exit 1
        fi
        query_if 5 | jq '.[]?'
        ;;

    all)
        ccf_result=$(query_ccf 3)
        if_result=$(query_if 3)

        ccf_rank=$(echo "$ccf_result" | jq -r '.[0].rank // empty')
        jcr_quartile=$(echo "$if_result" | jq -r '.[0].jcr // empty')
        cas_quartile=$(echo "$if_result" | jq -r '.[0].zky // empty')
        impact_factor=$(echo "$if_result" | jq -r '.[0].factor // empty')

        jq -n \
            --arg query "$NAME" \
            --arg ccf_rank "$ccf_rank" \
            --arg jcr "$jcr_quartile" \
            --arg cas "$cas_quartile" \
            --arg if "$impact_factor" \
            --argjson ccf "$ccf_result" \
            --argjson impact "$if_result" \
            '{
                query: $query,
                summary: {
                    ccf_rank: (if $ccf_rank != "" then $ccf_rank else null end),
                    jcr_quartile: (if $jcr != "" then $jcr else null end),
                    cas_quartile: (if $cas != "" then $cas else null end),
                    impact_factor: (if $if != "" then ($if | tonumber) else null end)
                },
                ccf_details: $ccf,
                impact_details: $impact
            }'
        ;;
esac
