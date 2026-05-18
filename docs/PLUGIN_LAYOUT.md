# paper-plugin 重构草案

> 状态：**草案 v0.1**，等待用户审阅后再开始迁移。
> 目标：把 `paper.skill`（单 Skill）重构为 `paper-plugin`（Plugin），
> 把"文献检索 + 引用验证 + venue 质量评估"抽成独立子 skill `citation-search`，
> M0–M9 不再各自重复实现，统一引用 `citation-search`。

---

## 1. 重构动机（一句话）

**当前痛点**：`paper_search.sh`、反幻觉协议、CCF/IF 数据库——这些资产被 M1/M2/M3/M5/M6/M7/M8/M9 共 8 个模块各自零散调用，规范靠 `reference/literature-research-protocol.md` 复制粘贴维持一致性。

**目标状态**：检索 + 验证 + venue 评估**只在一处实现**（`citation-search` skill），其他模块通过 `@citation-search` 调用，规范放在该 skill 自带的 `reference/` 里，单点维护。

---

## 2. 总体目录结构

```
paper-plugin/
├── .claude-plugin/
│   └── plugin.json                       # 插件元数据（name, version, author, skills, commands）
├── skills/
│   ├── citation-search/                  # ⭐ 核心独立 skill（本次重构的重头戏）
│   │   ├── SKILL.md
│   │   ├── reference/
│   │   │   ├── literature-research-protocol.md   # 三段式检索工作流
│   │   │   ├── anti-hallucination-protocol.md    # Tier 0 + Levenshtein
│   │   │   ├── venue-quality-protocol.md         # CCF/IF + arXiv 阈值
│   │   │   └── output-schema.md                  # NDJSON 字段契约 + manifest
│   │   ├── scripts/                              # ← 直接搬 script/paper/，代码不动
│   │   │   ├── paper_search.sh
│   │   │   ├── multi_source_search.py
│   │   │   ├── venue_lookup.sh
│   │   │   ├── verify_citations.sh
│   │   │   ├── author_info.sh
│   │   │   ├── doi2bibtex.sh
│   │   │   ├── find_evidence.sh
│   │   │   ├── check_material_gaps.sh
│   │   │   ├── collect_papers.sh
│   │   │   ├── load_config.sh
│   │   │   ├── verify_config.sh
│   │   │   └── init.sh
│   │   ├── config/
│   │   │   ├── api.json
│   │   │   ├── swagger.json
│   │   │   └── README.md
│   │   └── data/
│   │       ├── ccf_2026.sqlite
│   │       ├── ccf_2026.jsonl
│   │       └── impact_factor.sqlite3
│   ├── m0-dashboard/SKILL.md             # 横切看板
│   ├── m1-topic/SKILL.md
│   ├── m2-literature/SKILL.md            # 重度调用 citation-search
│   ├── m3-experiment/SKILL.md
│   ├── m4-structure/SKILL.md             # 不调用 citation-search
│   ├── m5-argument/SKILL.md
│   ├── m6-writing/SKILL.md
│   ├── m7-final-check/SKILL.md
│   ├── m8-peer-review/SKILL.md
│   └── m9-compliance/SKILL.md
├── commands/
│   ├── paper-init.md                     # /paper:init  —— 凭据 + 工作区检查 + 仪表盘初始化
│   ├── paper-verify.md                   # /paper:verify —— 单点引用校验快捷入口
│   └── paper-venue.md                    # /paper:venue  —— 单点 venue tier 查询
├── reference/                            # 跨 skill 共享的非检索类知识（M3-M9 用）
│   ├── writing/                          # 15 文件，写作风格 / 语言 / 格式
│   ├── research/                         # 12 文件，研究方法论 / 实验设计
│   ├── review/                           # 9 文件，同行评审 / 质量评估
│   ├── compliance/                       # 11 文件，PRISMA-trAIce / RAISE / AI 披露
│   ├── handoff_schemas.md                # 跨阶段数据契约（非检索部分）
│   └── mode_spectrum.md                  # 保真度 vs 原创性频谱
├── templates/                            # 15 个输出模板（IMRAD / poster / review report 等）
├── hooks/                                # 工作流纪律（settings.json 模板）
│   └── settings.template.json
└── docs/
    ├── MANIFEST_SCHEMA.md                # manifest.jsonl 字段约定
    └── MIGRATION.md                      # 从 paper.skill v1 升级指南
```

### 不进 plugin 的东西
- `relate-work/` —— 项目产物，留在用户论文仓库
- `.env` / `.env.example` —— 用户项目根
- 用户论文草稿 / 配图 / 数据

---

## 3. citation-search skill 详细设计

### 3.1 SKILL.md frontmatter（草稿）

```yaml
---
name: citation-search
description: |
  学术文献检索与质量验证。覆盖 Semantic Scholar / CrossRef / arXiv /
  OpenAlex 四源，内置 Tier 0 反幻觉校验（DOI 反查 + Levenshtein ≥ 0.70）
  和 venue quality 过滤（CCF + JCR 影响因子，arXiv 引用阈值）。任何需要
  查文献、验证引用真实性、评估期刊/会议质量、生成 BibTeX、或建立证据
  池的场景都应调用本 skill，而不是让 Claude 凭记忆产出引用。
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---
```

### 3.2 SKILL.md 章节大纲

1. **何时调用本 skill**
   - idea 验证（M1）：检索"有没有人做过"
   - 文献综述（M2）：建立引用网络
   - 找证据（M5）：支撑或反驳某个 claim
   - 写作时实时验证（M6）：每个 `[CITE: ...]` 标记触发一次校验
   - 投稿前 audit（M7）：批量 verify 全文引用
   - 反向检索（M8 评审仿真）：找质疑性文献
   - PRISMA-trAIce 系统检索（M9）

2. **五种检索 mode 速查 + 决策树**

   | mode | 平台 | 用途 | 限制 |
   |---|---|---|---|
   | `standard` | S2 `/paper/search` | 相关性排序首选 | limit ≤ 100 |
   | `bulk` | S2 `/paper/search/bulk` | 大量、year 过滤 | 无相关性排序 |
   | `crossref` | CrossRef `/works` | S2 限流 fallback | 元数据较弱 |
   | `multi` | arXiv + S2 + OpenAlex 并发 + BM25 | 综述用，覆盖最广 | 需 Python deps |
   | `verify` | S2 (DOI 反查 / title 搜索) | Tier 0 真实性校验 | 输入 NDJSON |

   决策树（Mermaid 或文字）：知道 DOI → verify；要相关性排序 → standard；要 bulk + year → bulk；建综述 → multi；S2 限流 → crossref。

3. **必读规范**
   - [`reference/literature-research-protocol.md`](reference/literature-research-protocol.md) —— 三段式工作流
   - [`reference/anti-hallucination-protocol.md`](reference/anti-hallucination-protocol.md) —— Tier 0 三层校验 + 红线清单
   - [`reference/venue-quality-protocol.md`](reference/venue-quality-protocol.md) —— CCF/IF 过滤 + arXiv 引用阈值

4. **输出契约**
   - 标准 mode 输出：单条 JSON / 行
   - verify mode 输出：NDJSON `{input_title, verdict, s2_id, match_score, hallucination_class, notes}`
   - manifest 字段规范（链接到 `docs/MANIFEST_SCHEMA.md`）

5. **错误处理矩阵**
   - HTTP 429 → 切换 mode 或等待
   - `S2_NOT_FOUND` → 是否真不存在 vs S2 数据库缺失
   - `S2_UNAVAILABLE` → 网络/凭据问题
   - `DOI_MISMATCH` → PAC (Plausibly Authored Citation) 红线

6. **与上下游 skill 的交接**
   - 写入约定：`<project>/relate-work/search-{topic}-{date}.json`
   - 读取约定：上游 skill 怎么传 query（关键词 / 完整问题 / DOI 列表）

### 3.3 三份 protocol 怎么拆

当前 `reference/literature-research-protocol.md` 一份吃下了所有内容（三段式 + 反幻觉 + 红线 + 常见陷阱）。拆成三份的好处：M2/M5/M6/M7 各自只链接到具体那份，不必每次让 Claude 读完整篇。

| 拆分后文件 | 内容来源（在原文件中的位置） |
|---|---|
| `literature-research-protocol.md` | 三段式工作流（探索 → 聚焦 → 验证） |
| `anti-hallucination-protocol.md` | Tier 0 三层校验、Levenshtein 阈值、PAC/PCC/PNC 分类、红线清单 |
| `venue-quality-protocol.md` | venue tier 过滤标准、arXiv ≥ 100 引用阈值、NBER WP/SSRN 警告（来自 `feedback_venue_quality` memory） |

### 3.4 代码不动，只改路径变量

`paper_search.sh` 头部已经做过抽象：
```bash
PAPER_SKILL_DIR="${PAPER_SKILL_DIR:-${PAPER_SKILL_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}}"
PAPER_PROJECT_DIR="${PAPER_PROJECT_DIR:-$PWD}"
```

迁移后：
- `PAPER_SKILL_DIR` → 改为指向 `paper-plugin/skills/citation-search/`
- `PAPER_PROJECT_DIR` → 保持指向用户项目根（不变）
- `config/api.json`、`data/*.sqlite` 的相对路径要重新计算

**改动量小**：所有 sh / py 代码本身不动，只调整 `SCRIPT_DIR/../..` 这一类相对定位。

---

## 4. M0–M9 与 citation-search 的引用关系矩阵

| skill | 调用强度 | 典型用法 | 引用方式 |
|---|---|---|---|
| **M0 dashboard** | ★ | 读 `relate-work/` manifest 字段约定 | 引用 `citation-search/reference/output-schema.md` |
| **M1 topic** | ★★★ | "有人做过吗"检索 + 创新性评估 | `mode=multi` → 写 `relate-work/search-m1-*.json` |
| **M2 literature** | ★★★★★ | 全方位：检索 + 验证 + venue 评估 + BibTeX | 五种 mode 都用，重度依赖 |
| **M3 experiment** | ★★ | 检索同类实验设计 / baseline | `mode=standard` |
| **M4 structure** | ☆ | 不直接调用 | — |
| **M5 argument** | ★★★ | 找证据支撑/反驳每条 claim | `find_evidence.sh` + `mode=verify` |
| **M6 writing** | ★★★★ | 写作时实时验证 `[CITE: ...]` 标记 | `mode=verify` 增量 |
| **M7 final-check** | ★★★★ | 全文引用 audit | `mode=verify` 批量 |
| **M8 peer-review** | ★★★ | 反向检索质疑性文献 + venue tier 检验 | `mode=multi` + `venue_lookup.sh` |
| **M9 compliance** | ★★★ | PRISMA-trAIce 系统检索 | `mode=bulk` + year 过滤 |

> **M4 是唯一不依赖 citation-search 的模块**——它只管 IMRAD 骨架和篇幅分配，是好事，说明拆分边界正确。

### 4.1 各 skill SKILL.md 中"工具依赖"段的统一模板

```markdown
## 工具依赖
本模块的所有文献检索 / 验证 / venue 评估 / BibTeX 生成都委托给
`citation-search` skill。**不要在此模块内重新实现检索逻辑或抄写
反幻觉协议——直接引用 citation-search 的对应文件。**

| 任务 | 调用 | 参考规范 |
|---|---|---|
| {本模块的检索任务 A} | `citation-search` mode={x} | `citation-search/reference/{y}.md` |
| {本模块的检索任务 B} | `citation-search/scripts/{z}.sh` | 同上 |
```

---

## 5. 工作流纪律：hooks 设计

当前 SKILL.md 顶上的"Git 强制、`.env` 检查、阶段 commit 边界"靠 prompt 指令维持。拆 skill 后单一指令的强约束力会被稀释，必须用 hooks 真正强制。

### 5.1 推荐 hook 配置（`hooks/settings.template.json`）

| 触发点 | hook 类型 | 行为 |
|---|---|---|
| 第一次进入 paper-plugin 上下文 | `SessionStart` | 跑 `verify_config.sh`，缺凭据就阻断 |
| 进入 M6/M7/M8 skill 前 | `PreToolUse`（特定 skill 触发） | `git status --porcelain` 非空就警告 |
| 任何 `Write`/`Edit` 触及 `draft/*.tex` | `PostToolUse` | 提醒"是否需要 commit" |
| skill 退出 | `Stop` | 检查是否有 `[NEEDS-EVIDENCE]` 未闭合 |

### 5.2 hooks 怎么分发

Claude Code Plugin **可以**附带 hooks 配置（在 `.claude-plugin/plugin.json` 里声明）。但用户的 `~/.claude/settings.json` 本来就允许覆盖——`hooks/settings.template.json` 仅作为参考模板,`/paper:init` 命令可以引导用户把它复制到项目 `.claude/settings.json`。

> **决策点 #1**：hooks 是 plugin 强制配置（plugin.json 内置），还是 `/paper:init` 提示用户手动复制？前者更硬，后者更尊重用户的 settings。

---

## 6. /paper:init 命令设计

```markdown
# /paper:init

初始化 paper-plugin 在当前论文项目中的工作环境。

## 执行内容
1. 检查 git 仓库 + 工作区干净
2. 检查 `.env` 与 `S2_API_KEY` 是否就绪（调用 `citation-search/scripts/verify_config.sh`）
3. 创建 `relate-work/` 目录（如不存在）
4. 创建 `manifest.jsonl`（如不存在，写入 header）
5. 提示用户是否复制 `hooks/settings.template.json` 到 `.claude/settings.json`
6. 输出 M0 仪表盘初始报告（空项目）
```

---

## 7. 迁移步骤（按 git commit 边界）

> 在新分支 `feat/plugin-migration` 上做，每步一个 commit，便于回滚审计。

1. **`feat(plugin): scaffold paper-plugin directory`**
   建空骨架（`.claude-plugin/plugin.json` + `skills/` + `commands/` + `hooks/` + `docs/`），不动任何旧文件。

2. **`feat(citation-search): move scripts and data`**
   `script/paper/*` → `skills/citation-search/scripts/`
   `reference/*.sqlite*` + `*.jsonl` → `skills/citation-search/data/`
   `config/*` → `skills/citation-search/config/`
   修正 `paper_search.sh` 等里的 `PAPER_SKILL_DIR` 路径计算。
   **不动代码，只动路径**。

3. **`feat(citation-search): split literature-research-protocol into three`**
   把 `reference/literature-research-protocol.md` 拆成三份 protocol。

4. **`feat(citation-search): write SKILL.md`**
   按 3.2 节大纲写 SKILL.md。

5. **`feat(commands): /paper:init`**
   写 `commands/paper-init.md`。

6. **`feat(skills): migrate M0 dashboard`** … **`feat(skills): migrate M9 compliance`**
   一个 M 一个 commit，每个 skill：
   - 把 `modules/m{n}.md` 改写成 `skills/m{n}-{name}/SKILL.md`
   - 顶部"工具依赖"段按 4.1 模板写
   - 把跨域 reference 引用改为指向 plugin 根 `reference/`

7. **`feat(hooks): add settings template`**
   写 `hooks/settings.template.json`。

8. **`docs(plugin): write README and MIGRATION`**
   重写 `README.md`，添加 `docs/MIGRATION.md` 指导从 paper.skill v1 升级。

9. **`chore: remove paper.skill v1 layout`**
   删除旧的 `modules/`、`script/paper/`、`config/`、`reference/literature-research-protocol.md` 等已搬运过的文件。**这是最后一步,前面 8 步必须全部通过验证后才做**。

---

## 8. 开放决策（请用户确认）

### #1 hooks 是 plugin 内置强制 vs `/paper:init` 提示复制？
- **A**（强）：`.claude-plugin/plugin.json` 内置 hooks 配置，装上就强制
- **B**（弱）：只提供 `hooks/settings.template.json` 模板，用户决定是否启用

> 倾向 **B**——hooks 影响用户的 git 工作流，强加是粗暴的；提供模板 + `/paper:init` 提示更合适。

### #2 M0-M9 命名要不要保留编号？
- **A**：保留 `m0-dashboard` / `m1-topic` ……（顺序信息明确，但 `@m6-writing` 调用感觉怪）
- **B**：去掉编号 `dashboard` / `topic` / `literature` ……
- **C**：保留编号但 description 里强调用途，让 Claude 优先用 description 路由

> 倾向 **A**——你的工作流编号已经是项目身份的一部分（commit message 里大量使用 `m1:`、`m6:`），保留编号有助于 trace。

### #3 citation-search 的 reference/ 放哪？
- **A**（贴身）：`skills/citation-search/reference/`（本方案当前选择）
- **B**（共享）：plugin 根 `reference/citation-search/`

> 倾向 **A**——三份 protocol 只有 citation-search 自己用，贴身放更内聚；其他 skill 引用时跨 skill 路径明确（这是 feature 不是 bug，能让 Claude 意识到"这是 citation-search 的规范"）。

### #4 `config/api.json` 是否需要复制到项目根？
- **A**：留在 `skills/citation-search/config/`，用户改全局生效
- **B**：`/paper:init` 复制一份到项目 `.paper/config.json`，允许项目级覆盖

> 倾向 **A** 起步——绝大多数项目用默认配置；如果未来真有用户要私有镜像 / 代理，再加 **B** 的覆盖机制。

### #5 `find_evidence.sh` / `check_material_gaps.sh` 算 citation-search 还是 M5？
这两个脚本目前住在 `script/paper/`，但语义上更接近"论证支撑"（M5）和"物料缺口"（M0 仪表盘）。
- **A**：跟着检索能力走，全进 `citation-search/scripts/`
- **B**：按语义拆，`find_evidence.sh` 进 m5，`check_material_gaps.sh` 进 m0

> 倾向 **A**——这两个脚本底层都靠 paper_search 实现，拆开会导致路径依赖跨 skill，维护成本高。

### #6 `paper_search.sh` 五种 mode 是否要拆成五个 wrapper？
当前一个 sh 文件靠 `--mode` 分发，Claude 调用时要记住 mode 名。
- **A**：保持现状（一个 sh）
- **B**：拆成 `search_standard.sh` / `search_bulk.sh` / `search_crossref.sh` / `search_multi.sh` / `verify.sh`，每个一行 `exec paper_search.sh --mode xxx "$@"`

> 倾向 **A**——五种 mode 共享大量公共逻辑（rate limiting、format jq、Levenshtein 函数），拆 wrapper 不能减小代码量；description 里把决策树写清楚即可。

### #7 plugin name 叫什么？
候选：`paper-plugin` / `paper-assistant` / `academic-paper` / `paper-skill`（沿用）
> 建议 `paper-assistant`，与现有 SKILL.md 标题一致；marketplace 上可加前缀如 `larbare/paper-assistant`。

---

## 9. 不动的东西（明确范围）

- ✅ 所有 bash/Python 脚本**代码本身不动**，只调整路径变量定位
- ✅ `multi_source_search.py` 完全不动（已经稳定，BM25 + 三源并发跑通）
- ✅ `ccf_2026.sqlite` / `ccf_2026.jsonl` / `impact_factor.sqlite3` 完全不动
- ✅ 用户的 `relate-work/` 论据池**不进 plugin**
- ✅ `.env` 与 `.env.example` 留项目根

> 这次重构的本质是**目录重组 + 规范单点化**，不是代码重写。代码重写应该是后续单独的项目（如果有必要）。

---

## 10. 验收标准

迁移完成后,以下场景应该跑通:

- [ ] 在一个全新论文项目里 `/paper:init`,凭据检查通过,看到空仪表盘
- [ ] `@citation-search` 输入"transformer attention mechanism",拿到 NDJSON 结果
- [ ] M1 skill 触发时,自动委托给 citation-search,把结果写入 `relate-work/`
- [ ] M6 写作时,在草稿里写 `[CITE: Vaswani 2017 attention]`,Claude 触发 citation-search verify,Levenshtein ≥ 0.70 才接受
- [ ] M7 总检批量验证全文引用,产出 verification 报告
- [ ] hook 在工作区脏的情况下阻止进入 M6/M7
- [ ] 旧 paper.skill 用户跟着 `docs/MIGRATION.md` 能把现有项目对接到新 plugin

---

## 11. 下一步

请审阅本草案,重点看：
1. **第 4 节引用关系矩阵**——M0-M9 各自的强度判断对吗?有没有遗漏的调用场景?
2. **第 7 节迁移步骤**——commit 切分粒度是否合适?有没有该合并或该拆细的?
3. **第 8 节 7 个开放决策**——每条选 A/B/C 或提出第三方案

点头后,我开始执行第 7 节第 1 步(scaffold)。
