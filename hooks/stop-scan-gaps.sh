#!/usr/bin/env bash
# paper-assistant Stop hook
# Claude 准备结束本轮回答时:
#   - 若 draft/ 含 [NEEDS-EVIDENCE] / [MATERIAL GAP],提醒用户
# 非 paper 项目 → 静默退出。永远 exit 0(不阻塞 stop)。

[[ -d "relate-work" ]] || exit 0
[[ -d "draft" ]] || exit 0

gap_count=$(grep -roh '\[NEEDS-EVIDENCE\]\|\[MATERIAL GAP:' draft/ 2>/dev/null | wc -l | tr -d ' ')

if [[ "${gap_count:-0}" -gt 0 ]]; then
    # 只在 gap 数变化时提醒,避免每次回答都念
    state_file="relate-work/.last_gap_count"
    last=0
    [[ -f "$state_file" ]] && last=$(cat "$state_file" 2>/dev/null || echo 0)
    if [[ "$gap_count" != "$last" ]]; then
        echo "🟡 draft/ 当前有 ${gap_count} 处 [NEEDS-EVIDENCE]/[MATERIAL GAP] —— 进 m7-final-check 前必须清空" >&2
        echo "$gap_count" > "$state_file"
    fi
fi

exit 0
