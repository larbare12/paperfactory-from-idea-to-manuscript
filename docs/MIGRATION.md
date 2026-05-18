# 从 paper.skill v1 迁移到 paper-assistant plugin

本文档面向使用过老版 `paper.skill`(单 Claude Code skill 形式)的用户。

---

## 为什么改成 plugin

旧版 `paper.skill` 是**单 skill**——一个 SKILL.md 干完所有事(M0-M9 全装在里面)。痛点:

1. **M0-M9 模块互相提到"调用 paper_search.sh"**,每次都要重复说一遍约束(反幻觉、venue、三段式) —— **citation-search 应该是横切子 skill**
2. **hooks 没有规范的安装入口** —— 用户要么自己抄 settings,要么没配
3. **`/paper:init` 这样的命令在 skill 形态下没法做** —— skill 没有 slash command 机制

Plugin 形态解决:
- 每个 M{n} 是独立 skill,可被 `@` 单独激活
- citation-search 是独立 skill,9 个 M{n} 都引用它
- `/paper-assistant:init` 当首次入口
- hooks 通过 `plugin.json` 自动激活,无需用户复制设置

---

## 目录变化对照表

| 旧路径(v1) | 新路径(plugin) |
|---|---|
| `SKILL.md`(根) | 删除——拆分到各 skill 下 |
| `modules/m{n}-{name}.md` | `skills/m{n}-{name}/SKILL.md` |
| `script/paper/paper_search.sh` | `skills/citation-search/scripts/paper_search.sh` |
| `script/paper/manifest.py` | `skills/citation-search/scripts/manifest.py` |
| `script/paper/{find_evidence,check_material_gaps}.sh` | `skills/citation-search/scripts/{find_evidence,check_material_gaps}.sh` |
| `config/api.json` | `skills/citation-search/config/api.json` |
| `reference/ccf_2026.sqlite` 等数据库 | `skills/citation-search/data/` |
| `reference/literature-research-protocol.md` | 拆成 3 份在 `skills/citation-search/reference/`(literature-research / anti-hallucination / venue-quality) |
| `reference/writing/*`、`reference/research/*` 等 | **不变**,仍在 plugin 根的 `reference/` 下(M3-M9 跨域引用) |
| `templates/*` | **不变** |
| `docs/MANIFEST_SCHEMA.md` | `skills/citation-search/reference/manifest-schema.md` |
| (无对应) | `.claude-plugin/plugin.json` 新增 |
| (无对应) | `commands/init.md` 新增 |
| (无对应) | `hooks/hooks.json` + 4 个 hook 脚本 新增 |

---

## 调用方式变化

### 旧

skill 是"一体化激活",所有 M0-M9 + 工具都自动可用:

```
请帮我做 M2 文献综述
```

### 新

每个 M{n} 是独立 skill,通过 `@` 路由:

```
@m2-literature 帮我做文献综述
```

或在自然语言里提及 skill 用途(Claude 会自动路由):

```
我要做文献综述
```

citation-search 是横切 skill,绝大多数时候**不需要直接 @**——M0-M9 内部自动委托。但你可以在纯检索场景直接调:

```
@citation-search 找 5 篇关于 diffusion 模型的最新综述
```

---

## hooks 变化

### 旧

没有 hooks。所有提醒(NEEDS-EVIDENCE / commit checkpoint / verify_citations)靠用户自己记得跑脚本。

### 新

`plugin.json` 内置 4 个 hook,装上 plugin 即激活:

| Hook | 时机 | 行为 |
|---|---|---|
| SessionStart | 每次启动 session | 检测 `relate-work/` → 跑 verify_config + M0 mini |
| PreToolUse(Write/Edit/MultiEdit) | 写入 draft/ 前 | 累计未提交 >200 行 → 提醒 commit |
| PostToolUse(同上) | 写入 draft/ 后 | 新含 `\cite{}` 但 24h 内未跑 Tier 0 → 提醒;含 `[NEEDS-EVIDENCE]` → 计数提醒 |
| Stop | Claude 准备结束回答 | gap 数变化时提醒 m7 前必清空 |

所有 hook 在**非 paper 项目**(无 `relate-work/`)静默 exit 0,不污染其他 Claude session。

---

## 升级步骤

### 选项 A:全新克隆(推荐)

```bash
# 1. 备份你的论文项目
cp -r /path/to/your-paper-project /path/to/your-paper-project.bak

# 2. 在 Claude Code plugin 路径下放置 paper-assistant
# (参见 Claude Code 文档关于 plugin 安装位置)

# 3. 在论文项目里跑 init
cd /path/to/your-paper-project
claude
> /paper-assistant:init
```

`relate-work/` 内容(manifest.jsonl / pdf/ / ref-*.md)**完全兼容**,不需要迁移。

### 选项 B:就地升级

如果你的 paper.skill v1 已经 git-managed,直接 `git pull` 到本仓库的 `feat/plugin-migration` 或后续 release 分支即可。

旧版 `modules/` / `script/paper/` / `config/`(根)在最后一步会被删除(`chore: remove paper.skill v1 layout`),所以升级前确保:
- 没有自定义脚本依赖 `script/paper/` 旧路径
- 没有外部 reference 指向 `modules/m{n}-*.md`(改为 `skills/m{n}-*/SKILL.md`)

---

## 不变的东西

- **`relate-work/`** 仍是论文项目的产物目录,manifest schema 完全不变
- **`.env` / `.env.example`** 仍在论文项目根(plugin 也带一份示例)
- **`reference/{writing,research,review,compliance}/`** 路径不变,只是从 paper.skill 根迁移到 plugin 根
- **`templates/`** 路径和文件名不变
- 所有反幻觉/venue/三段式工作流的协议**内容**不变,只是从 `reference/literature-research-protocol.md` 一份拆成三份

---

## 常见问题

### Q: 我自己写的脚本引用了 `script/paper/paper_search.sh` 怎么办?

A: 改用 `${CLAUDE_PLUGIN_ROOT}/skills/citation-search/scripts/paper_search.sh`。在 hook / slash command / skill body 内 `${CLAUDE_PLUGIN_ROOT}` 自动可用;在普通 bash 里需要自己设置。

### Q: 我的 `.bib` 文件 / draft.tex 需要改吗?

A: 不需要。plugin 不修改你的论文产物。

### Q: hooks 太吵了能关吗?

A: 可以在用户的 `~/.claude/settings.json` 里覆盖 plugin hooks。但建议先在 paper 项目里用一段时间——所有 hook 都设计了"非 paper 项目静默""不刷屏"的兜底。

### Q: 我同时有非论文项目,hooks 会干扰吗?

A: 不会。所有 hook 第一行检查 `[[ -d "relate-work" ]] || exit 0`。

### Q: M2 老 SKILL.md 里那 5 类幻觉分类法(TF/PAC/IH/PH/SH)去哪了?

A: 搬到 `skills/citation-search/reference/anti-hallucination-protocol.md`(连同 Tier 0 协议细节)。M2 skill 不再重复定义,只链接。

---

## 反馈

本迁移在 `feat/plugin-migration` 分支上进行。如果迁移过程中发现:
- 路径残留指向旧位置
- 跨域 reference 链接打不开
- hook 在你的环境里行为异常

请提 issue 或在仓库内创建讨论。
