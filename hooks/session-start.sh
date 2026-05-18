#!/usr/bin/env bash
# paper-assistant SessionStart hook
# 在 paper 项目目录里启动 session 时:
#   - 跑 verify_config.sh 自检凭据
#   - 输出 M0 mini 状态(NEEDS-EVIDENCE 数 + manifest 状态)
# 非 paper 项目(无 relate-work/)→ 静默退出

set -e

# 检测是否在 paper 项目里(以 relate-work/ 为标识)
if [[ ! -d "relate-work" ]]; then
    exit 0
fi

echo "📝 paper-assistant 已激活($PWD)" >&2

# 凭据自检(失败不阻塞,只警告)
if [[ -x "${CLAUDE_PLUGIN_ROOT}/skills/citation-search/scripts/verify_config.sh" ]]; then
    if ! bash "${CLAUDE_PLUGIN_ROOT}/skills/citation-search/scripts/verify_config.sh" >/dev/null 2>&1; then
        echo "  ⚠️  citation-search 配置不完整 —— 运行 /paper-assistant:init 修复" >&2
    fi
fi

# M0 mini 扫描:NEEDS-EVIDENCE 数 + manifest 状态
gap_count=0
if [[ -d "draft" ]]; then
    gap_count=$(grep -roh '\[NEEDS-EVIDENCE\]\|\[MATERIAL GAP:' draft/ 2>/dev/null | wc -l | tr -d ' ')
fi

manifest_count=0
if [[ -f "relate-work/manifest.jsonl" ]]; then
    manifest_count=$(grep -c '^{' relate-work/manifest.jsonl 2>/dev/null || echo 0)
fi

if [[ "$gap_count" -gt 0 ]]; then
    echo "  🟡 待回填: $gap_count 处 [NEEDS-EVIDENCE]/[MATERIAL GAP]" >&2
fi

if [[ "$manifest_count" -gt 0 ]]; then
    echo "  📚 manifest: $manifest_count 条" >&2
fi

if [[ "$gap_count" -eq 0 && "$manifest_count" -eq 0 ]]; then
    echo "  💡 空项目 —— 建议 @m1-topic 开始选题诊断" >&2
fi

exit 0
