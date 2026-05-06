#!/bin/bash
# find_evidence.sh — 论据自动检索（corpus-first / search-fills-gap）
#
# ============================================================================
# 4 IRON RULES (永不违反)
# ============================================================================
# 1. Same standard: 本地 corpus 和远程 S2 使用相同的检索标准。
#    当本地有结果时，不得隐式放宽搜索条件。
# 2. No silent skip: 如果任何地方都找不到证据，必须以 exit code 2
#    退出并输出结构化错误 JSON，绝不得 exit 0 + 空结果。
# 3. No mutation: 绝不修改 relate-work/ 目录中的任何文件（只读访问）。
# 4. Graceful degradation: 如果 S2 API 失败（网络、限速、5xx），
#    降级为仅本地搜索并在 stderr 记录 [S2-API-UNAVAILABLE]，
#    绝不使整个管线崩溃。
# ============================================================================
#
# 输出: NDJSON（每行一个 JSON 对象）
# Schema:
#   {"source":"local"|"s2","title":"...","authors":[...],"year":int|null,
#    "doi":"..."|null,"match_score":float,"path_or_url":"..."}
# ============================================================================

# 初始化
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAPER_SKILL_DIR="${PAPER_SKILL_DIR:-${PAPER_SKILL_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}}"
PAPER_PROJECT_DIR="${PAPER_PROJECT_DIR:-$PWD}"
PROJECT_ROOT="${PAPER_SKILL_DIR}"  # back-compat alias for load_config.sh
RELATE_DIR="$PAPER_PROJECT_DIR/relate-work"

source "$SCRIPT_DIR/load_config.sh" 2>/dev/null || true

# ---- 参数解析 ----
CLAIM=""
TOPIC=""
LIMIT=5
YEAR_FROM=""
OUTPUT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --topic)     TOPIC="$2"; shift 2 ;;
        --topic=*)   TOPIC="${1#--topic=}"; shift ;;
        --limit)     LIMIT="$2"; shift 2 ;;
        --limit=*)   LIMIT="${1#--limit=}"; shift ;;
        --year-from) YEAR_FROM="$2"; shift 2 ;;
        --year-from=*) YEAR_FROM="${1#--year-from=}"; shift ;;
        --output)    OUTPUT="$2"; shift 2 ;;
        --output=*)  OUTPUT="${1#--output=}"; shift ;;
        -*)
            echo "{\"error\": \"Unknown option: $1\"}" >&2
            exit 1
            ;;
        *)
            if [[ -z "$CLAIM" ]]; then CLAIM="$1"; fi
            shift
            ;;
    esac
done

if [[ -z "$CLAIM" ]]; then
    echo '{"error": "Usage: bash script/paper/find_evidence.sh \"<claim>\" [--topic STR] [--limit N] [--year-from YYYY] [--output FILE]"}' >&2
    exit 1
fi

# 默认 topic = claim
TOPIC="${TOPIC:-$CLAIM}"

# ---- 临时文件 ----
TMPDIR_WORK=$(mktemp -d)
trap 'rm -rf "$TMPDIR_WORK"' EXIT
RESULTS_FILE="$TMPDIR_WORK/results.ndjson"
: > "$RESULTS_FILE"

# ---- 工具函数 ----

# Dedupe NDJSON by title (case-insensitive), keep first occurrence
dedup_by_title() {
    local infile="$1"
    [[ -s "$infile" ]] || return 0
    awk -F'"title":"' '
    {
        split($2, a, "\"")
        key = tolower(a[1])
        if (!(key in seen)) {
            seen[key] = 1
            print
        }
    }
    ' "$infile"
}

# ---- Step A: Search relate-work/ corpus ----
search_local() {
    local topic="$1"

    local pattern="$topic"

    # Check if relate-work/ has any evidence files (exclude README.md)
    local file_count
    file_count=$(find "$RELATE_DIR" -maxdepth 1 -type f \( -name '*.json' -o -name '*.md' \) ! -name 'README.md' 2>/dev/null | wc -l)

    if [[ "$file_count" -eq 0 ]]; then
        echo "[LOCAL] No evidence files in relate-work/" >&2
        return 0
    fi

    # Search JSON files (search-*.json from paper_search.sh output)
    if compgen -G "$RELATE_DIR/search-*.json" >/dev/null 2>&1; then
        for json_file in "$RELATE_DIR"/search-*.json; do
            [[ -f "$json_file" ]] || continue

            # Check if file content matches topic
            if ! grep -qi "$pattern" "$json_file" 2>/dev/null; then
                continue
            fi

            local rel_path="${json_file#$PAPER_PROJECT_DIR/}"
            local score="0.3"

            # Extract individual paper entries from JSON array using jq
            jq -c --arg pat "$pattern" --arg score "$score" --arg rpath "$rel_path" '
                .[]? |
                select(.title != null and .title != "") |
                select(
                    ((.title | test($pat; "i")) or
                     ((.abstract // "") | test($pat; "i")) or
                     ((.venue // "") | test($pat; "i")))
                ) |
                {
                    source: "local",
                    title: .title,
                    authors: ([.authors[]?.name // .authors // empty][:5]),
                    year: (if .year and (.year | tostring | test("^[0-9]+$")) then .year else null end),
                    doi: (.doi // null),
                    match_score: ($score | tonumber),
                    path_or_url: $rpath
                }
            ' "$json_file" 2>/dev/null >> "$RESULTS_FILE" || true
        done
    fi

    # Search markdown files (note-*.md, ref-*.md, search-*.md)
    local md_files
    md_files=$(find "$RELATE_DIR" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' 2>/dev/null)

    if [[ -n "$md_files" ]]; then
        while IFS= read -r md_file; do
            [[ -f "$md_file" ]] || continue

            local filename
            filename=$(basename "$md_file")
            local in_filename=false
            local in_content=false

            # Check filename match
            if echo "$filename" | grep -qi "$pattern" 2>/dev/null; then
                in_filename=true
            fi

            # Check content match
            if grep -qi "$pattern" "$md_file" 2>/dev/null; then
                in_content=true
            fi

            if [[ "$in_filename" == false && "$in_content" == false ]]; then
                continue
            fi

            local rel_path="${md_file#$PAPER_PROJECT_DIR/}"
            local score
            if [[ "$in_filename" == true ]]; then
                score="0.6"
            else
                score="0.3"
            fi

            # Extract metadata from markdown content
            local title year doi authors_json

            # Title: first # heading, or filename
            title=$(grep -m1 '^# ' "$md_file" 2>/dev/null | sed 's/^# *//' | head -1)
            if [[ -z "$title" ]]; then
                title=$(sed -n '/^---$/,/^---$/p' "$md_file" 2>/dev/null | grep -m1 '^title:' | sed 's/^title: *//;s/^"//;s/"$//')
            fi
            if [[ -z "$title" ]]; then
                title="$filename"
            fi

            # Year: 4-digit number in content
            year=$(grep -oP '\b(19|20)\d{2}\b' "$md_file" 2>/dev/null | head -1)
            if [[ -z "$year" ]]; then
                year="null"
            fi

            # DOI
            doi=$(grep -oiP '10\.\d+/[^\s"<>]+' "$md_file" 2>/dev/null | head -1)
            if [[ -z "$doi" ]]; then
                doi="null"
            fi

            # Authors: after "Author(s)" label or from bibtex author field
            local authors_raw
            authors_raw=$(grep -iP '^(authors?|author)\s*[:=]' "$md_file" 2>/dev/null | head -1 | sed 's/^[^:=]*[:=]\s*//' | sed 's/\s*$//')
            if [[ -n "$authors_raw" ]]; then
                authors_json=$(echo "$authors_raw" | jq -Rc '[split(",")[] | select(length > 0) | gsub("^\\s+|\\s+$";"")]')
            else
                authors_json="[]"
            fi

            printf '{"source":"local","title":%s,"authors":%s,"year":%s,"doi":%s,"match_score":%s,"path_or_url":"%s"}\n' \
                "$(echo "$title" | jq -Rc .)" \
                "$authors_json" \
                "$year" \
                "$([ "$doi" = "null" ] && echo "null" || echo "$doi" | jq -Rc .)" \
                "$score" \
                "$rel_path" >> "$RESULTS_FILE"

        done <<< "$md_files"
    fi

    local local_count
    local_count=$(wc -l < "$RESULTS_FILE" | tr -d ' ')
    if [[ "$local_count" -eq 0 ]]; then
        echo "[LOCAL] 0 matches for topic: $topic" >&2
    else
        echo "[LOCAL] $local_count matches found" >&2
    fi
}

# ---- Step B: S2 search (gap-filling) ----
search_remote() {
    local topic="$1"
    local remaining="$2"
    local year_arg=""

    if [[ -n "$YEAR_FROM" ]]; then
        year_arg="--year"
    fi

    # Call paper_search.sh — all errors go to stderr
    local remote_output
    remote_output=$(bash "$SCRIPT_DIR/paper_search.sh" "$topic" \
        --mode standard \
        --limit "$remaining" \
        $year_arg "$YEAR_FROM" \
        2>/tmp/s2_stderr_$$) || {
        cat /tmp/s2_stderr_$$ >&2 2>/dev/null
        echo "[S2-API-UNAVAILABLE] S2 search failed; returning local-only results" >&2
        rm -f /tmp/s2_stderr_$$
        return 1
    }
    rm -f /tmp/s2_stderr_$$

    if [[ -z "$remote_output" ]]; then
        echo "[S2] 0 results returned" >&2
        return 0
    fi

    # Validate and format as NDJSON
    local s2_count
    s2_count=$(echo "$remote_output" | jq -c --arg rpath "s2://semantic-scholar" '
        select(.title != null and .title != "") |
        {
            source: "s2",
            title: .title,
            authors: ([.authors[]?.name // .authors // empty][:5]),
            year: (if .year and (.year | tostring | test("^[0-9]+$")) then .year else null end),
            doi: (.doi // null),
            match_score: 0.5,
            path_or_url: (.url // $rpath)
        }
    ' 2>/dev/null | tee -a "$RESULTS_FILE" | wc -l)

    echo "[S2] $s2_count results from S2" >&2
}

# ---- Main Execution ----

# Step A: Search local corpus first
search_local "$TOPIC"

local_count=$(wc -l < "$RESULTS_FILE" | tr -d ' ')

# Step B: Decide whether to call S2 search
if [[ "$local_count" -ge "$LIMIT" ]]; then
    echo "[INFO] Local matches ($local_count) >= limit ($LIMIT), skipping S2 search" >&2
elif [[ "$local_count" -eq 0 ]]; then
    echo "[INFO] No local matches, calling S2 search to find evidence" >&2
    search_remote "$TOPIC" "$LIMIT" || true
else
    remaining=$((LIMIT - local_count))
    echo "[INFO] $local_count local matches < limit ($LIMIT), calling S2 for $remaining more" >&2
    search_remote "$TOPIC" "$remaining" || true
fi

# ---- Dedup and Output ----
DEDUPED_FILE="$TMPDIR_WORK/deduped.ndjson"
dedup_by_title "$RESULTS_FILE" > "$DEDUPED_FILE"

final_count=$(wc -l < "$DEDUPED_FILE" | tr -d ' ')

if [[ "$final_count" -eq 0 ]]; then
    # IRON RULE 2: No silent skip — structured error, exit 2
    echo "{\"error\": \"No evidence found\", \"claim\": $(echo "$CLAIM" | jq -Rc .), \"topic\": $(echo "$TOPIC" | jq -Rc .), \"searched_local\": true, \"searched_remote\": true}" >&2
    exit 2
fi

# Output
if [[ -n "$OUTPUT" ]]; then
    cp "$DEDUPED_FILE" "$OUTPUT"
    echo "[INFO] $final_count evidence items written to $OUTPUT" >&2
else
    cat "$DEDUPED_FILE"
fi
