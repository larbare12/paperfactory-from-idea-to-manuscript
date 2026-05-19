#!/usr/bin/env bash
# paper-assistant PreToolUse hook (Write|Edit|MultiEdit)
# 写 draft/ 下文件前提示用户最近 git 状态。
# 非 paper 项目(无 relate-work/)→ 静默退出。
# 永远 exit 0(不阻塞工具调用)。

# stdin 是 hook 输入 JSON,带 tool_input.file_path
INPUT=$(cat)

# 不是 paper 项目就跳过
[[ -d "relate-work" ]] || exit 0

# 解析 file_path(用 jq 优先,无 jq 则 grep fallback)
if command -v jq >/dev/null 2>&1; then
    file_path=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
else
    file_path=$(echo "$INPUT" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
fi

# 只对 draft/ 下的文件触发
case "$file_path" in
    *draft/*|*draft\\*)
        ;;
    *)
        exit 0
        ;;
esac

# 看 draft/ 是否有未提交改动 + 自上次 commit 累计的改动行数
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    dirty_lines=$(git diff --shortstat -- draft/ 2>/dev/null | grep -oE '[0-9]+ insertion|[0-9]+ deletion' | grep -oE '[0-9]+' | awk '{s+=$1} END{print s+0}')
    if [[ "${dirty_lines:-0}" -gt 200 ]]; then
        echo "📝 draft/ 累计未提交改动 ${dirty_lines} 行 —— 建议先 git commit 形成可回滚的 checkpoint" >&2
    fi
fi

exit 0
