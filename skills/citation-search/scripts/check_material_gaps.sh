#!/usr/bin/env bash
# Scans a draft for [MATERIAL GAP: ...] markers
# Exit 0 = clean, exit 1 = found markers (with detail to stderr)
#
# Usage: check_material_gaps.sh <draft_path>
#   or: check_material_gaps.sh --dir <directory>

set -euo pipefail

PATTERN='\[MATERIAL GAP: [^]]+\]'

usage() {
    echo "Usage: $0 <draft_path>" >&2
    echo "   or: $0 --dir <directory>" >&2
    exit 2
}

# --- Parse args ---
TARGET=""
MODE="file"

if [[ $# -lt 1 ]]; then
    usage
fi

if [[ "$1" == "--dir" ]]; then
    MODE="dir"
    if [[ $# -lt 2 ]]; then
        usage
    fi
    TARGET="$2"
elif [[ "$1" == "-" ]]; then
    MODE="stdin"
else
    TARGET="$1"
fi

# --- Validate paths ---
if [[ "$MODE" == "file" && ! -f "$TARGET" ]]; then
    echo "Error: file not found: $TARGET" >&2
    exit 2
fi

if [[ "$MODE" == "dir" && ! -d "$TARGET" ]]; then
    echo "Error: directory not found: $TARGET" >&2
    exit 2
fi

# --- Scan ---
TOTAL=0

if [[ "$MODE" == "stdin" ]]; then
    RESULT=$(grep -nE "$PATTERN" || true)
    if [[ -n "$RESULT" ]]; then
        echo "stdin:$RESULT"
        TOTAL=$(echo "$RESULT" | wc -l)
    fi
elif [[ "$MODE" == "file" ]]; then
    RESULT=$(grep -nE "$PATTERN" "$TARGET" || true)
    if [[ -n "$RESULT" ]]; then
        while IFS= read -r line; do
            linenum="${line%%:*}"
            matched="${line#*:}"
            echo "${TARGET}:${linenum}:${matched}"
            TOTAL=$((TOTAL + 1))
        done <<< "$RESULT"
    fi
else
    # directory mode: scan all regular files recursively
    while IFS= read -r -d '' file; do
        RESULT=$(grep -nE "$PATTERN" "$file" 2>/dev/null || true)
        if [[ -n "$RESULT" ]]; then
            while IFS= read -r line; do
                linenum="${line%%:*}"
                matched="${line#*:}"
                echo "${file}:${linenum}:${matched}"
                TOTAL=$((TOTAL + 1))
            done <<< "$RESULT"
        fi
    done < <(find "$TARGET" -type f -print0)
fi

# --- Summary ---
echo ""
echo "Total [MATERIAL GAP] markers: ${TOTAL}"
if [[ "$TOTAL" -gt 0 ]]; then
    echo "To proceed to M7, all markers must be resolved."
    exit 1
else
    exit 0
fi
