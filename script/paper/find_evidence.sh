#!/bin/bash
# find_evidence.sh — 论据自动检索（占位实现，未实现）
#
# 设计意图
# --------
# 当 M6 写作流程提出一个 claim、但在 relate-work/ 中找不到本地证据时，
# 由这个脚本接管"自动找论据"的工作。当前为占位实现：
#   - stderr 报错并 exit 1
#   - M6 流程检测到 exit code != 0 时，应在草稿对应位置标记 [NEEDS-EVIDENCE]
#     而不是阻塞写作
#
# 用法（接口已定，行为待实现）
# ----------------------------
#   bash script/paper/find_evidence.sh "<claim 一句话>"
#
# 未来实现 TODO（按优先级）
# -------------------------
# 1. 把 claim 改写成检索 query（去口语化、抽核心名词、加领域术语）
# 2. 调用 paper_search.sh --mode bulk --year <近5年> --limit 50 拉候选
# 3. 用 venue_lookup.sh 给候选排序（CCF 分级 / IF / 引用量）
# 4. 取 top-N 写入 relate-work/ （JSON + Markdown 摘要两种形式）
# 5. stdout 输出引用建议（DOI、标题、推荐 BibTeX key）供 M6 直接消费
# 6. 失败时降级到 --mode crossref，仍失败才报错退出

set -e

CLAIM="${1:-}"
if [[ -z "$CLAIM" ]]; then
    echo '{"error": "Usage: bash script/paper/find_evidence.sh \"<claim>\""}' >&2
    exit 2
fi

cat >&2 <<EOF
{"error": "find_evidence.sh is not implemented yet",
 "claim": "${CLAIM//\"/\\\"}",
 "next_action": "在 M6 草稿中将该位置标记为 [NEEDS-EVIDENCE]，等本脚本实现后回填",
 "see": "脚本顶部 TODO 列表"}
EOF
exit 1
