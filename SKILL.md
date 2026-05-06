---
name: paper-assistant
description: |
  全流程论文写作辅助 Skill。基于 Relic 论文的八层提取法，整合 academic-research-skills (ARS) 
  的丰富 prompt 资产，形成 M0-M9 十模块架构，从 idea 到投稿提供系统化支持。
  
  使用场景：
  (1) 评估研究选题的可行性和创新性
  (2) 规划论文结构和论证逻辑
  (3) 管理文献和引用格式
  (4) 设计完整的实验方案
  (5) 学术写作语言润色
  (6) 模拟同行评审预判问题
  (7) 投稿前格式与合规检查
---

# 论文写作助手 (Paper Assistant)

## 快速开始

本 Skill 旨在实现：**人只需提供 idea，论文全流程自动化**。

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
- 若用户打算用 `--mode multi`（多源检索）→ 提示 `pip install -r requirements.txt`（rank-bm25 + arxiv + requests）

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

## ⚠️ 反幻觉硬约束（Anti-Hallucination）

**论文检索（M1/M2）完成后，所有引用必须经过真实性验证才能进入 M6 写作。这是最严重的红线，违反将导致论文撤稿风险。**

### 三层验证机制

#### Layer 1：来源验证（每篇文献入库时）
- 任何文献从外部进入 `relate-work/` 之前，必须有可验证的来源标识：DOI / arXiv ID / Semantic Scholar paperId 至少一个
- 没有标识符的"凭印象引用" → 直接丢弃，不允许"先写上再说"
- 检索结果必须通过 `script/paper/paper_search.sh` 或同等脚本获得，禁止 Agent 自行"回忆"论文标题、作者、年份

#### Layer 2：引用验证（写作阶段，每次新增 \cite 时）
- 草稿中每个 `\cite{key}` 或 `[@key]` 必须在 `references.bib` 中有完整条目
- 进入 M7 前必须运行：
  ```bash
  bash script/paper/verify_citations.sh relate-work/draft.tex --bib relate-work/references.bib
  ```
- 报告会按"五类幻觉分类"（虚构标题、错配作者、年份偏差、虚假 venue、不存在 DOI）输出
- **任何 Tier 0（高风险）幻觉未消除 → 禁止进入 M7**

#### Layer 3：内容一致性（论证阶段）
- 引用论文的核心论点、数值、结论，Agent 不得复述记忆，必须从 `relate-work/manifest.jsonl` 中 status=`downloaded`/`user-supplied` 的论文全文里摘录（v0.6+：以 manifest 为唯一权威清单）
- 若 manifest 中该 bibkey 的 status=`missing` 或 `pending`（PDF 尚未到位）→ 标记 `[NEEDS-EVIDENCE]` 并在 M6 检查中回填
- 见 [M6 写作辅助](modules/m6-writing.md) 的 "MATERIAL GAP IRON RULE"

### 红线清单（任何一条触发立即 STOP）

- 🚫 用模型记忆引用 2024 年之后的论文（知识截止前后的论文都不可信）
- 🚫 凭"似乎读过"补全 BibTeX 字段（作者、期刊、卷号、页码）
- 🚫 把 arXiv 预印本当作正式期刊版本引用
- 🚫 跳过 `verify_citations.sh` 直接进入 M7

> Agent 在 M2 结束、M6 进入前、M7 进入前 **三个时点**，必须主动运行 `verify_citations.sh` 并把报告路径告诉用户。

---

## 📁 项目目录结构（v0.6+ 重要约定）

> **paper.skill 是工具库，不是项目仓库。** 它被多个论文项目共享调用，自身**不存放**任何具体论文的产物（manifest、PDF、草稿）。

### 两类目录的明确区分

| 类型 | 路径变量 | 默认值 | 内容 |
|---|---|---|---|
| **Skill 安装目录**（共享） | `$PAPER_SKILL_DIR` | 脚本所在仓库根（`paper.skill/`）| `script/`、`config/`、`modules/`、`reference/`、`docs/`、`templates/` |
| **论文项目工作目录**（per-paper） | `$PAPER_PROJECT_DIR` | 当前 cwd（`pwd`） | `relate-work/`、`draft/`、`references.bib`、`.env`（可选）|

**典型用法**：

```bash
# 1. clone skill 一次（放到方便的位置，如 ~/skills/paper.skill）
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

### 推荐的论文项目目录结构

```
<paper-project-dir>/                 ← cwd，例 ~/papers/Y.Nie_EM-SDPD_paper01_2605/
├── relate-work/                     ← M1/M2/M6 写入；single source of truth = manifest.jsonl
│   ├── manifest.jsonl               ← 文献清单（脚本维护，不要手动改）
│   ├── manifest.md                  ← 渲染视图（manifest.py render 生成）
│   ├── missing.md                   ← 待人工补全清单（manifest.py render 生成）
│   ├── search-<slug>-<date>.jsonl   ← multi 模式的检索结果
│   ├── ref-<bibkey>.md              ← 精读笔记卡（M2 写入，可选）
│   ├── citation_verification_report_*.md  ← Tier 0 引用核验报告（verify_citations.sh）
│   └── pdf/                         ← OA PDF 自动下载 + 用户手动补全
│       ├── vaswani-2017-attention.pdf
│       └── ...
├── draft/                           ← M4-M6 写作产物
│   ├── outline.md                   ← M4 章节骨架
│   ├── argument-map.md              ← M5 论证设计
│   ├── main.tex / main.md           ← 主文
│   └── sections/                    ← 分章节草稿
├── references.bib                   ← M2 维护的 BibTeX 文件
├── passport.yaml                    ← M0-M9 跨模块 passport（可选）
└── .env                             ← 项目级覆盖（可选；默认用 skill 安装目录的 .env）
```

### 为什么 .env 默认放在 skill 安装目录？

`S2_API_KEY` 是用户级凭据，所有论文项目共享。脚本加载 `.env` 时**优先读项目目录**（如果有），否则回退到 skill 安装目录——既支持"一次配置全局复用"，也支持单项目覆盖。

### 环境变量速查

| 环境变量 | 含义 | 何时设置 |
|---|---|---|
| `PAPER_SKILL_DIR` | skill 安装位置 | 通常脚本自动算（基于 BASH_SOURCE）；非标准位置可手动 export |
| `PAPER_PROJECT_DIR` | 论文项目工作目录 | 通常用 `cd` 即可（默认 `$PWD`）；从外部调用时显式 export |
| `PAPER_SKILL_ROOT` | （旧）SKILL_DIR 的别名 | 向后兼容 v0.5 之前的脚本，新代码不用 |
| `PAPER_SKILL_MAILTO` | OpenAlex polite pool 邮箱 | 可选，进 polite 通道用 |
| `S2_API_KEY` | Semantic Scholar API key | 必填，写在 `.env` |

> Agent 在每次进入 M1（首次检索文献）前，必须：(1) 确认当前 cwd 就是论文项目目录（`pwd` 显示的是 `<paper-project-dir>` 而非 skill 仓库），(2) 检查 `relate-work/` 是否存在（不在则 `mkdir`）。**禁止把任何项目产物写到 skill 安装目录里**。

---

## 📚 文献检索三段式工作流（v0.6+）

**首次检索 / 写作中补充检索 / 综述章节扩展，统一走这三段。** 不再有"Agent 拿到 search 结果后人工逐篇下载 PDF"的乱流——所有重复操作脚本化以省 token。

### Stage 1：广搜

```bash
bash script/paper/paper_search.sh "<query>" --mode multi --year 2020- --limit 30 \
     > relate-work/search-<slug>-$(date +%Y%m%d).jsonl
```

三源（arXiv + S2 + OpenAlex）并发 + BM25 重排（v0.5 已有）。每条记录含新字段 `pdf_url` / `pdf_status` / `s2_paper_id` / `openalex_id`，供 Stage 3 使用。

### Stage 2：筛选

Agent 阅读 search-*.jsonl，**用判断力**决定哪些与本工作真正相关（基础/方法/对比/相关四类，对应 manifest 的 `tags` 字段）。**Agent 不亲手写 JSONL**，调 helper 批量入表：

```bash
bash script/paper/collect_papers.sh \
     --search relate-work/search-<slug>-<date>.jsonl \
     --bibkeys vaswani-2017-attention,kipf-2017-semi,...
```

bibkey 算法：`<第一作者姓 ascii lower>-<年>-<标题前2个非停用词>`，例 `vaswani-2017-attention`。冲突自动加 `-2`/`-3` 后缀。Agent 选 bibkey 时可以先 dry-run 看候选：

```bash
py -3 -c "
import sys, json
sys.path.insert(0, 'script/paper')
from manifest import make_bibkey
with open('relate-work/search-X.jsonl') as f:
    taken = set()
    for line in f:
        e = json.loads(line)
        bk = make_bibkey(e, taken); taken.add(bk)
        print(bk, '|', e['title'][:60])
"
```

### Stage 3：收集（脚本自动）

`collect_papers.sh` 内部按顺序跑：

1. `manifest.py add` —— 把选定的 bibkeys 入 `relate-work/manifest.jsonl`，status=`pending`
2. `manifest.py download` —— 优先 arxiv 直链 > OpenAlex `best_oa_location` > S2 `openAccessPdf`，成功的 PDF 落 `relate-work/pdf/<bibkey>.pdf` 并设 status=`downloaded`，失败的设 status=`missing`
3. `manifest.py render` —— 生成 `manifest.md`（全表）+ `missing.md`（待人工补全清单 + 建议来源链接）

### Stage 4：用户人工补全闭源

闭源期刊（IEEE Trans / Elsevier / 部分 Springer）拿不到 OA PDF。Agent 把 `relate-work/missing.md` 显示给用户，用户从机构订阅手动下载，重命名为 `<bibkey>.pdf` 放进 `relate-work/pdf/`，再跑：

```bash
py -3 script/paper/manifest.py scan      # 检测新 PDF，状态变 user-supplied
```

### Stage 5：删除找不到的

对仍 missing 的，用户也无法找到时，向用户确认后从 manifest 移除：

```bash
py -3 script/paper/manifest.py prune          # 交互式 y/n
py -3 script/paper/manifest.py prune --yes    # 批量
```

### 状态语义（manifest.jsonl 的 `status` 字段）

| status | 含义 |
|---|---|
| `pending` | 刚 add，尚未尝试下载 |
| `downloaded` | 脚本自动 OA 下载成功 |
| `user-supplied` | 用户手动放进来后被 scan 识别 |
| `missing` | 下载失败，无 OA URL，等用户补 |
| `manual` | 用户标记不下载（保留元数据，不索取 PDF） |

详细字段约定见 [`docs/MANIFEST_SCHEMA.md`](docs/MANIFEST_SCHEMA.md)。

> Agent 在 M1 末尾必须执行 Stage 1+2+3 一轮，把候选论文落到 manifest。M6 写作时检索补充文献，同样走这三段。**绝对禁止跳过 manifest 直接 cite 论文**——Layer 3 验证以 manifest.jsonl 为权威清单。

---

### 模块架构（M0 + M1–M9）

基于 [Relic 论文](https://arxiv.org/abs/2604.16116) 的八层提取法思想，并整合 [academic-research-skills](https://github.com/) 的 prompt 资产，扩展为 1+9 架构：M0 是横切的常驻模块，M1–M9 按"研究 → 写作 → 评审 → 合规 → 投稿"的真实顺序排列。

| 模块 | 名称 | 功能 | 对应阶段 |
|-----|------|------|---------|
| **M0** | [项目仪表盘](modules/m0-dashboard.md) | 扫描 relate-work/ 与草稿，输出"已完成 / 待回填 / 阻塞"报表 | 横切（任何阶段可调） |
| **M1** | [选题诊断](modules/m1-topic.md) | 用 bulk 搜索做数据驱动的可行性、创新性、契合度评估 | 选题 |
| **M2** | [文献管理](modules/m2-literature.md) | 在 M1 沉淀的检索池上分类、精读、bib 整理、引用验证 | 文献综述 |
| **M3** | [实验设计](modules/m3-experiment.md) | 实验方案、指标、对比方法、消融、显著性检验 | 实验 |
| **M4** | [结构规划](modules/m4-structure.md) | 实验完成后规划 IMRAD 骨架、篇幅、章节边界（**只管骨架，不管论证**） | 规划 |
| **M5** | [论证设计](modules/m5-argument.md) | 论证主线、跨章节呼应、拒绝模式、反驳预判（**血肉**） | 方法论 |
| **M6** | [写作辅助](modules/m6-writing.md) | 按 M5 论证骨架展开正文；relate-work 优先 + `[NEEDS-EVIDENCE]` 标记 | 撰写 |
| **M7** | [投稿前总检](modules/m7-final-check.md) | A 内容红队（回扫 M3/M5）+ B 格式合规 + C rebuttal 撰写 | 修改 |
| **M8** | [同行评审仿真](modules/m8-peer-review.md) | 多视角审稿模拟（领域/方法/专家/跨领域/DA）+ 编辑决策 + 修改路线图 | 评审 |
| **M9** | [合规与伦理检查](modules/m9-compliance-check.md) | PRISMA-trAIce 17 项 + RAISE 五维度 + AI 披露 + 最终门控 | 合规 / 投稿 |

> **v0.6 变更说明**（2026-05-06）：新增**三段式文献工作流**（广搜 → 筛选 → 收集）。`multi_source_search.py` 输出补充 `pdf_url`/`pdf_status`/`s2_paper_id`/`openalex_id` 四个字段（S2 fields 加 `openAccessPdf`，OpenAlex 走 `best_oa_location`，arXiv 走直链）。新增 `script/paper/manifest.py`（add / download / scan / render / prune / list 六个子命令）维护 `relate-work/manifest.jsonl` 作为 single source of truth；新增 `script/paper/collect_papers.sh` 三步合一封装。开放获取论文 PDF 自动下载到 `relate-work/pdf/<bibkey>.pdf`，闭源走 `missing.md` 引导用户手动补全。manifest 字段约定见 [`docs/MANIFEST_SCHEMA.md`](docs/MANIFEST_SCHEMA.md)。
>
> **v0.5 变更说明**（2026-05-05）：新增 `paper_search.sh --mode multi`，整合 arXiv + Semantic Scholar + OpenAlex 三源并发检索 + BM25 重排（蒸馏自 papercircle-main 项目，~400 行 Python）。原 standard/bulk/crossref/verify 四模式保持不变。新增依赖：`rank-bm25` + `arxiv` + `requests`（见 `requirements.txt`，仅 multi 模式需要）。仅在 arxiv 命中、未被 S2/OpenAlex 交叉验证的预印本，`arxiv_status` 标为 `unknown`（而非 caution），因 arXiv API 不返回 `citationCount`。各源官方文档与限流参考见 [`config/README.md`](config/README.md) "外部 API 参考与限流" 表。

## 使用方式

### 方式一：流程式（推荐新手）
按顺序调用模块（M0 横切，任何阶段都能查状态）：
```
idea → M1 → M2 → M3 → M4 → M5 → M6 → M7 → M8 → M9 → 投稿
              ↑
          M0 项目仪表盘（横切）
```

### 方式二：按需调用（推荐老手）
根据当前卡点选择模块：
- "我的选题可行吗？" → [M1](modules/m1-topic.md)
- "不知道当前进度卡在哪儿" → [M0](modules/m0-dashboard.md)
- "文献怎么组织、引用怎么管" → [M2](modules/m2-literature.md)
- "实验设计有缺陷" → [M3](modules/m3-experiment.md)
- "不知道怎么组织论文骨架" → [M4](modules/m4-structure.md)
- "论证不充分 / 审稿人会怎么挑" → [M5](modules/m5-argument.md)
- "下笔难、找不到论据" → [M6](modules/m6-writing.md)
- "投稿前最后总检 / 写 rebuttal" → [M7](modules/m7-final-check.md)
- "模拟审稿人怎么看我的论文" → [M8](modules/m8-peer-review.md)
- "AI 使用披露 / 伦理合规检查" → [M9](modules/m9-compliance-check.md)

### 方式三：全自动（终极目标）
```
输入：idea + 数据
↓
M1–M7 自动串联（M0 持续监控状态）
↓
输出：可投稿论文
```

## 快速参考

### 项目命名规范
```
姓名_标题_类型0x_年月

例：Y.Nie_EM-SDPD_final_2409
    Z.Wang_DRL-AF_paper02_2407
```

### 写作顺序建议
1. **先写**：Method, Experiments（最容易）
2. **后写**：Introduction, Abstract（需要全文视角）
3. **穿插**：Related Work, Results, Discussion

### 投稿前检查清单
- [ ] **初始化**：`.env` 已配置、`config/api.json` 已确认、`verify_config.sh` 通过
- [ ] **Git**：所有模块产物已 commit，工作区干净，PR 已合并
- [ ] **反幻觉**：`verify_citations.sh` 报告 0 条 Tier 0 幻觉
- [ ] M0：仪表盘的 pending 列表为空
- [ ] M1：选题经过数据驱动诊断（relate-work/ 已沉淀候选）
- [ ] M2：文献分类完成、bib 规范、Tier 0 引用验证通过
- [ ] M3：实验充分完整（数据/对比/消融/显著性）
- [ ] M4：章节骨架清晰、篇幅符合期刊
- [ ] M5：论证主线完整、DA pass 通过（score >= 4）
- [ ] M6：所有 [MATERIAL GAP] 和 [NEEDS-EVIDENCE] 已回填
- [ ] M7：内容红队 + 格式合规 双双通过
- [ ] M8：同行评审仿真通过、修改路线图已完成
- [ ] M9：PRISMA-trAIce + RAISE 合规、AI 披露声明已添加

## 详细规范

### 学术写作规范
参见 [ACADEMIC-WRITING-GUIDE.md](reference/writing/ACADEMIC-WRITING-GUIDE.md)

### 论文写作指南
参见 [PAPER-WRITING-GUIDE.md](reference/writing/PAPER-WRITING-GUIDE.md)

## 理论基础

本 Skill 的设计参考了以下研究：

### Relic 条件论文
> Liu, C. (2026). The Relic Condition: When Published Scholarship Becomes Material for Its Own Replacement. arXiv:2604.16116.

**核心思想**：
- 八层提取法：从已发表论文中提取稳定的推理架构
- 九模块技能架构：将提取的推理系统组织为可部署的技能约束
- 高可蒸馏性：学术写作本身具有结构化和可提取的特征

**对本 Skill 的启发**：
- 论文写作流程可以模块化、系统化
- 每个模块对应特定的写作任务和检查点
- 通过结构化约束提升写作质量和效率

## 目标愿景

> **最终目标：研究者只需提供 idea，论文全流程自动化完成。**

当前版本已实现：
- ✅ M0-M9 十模块写作支持系统
- ✅ 每个模块的详细指南和 Prompt 模板
- ✅ 基于学术规范的质量检查清单
- ✅ 多视角同行评审仿真（M8）
- ✅ PRISMA-trAIce + RAISE 合规检查（M9）
- ✅ 47 个参考资料（reference/ 下按主题分 writing/research/review/compliance）
- ✅ 15 个结构化输出模板（templates/）
- ✅ 可执行脚本（搜索、引用验证、证据查找）

后续规划：
- 🔄 模块间自动化串联 (Material Passport)
- 📋 跨模型交叉验证集成
- 🚀 一键生成可投稿论文

---

*Skill 版本: 0.6*
*最后更新: 2026-05-06*
*基于 Relic 论文八层提取法 + academic-research-skills prompt 资产整合*
*v0.6 新增：三段式文献工作流（广搜→筛选→收集）+ `manifest.py` 自动 OA PDF 下载 + relate-work 文献清单维护*
*v0.5 新增：多源检索 + BM25 重排（`paper_search.sh --mode multi`，蒸馏自 papercircle-main）*
*v0.4 新增：初始化检查 / Git 强制版本控制 / 反幻觉三层验证*
