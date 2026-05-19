#!/usr/bin/env bash
# paperfactory PostToolUse hook (Write|Edit|MultiEdit)
# 写 draft/ 下文件后:
#   - 若新写入的内容含 \cite{...},轻提示运行 verify_citations.sh
#   - 若包含 [NEEDS-EVIDENCE] / [MATERIAL GAP],提示 m0-dashboard 会扫到
# 非 paper 项目 → 静默退出。永远 exit 0。

INPUT=$(cat)

[[ -d "relate-work" ]] || exit 0

if command -v jq >/dev/null 2>&1; then
    file_path=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
else
    file_path=$(echo "$INPUT" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
fi

case "$file_path" in
    *draft/*|*draft\\*)
        ;;
    *)
        exit 0
        ;;
esac

[[ -f "$file_path" ]] || exit 0

# 检查新文件是否含 \cite{...} 或 \citep{...} 或 [@...] 但未跑过 verify_citations
if grep -qE '\\cite[pt]?\{|\[@[a-zA-Z0-9_-]+' "$file_path" 2>/dev/null; then
    # 看最近 24h 是否跑过 verify_citations
    last_report=$(ls -t relate-work/citation_verification_report_*.md 2>/dev/null | head -1)
    if [[ -z "$last_report" ]] || [[ $(find "$last_report" -mtime +1 2>/dev/null) ]]; then
        echo "🔍 检测到新引用 —— 建议跑 citation-search 的 verify_citations.sh 做 Tier 0 校验" >&2
    fi
fi

# NEEDS-EVIDENCE / MATERIAL GAP 标记提醒
if grep -qE '\[NEEDS-EVIDENCE\]|\[MATERIAL GAP:' "$file_path" 2>/dev/null; then
    gap_count=$(grep -oE '\[NEEDS-EVIDENCE\]|\[MATERIAL GAP:' "$file_path" | wc -l | tr -d ' ')
    echo "🟡 该文件含 ${gap_count} 处证据缺口标记 —— m0-dashboard 会汇总" >&2
fi

exit 0
