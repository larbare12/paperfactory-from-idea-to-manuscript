---
description: 初始化 paper-assistant 工作环境(凭据+relate-work+manifest+M0 首次扫描)
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# /paper-assistant:init

> 在当前论文项目根目录(`$PWD`)启动 paper-assistant。
> 你(Claude)需要按下面 6 步执行,**每步遇阻就停下问用户**,不要静默跳过。

---

## Step 1 — git 仓库 + 工作区状态

```bash
git rev-parse --is-inside-work-tree 2>/dev/null
git status --short 2>/dev/null
```

- 非 git 仓库 → 问用户:"要 `git init` 吗?(强烈建议,后续 hooks 依赖 git)"
- 有未提交改动 → 列出来,问用户是否先 commit/stash 再继续

## Step 2 — 凭据自检

```bash
# .env 不存在?从 .env.example 复制
[[ -f .env ]] || cp "${CLAUDE_PLUGIN_ROOT}/.env.example" .env

# 跑配置自检
bash "${CLAUDE_PLUGIN_ROOT}/skills/citation-search/scripts/verify_config.sh"
```

- 缺 `S2_API_KEY` → 输出:
  ```
  ⚠️  S2_API_KEY 未配置。请去 https://www.semanticscholar.org/product/api 申请,
  填入 .env: S2_API_KEY=Bearer <your-key>
  ```
- multi mode 需 Python deps,提醒用户:`pip install -r "${CLAUDE_PLUGIN_ROOT}/requirements.txt"`

## Step 3 — 初始化 `relate-work/`

```bash
mkdir -p relate-work/pdf
# manifest.jsonl 不存在?创建 + header
[[ -f relate-work/manifest.jsonl ]] || echo '# manifest.jsonl - one JSON object per line. Schema: skills/citation-search/reference/manifest-schema.md' > relate-work/manifest.jsonl
```

- 已存在 manifest → `wc -l relate-work/manifest.jsonl` 报告条目数

## Step 4 — hooks 状态

hooks 已通过 plugin.json 自动激活(决策 #1: plugin-enforced),**用户无需手动复制**。输出确认:

```
✅ Hooks 已启用:
  - SessionStart: verify_config.sh 自检
  - PreToolUse(write to draft/*.tex): 提示先 git status
  - PostToolUse(write to draft/*.tex): 提示阶段性 commit
  - Stop: 扫 [NEEDS-EVIDENCE] 残留
```

(若 hooks/hooks.json 不存在 → 报错,提示用户 plugin 安装可能不完整)

## Step 5 — M0 仪表盘首次扫描

输出三态报表(模板见 `skills/m0-dashboard/SKILL.md` 的"报表模板"小节)。最小扫描脚本:

```bash
# NEEDS-EVIDENCE / TODO 标记
grep -rn '\[NEEDS-EVIDENCE\]\|TODO\|FIXME' draft/ 2>/dev/null | wc -l

# relate-work 沉淀计数
ls relate-work/search-*.jsonl 2>/dev/null | wc -l
ls relate-work/ref-*.md       2>/dev/null | wc -l
ls relate-work/note-*.md      2>/dev/null | wc -l

# manifest status 分布
jq -r '.status // empty' relate-work/manifest.jsonl 2>/dev/null | sort | uniq -c
```

## Step 6 — 下一步建议

按当前状态分支:

| 当前状态 | 推荐下一步 |
|---|---|
| 空项目(无 draft、manifest 空) | `@m1-topic` —— 先做选题诊断 |
| manifest 有但 draft/ 空 | `@m3-experiment` 或 `@m4-structure` |
| draft/ 有 + 多个 `[NEEDS-EVIDENCE]` | `@m6-writing` —— 先回填证据 |
| draft/ 完整、无 NEEDS-EVIDENCE | `@m7-final-check` —— 进总检 |

---

## 约束

- **路径**:用户的论文项目根是 `$PWD`;plugin 资源在 `${CLAUDE_PLUGIN_ROOT}`。**绝不**把这两个混用。
- **失败原则**:任何一步报错都要把可执行的修复命令贴给用户,不要静默继续。
- **不写 draft**:本命令只动 `.env` / `relate-work/`,不创建任何 `draft/` 文件——那是 M3/M4 的职责。
