---
name: paper-assistant
description: |
  全流程论文写作辅助 Skill。M0 横切 + M1–M9 九模块，从 idea 到投稿提供
  系统化支持：选题诊断、文献管理、实验设计、结构规划、论证设计、写作辅助、
  投稿前总检、同行评审仿真、合规与伦理检查。
---

# 论文写作助手 (Paper Assistant)

> 核心目标：**人只需提供 idea，论文全流程自动化。**

---

## 🚦 初始化检查（首次使用必读，每次新项目复核）

**Agent 在开始任何 M1–M9 任务前，必须先与用户完成下面 3 项确认。任何一项缺失都禁止进入后续模块。**

### Step 1：API 凭据检查
本 Skill 依赖 Semantic Scholar 等外部 API 进行文献检索与引用验证。Agent 必须主动询问用户：

> "在开始之前，请确认你已经设置好 API 凭据：
> 1. 是否已经在项目根目录创建 `.env` 文件？（参考 `.env.example`）
> 2. `S2_API_KEY` 是否已填入有效值？（在 https://www.semanticscholar.org/product/api 申请）
> 3. 是否已安装 Python 依赖（`pip install -r requirements.txt`）？仅 `--mode multi` 需要，其他模式可跳过。
> 如果未设置，我现在帮你检查并指引完成。"

**Agent 操作**：
- 运行 `bash script/paper/verify_config.sh` 验证配置是否就绪
- 若 `.env` 不存在 → 提示用户 `cp .env.example .env` 并填入 `S2_API_KEY`
- 若 `S2_API_KEY=your_api_key_here`（默认占位符） → 拒绝进入 M1/M2，要求先填写真实密钥
- 若用户打算用 `--mode multi`（多源检索）→ 提示 `pip install -r requirements.txt`

### Step 2：config/ 目录检查
所有 API 端点、Header、限流策略都集中在 `config/` 目录下。Agent 必须：

- **先读 [`config/README.md`](config/README.md)**，理解 `api.json` 的字段语义和修改流程
- 询问用户："是否需要修改 `config/api.json` 中的端点（例如使用代理、私有镜像）？"
- 若用户答"否" → 使用默认配置进入下一步
- 若用户答"是" → 引导用户参照 `config/README.md` 修改，修改后再次运行 `verify_config.sh`

### Step 3：Git 工作区检查
确认当前在 git 仓库内、且工作区干净（或用户明确同意在脏工作区上继续）。详见下方"Git 版本控制（强制）"章节。

> ✅ 三项全部通过后，再进入 M1。否则 STOP，向用户报告缺失项。

---

## 🔐 Git 版本控制（强制要求）

**本 Skill 在使用过程中，Agent 必须全程使用 git 进行版本控制。这是硬性约束，不允许跳过。**

### 核心规则

1. **每个模块开始前，新建分支**
   - 命名规范：`<type>/<module>-<short-desc>`
   - 示例：`feat/m1-topic-diagnosis`、`feat/m3-ablation-design`、`docs/m6-intro-draft`、`fix/m7-format-compliance`

2. **每个模块结束后，提交 commit**
   - 提交信息格式：`<type>(<module>): <what changed>`（遵循仓库现有 commit 风格，参见 `git log --oneline`）
   - 示例：`feat(m1): topic feasibility report with 23 candidates`、`feat(m6): draft Introduction §1.1–§1.3`
   - 若一个模块产生多个独立产物（报表、草稿、脚本输出），分多次 commit，不要堆在一起

3. **关键节点必须有 commit 边界**
   - relate-work/ 检索池沉淀完毕 → commit
   - draft 主文件结构变更（章节增删/重写）→ commit
   - 任何脚本生成的报告（citation_verification_report、material_gap_report 等）→ commit
   - **进入 M7/M8/M9 红队/审稿/合规检查前，工作区必须干净**

4. **禁止动作**
   - ❌ 禁止 `git add -A` 一把梭，应明确列出文件
   - ❌ 禁止 `--no-verify` 跳过 hooks
   - ❌ 禁止 `--amend` 修改已合并的 commit
   - ❌ 禁止删除分支前未确认 merge 状态

5. **每次重要修改前**
   - 先 `git status` + `git diff` 确认当前状态
   - 跨模块切换前，确认上一个模块的产物已 commit 或显式 stash

> Agent 在每次进入新模块时，**第一句话必须是**："正在为 M{n} 创建分支 `<branch-name>`，开始前请确认当前工作区状态。"

---

## 📖 必读规范（Required Reading）

进入下表所列模块前，Agent 必须先读完对应 reference 文档。这些规范由 Agent 在运行时自行加载，不在 SKILL.md 内重复。

| 模块 | 必读 reference | 说明 |
|---|---|---|
| M1 选题、M2 文献、M6 写作、M7 总检 | [`reference/literature-research-protocol.md`](reference/literature-research-protocol.md) | 文献检索三段式工作流 + 反幻觉三层验证 + 红线清单 + 常见陷阱 |
| M2 文献（BibTeX 格式） | [`reference/handoff_schemas.md`](reference/handoff_schemas.md) | 模块间数据交接 schema |
| 跨模块 | [`docs/MANIFEST_SCHEMA.md`](docs/MANIFEST_SCHEMA.md) | manifest.jsonl 字段约定 |

各模块文件（`modules/m{1..9}.md`）顶部已嵌入对应 reference 链接，Agent 进入模块时按链接跳转即可。

---

## 📁 项目目录结构

paper.skill 是**工具库**，不是项目仓库。它被多个论文项目共享调用，自身**不存放**任何具体论文的产物。

### Skill 安装目录（本仓库）

```
paper.skill/                          ← $PAPER_SKILL_DIR
├── SKILL.md                          ← 本文件（agent 入口）
├── README.md                         ← 给人看的项目介绍
├── .env.example                      ← S2_API_KEY 等凭据模板
├── requirements.txt                  ← multi-source 检索的 Python 依赖
│
├── modules/                          ← M0–M9 十个模块的详细指引
│   ├── m0-dashboard.md
│   ├── m1-topic.md
│   ├── m2-literature.md
│   ├── m3-experiment.md
│   ├── m4-structure.md
│   ├── m5-argument.md
│   ├── m6-writing.md
│   ├── m7-final-check.md
│   ├── m8-peer-review.md
│   └── m9-compliance-check.md
│
├── script/paper/                     ← 可执行工具（bash + python）
│   ├── verify_config.sh              ← 初始化自检
│   ├── paper_search.sh               ← 文献检索（standard/bulk/multi/verify）
│   ├── multi_source_search.py        ← 三源并发 + BM25 重排核心
│   ├── collect_papers.sh             ← 三段式 Stage 3 封装（add+download+render）
│   ├── manifest.py                   ← manifest.jsonl 维护：add/download/scan/render/prune/list
│   ├── verify_citations.sh           ← 反幻觉 Tier 0 引用核验
│   ├── doi2bibtex.sh                 ← DOI → BibTeX (CrossRef)
│   ├── author_info.sh                ← S2 作者信息查询
│   ├── venue_lookup.sh               ← 会议/期刊查询
│   ├── find_evidence.sh              ← M6 证据查找
│   ├── check_material_gaps.sh        ← M6 [MATERIAL GAP] 扫描
│   ├── load_config.sh                ← 内部：加载 config/api.json
│   └── init.sh                       ← 内部：初始化辅助
│
├── config/                           ← API 端点 / Header / 限流配置
│   ├── README.md                     ← 必读：字段语义和修改流程
│   ├── api.json                      ← S2/CrossRef/OpenAlex/arXiv 端点
│   └── swagger.json
│
├── reference/                        ← 必读规范（M1–M9 按需加载）
│   ├── literature-research-protocol.md  ← 文献检索 + 反幻觉（M1/M2/M6/M7）
│   ├── handoff_schemas.md            ← 模块间交接 schema
│   ├── mode_spectrum.md              ← copilot vs autonomous 行为谱
│   ├── ccf_2026.jsonl / sqlite       ← CCF 期刊会议分级
│   ├── impact_factor.sqlite3         ← JCR 影响因子
│   ├── writing/                      ← 学术写作规范子库
│   ├── research/                     ← 研究方法子库
│   ├── review/                       ← 同行评审子库
│   └── compliance/                   ← PRISMA-trAIce / RAISE 合规子库
│
├── templates/                        ← 15 个结构化输出模板
│   ├── imrad_template.md             ← IMRAD 论文骨架
│   ├── literature_matrix_template.md
│   ├── peer_review_report_template.md
│   └── ...
│
├── docs/                             ← 内部技术文档
│   └── MANIFEST_SCHEMA.md            ← manifest.jsonl 字段约定
│
├── schemas/                          ← JSON schema 定义
└── passport.example.yaml             ← 跨模块 passport 模板（per-paper 拷贝出来用）
```

### 论文项目工作目录（per-paper，**不在本仓库**）

```
<paper-project-dir>/                  ← cwd，例 ~/papers/Y.Nie_EM-SDPD_paper01_2605/
├── relate-work/                      ← M1/M2/M6 写入；SSoT = manifest.jsonl
│   ├── manifest.jsonl                ← 文献清单（脚本维护，不要手动改）
│   ├── manifest.md                   ← 渲染视图（manifest.py render 生成）
│   ├── missing.md                    ← 待人工补全清单
│   ├── search-<slug>-<date>.jsonl    ← multi 模式检索结果
│   ├── ref-<bibkey>.md               ← 精读笔记卡（M2 写入，可选）
│   ├── citation_verification_report_*.md  ← Tier 0 核验报告
│   └── pdf/                          ← OA 自动下载 + 用户手动补全
├── draft/                            ← M4–M6 写作产物
│   ├── outline.md / argument-map.md
│   ├── main.tex / main.md
│   └── sections/
├── references.bib                    ← M2 维护
├── passport.yaml                     ← M0–M9 跨模块 passport（可选）
└── .env                              ← 项目级覆盖（可选）
```

### 典型用法

```bash
# 1. clone skill 一次（位置随意，如 ~/skills/paper.skill）
git clone https://github.com/larbare12/paper.skill.git ~/skills/paper.skill

# 2. 为每篇论文新建一个项目目录
mkdir -p ~/papers/Y.Nie_EM-SDPD_paper01_2605
cd ~/papers/Y.Nie_EM-SDPD_paper01_2605

# 3. 在项目目录下跑 skill 的脚本
bash ~/skills/paper.skill/script/paper/paper_search.sh "..." --mode multi --limit 30 \
     > relate-work/search-emsdpd-$(date +%Y%m%d).jsonl
bash ~/skills/paper.skill/script/paper/collect_papers.sh \
     --search relate-work/search-emsdpd-*.jsonl --bibkeys ...

# 产物自动落到 ~/papers/Y.Nie_EM-SDPD_paper01_2605/relate-work/
# Skill 自身保持干净，可被其他论文项目复用
```

### 环境变量速查

| 环境变量 | 含义 | 何时设置 |
|---|---|---|
| `PAPER_SKILL_DIR` | skill 安装位置 | 通常脚本自动算（基于 `BASH_SOURCE`）；非标准位置可手动 export |
| `PAPER_PROJECT_DIR` | 论文项目工作目录 | 通常用 `cd` 即可（默认 `$PWD`）；从外部调用时显式 export |
| `PAPER_SKILL_ROOT` | （旧）`PAPER_SKILL_DIR` 的别名 | 向后兼容，新代码不用 |
| `PAPER_SKILL_MAILTO` | OpenAlex polite pool 邮箱 | 可选 |
| `S2_API_KEY` | Semantic Scholar API key | 必填，写在 `.env` |

### `.env` 加载优先级

`S2_API_KEY` 是用户级凭据，所有论文项目共享。脚本加载 `.env` 时**优先读项目目录**（如果有），否则回退到 skill 安装目录——既支持"一次配置全局复用"，也支持单项目覆盖。

> Agent 在每次进入 M1（首次检索文献）前，必须：(1) 确认 `pwd` 是论文项目目录而非 skill 仓库；(2) 检查 `relate-work/` 是否存在（不在则 `mkdir`）。**禁止把任何项目产物写到 skill 安装目录里**。

---

## 🧩 模块架构（M0 + M1–M9）

M0 是横切的常驻模块，M1–M9 按"研究 → 写作 → 评审 → 合规 → 投稿"顺序排列。

| 模块 | 名称 | 功能 | 阶段 |
|-----|------|------|------|
| **M0** | [项目仪表盘](modules/m0-dashboard.md) | 扫描 relate-work/ 与草稿，输出"已完成 / 待回填 / 阻塞"报表 | 横切 |
| **M1** | [选题诊断](modules/m1-topic.md) | bulk 搜索做数据驱动的可行性、创新性、契合度评估 | 选题 |
| **M2** | [文献管理](modules/m2-literature.md) | 在 M1 沉淀的检索池上分类、精读、bib 整理、引用验证 | 文献综述 |
| **M3** | [实验设计](modules/m3-experiment.md) | 实验方案、指标、对比方法、消融、显著性检验 | 实验 |
| **M4** | [结构规划](modules/m4-structure.md) | 实验完成后规划 IMRAD 骨架、篇幅、章节边界（**只管骨架**） | 规划 |
| **M5** | [论证设计](modules/m5-argument.md) | 论证主线、跨章节呼应、拒绝模式、反驳预判（**血肉**） | 方法论 |
| **M6** | [写作辅助](modules/m6-writing.md) | 按 M5 论证骨架展开正文；relate-work 优先 + `[NEEDS-EVIDENCE]` 标记 | 撰写 |
| **M7** | [投稿前总检](modules/m7-final-check.md) | A 内容红队（回扫 M3/M5）+ B 格式合规 + C rebuttal 撰写 | 修改 |
| **M8** | [同行评审仿真](modules/m8-peer-review.md) | 多视角审稿模拟 + 编辑决策 + 修改路线图 | 评审 |
| **M9** | [合规与伦理检查](modules/m9-compliance-check.md) | PRISMA-trAIce 17 项 + RAISE 五维度 + AI 披露 + 最终门控 | 合规 / 投稿 |

---

## 🛠 使用方式

### 方式一：流程式（推荐新手）
按顺序调用模块（M0 横切，任何阶段都能查状态）：
```
idea → M1 → M2 → M3 → M4 → M5 → M6 → M7 → M8 → M9 → 投稿
              ↑
          M0 项目仪表盘
```

### 方式二：按需调用（推荐老手）
根据当前卡点选择模块：
- "我的选题可行吗？" → M1
- "不知道当前进度卡在哪儿" → M0
- "文献怎么组织、引用怎么管" → M2
- "实验设计有缺陷" → M3
- "不知道怎么组织论文骨架" → M4
- "论证不充分 / 审稿人会怎么挑" → M5
- "下笔难、找不到论据" → M6
- "投稿前最后总检 / 写 rebuttal" → M7
- "模拟审稿人怎么看我的论文" → M8
- "AI 使用披露 / 伦理合规检查" → M9

### 方式三：全自动
```
输入：idea + 数据
↓
M1–M7 自动串联（M0 持续监控状态）
↓
输出：可投稿论文
```

---

## 📛 项目命名规范

```
姓名_标题_类型0x_年月

例：Y.Nie_EM-SDPD_final_2409
    Z.Wang_DRL-AF_paper02_2407
```

## ✍️ 写作顺序建议

1. **先写**：Method, Experiments（最容易）
2. **后写**：Introduction, Abstract（需要全文视角）
3. **穿插**：Related Work, Results, Discussion
