#!/bin/bash
# Stage 3 一键收集：add → download → render
# 用法:
#   bash skills/citation-search/scripts/collect_papers.sh \
#       --search relate-work/search-X.jsonl \
#       --bibkeys vaswani-2017-attention,kipf-2017-semi
#
# Stage 2 筛选完成后调用本脚本：把选定的 bibkeys 入 manifest，
# 自动尝试下载 OA PDF，最后渲染 manifest.md + missing.md。
# 缺失的 PDF 由用户手动补全后，跑 `manifest.py scan`。

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAPER_SKILL_DIR="${PAPER_SKILL_DIR:-${PAPER_SKILL_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}}"
PAPER_PROJECT_DIR="${PAPER_PROJECT_DIR:-$PWD}"
export PAPER_SKILL_DIR PAPER_PROJECT_DIR
export PAPER_SKILL_ROOT="$PAPER_SKILL_DIR"  # back-compat alias for downstream scripts

SEARCH=""
BIBKEYS=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --search)        SEARCH="$2"; shift 2 ;;
        --search=*)      SEARCH="${1#--search=}"; shift ;;
        --bibkeys)       BIBKEYS="$2"; shift 2 ;;
        --bibkeys=*)     BIBKEYS="${1#--bibkeys=}"; shift ;;
        -h|--help)
            grep '^#' "$0" | sed 's/^# \?//'
            exit 0 ;;
        *)
            echo "[err] unknown arg: $1" >&2
            exit 2 ;;
    esac
done

if [[ -z "$SEARCH" || -z "$BIBKEYS" ]]; then
    echo "[err] both --search and --bibkeys are required" >&2
    echo "Run with -h for usage." >&2
    exit 2
fi

# Python 解释器探测（同 paper_search.sh）
PYTHON_CMD=()
if command -v py >/dev/null 2>&1 && py -3 -c "import sys" >/dev/null 2>&1; then
    PYTHON_CMD=(py -3)
elif command -v python3 >/dev/null 2>&1 && python3 -c "import sys" >/dev/null 2>&1; then
    PYTHON_CMD=(python3)
elif command -v python >/dev/null 2>&1 && python -c "import sys" >/dev/null 2>&1; then
    PYTHON_CMD=(python)
else
    echo '[err] Python 3 not found.' >&2
    exit 1
fi

MANIFEST_PY="$SCRIPT_DIR/manifest.py"

echo "=== Stage 3.1: add ==="
"${PYTHON_CMD[@]}" "$MANIFEST_PY" add --from-search "$SEARCH" --bibkeys "$BIBKEYS"

echo
echo "=== Stage 3.2: download ==="
"${PYTHON_CMD[@]}" "$MANIFEST_PY" download

echo
echo "=== Stage 3.3: render ==="
"${PYTHON_CMD[@]}" "$MANIFEST_PY" render

echo
echo "✅ Done. Review (in your paper project at $PAPER_PROJECT_DIR):"
echo "  - 全表:        relate-work/manifest.md"
echo "  - 待人工补全:   relate-work/missing.md"
echo "  - 用户补完后跑: ${PYTHON_CMD[*]} $MANIFEST_PY scan"
