<div align="center">

# paperfactory: from idea to manuscript

<sub><b>全自动论文生产线 —— Claude Code Plugin</b></sub>

<p>
  <img alt="Claude Code Plugin" src="https://img.shields.io/badge/Claude%20Code-Plugin-7C3AED?style=flat-square">
  <img alt="Skills" src="https://img.shields.io/badge/skills-10-2563EB?style=flat-square">
  <img alt="Hooks" src="https://img.shields.io/badge/hooks-4-059669?style=flat-square">
  <img alt="Status" src="https://img.shields.io/badge/status-active-22C55E?style=flat-square">
</p>

M0 仪表盘 · M1–M9 九阶段模块 · citation-search 独立子 skill<br>
覆盖选题诊断 · 文献管理(<b>Tier 0 反幻觉 + venue quality</b>) · 实验设计<br>
结构规划 · 论证设计 · 写作辅助 · 投稿前总检 · 同行评审仿真 · 合规检查

<sub>
  <a href="#快速开始">快速开始</a> ·
  <a href="#架构">架构</a> ·
  <a href="#核心特性">核心特性</a> ·
  <a href="MIGRATION.md">从 v1 升级</a> ·
  <a href="index.html">网页版文档</a>
</sub>

</div>

---

## 初衷

天下研究生，苦小论文久矣。paperfactory 想做一件事——**把从 idea 到 manuscript 的整条生产线自动化**。你负责想 idea，剩下的交给流水线。

---

## 快速开始

### 1. 安装

把整个 plugin 目录放到 Claude Code 的 plugin 路径(参见 Claude Code 文档),或在本目录直接启动 Claude Code session。

### 2. 在你的论文项目里跑

```bash
cd /path/to/your-paper-project
claude  # 启动 session
```

第一次进入项目时,执行:

```
/paperfactory:init
```

会自动:

1. 检查 git 仓库 + 工作区
2. 检查 S2 API key 凭据(`.env`)
3. 初始化 `relate-work/` + `manifest.jsonl`
4. 启用 hooks(SessionStart / PreToolUse / PostToolUse / Stop)
5. 跑 M0 仪表盘首次扫描
6. 给出下一步建议

### 3. 按 M0–M9 工作流推进

<table>
  <thead>
    <tr>
      <th align="left">阶段</th>
      <th align="left">命令</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>想找文献 / 验证引用 / 查 venue 质量</td><td><code>@citation-search</code></td></tr>
    <tr><td>评估 idea 可行性</td><td><code>@m1-topic</code></td></tr>
    <tr><td>文献综述 / bib 整理</td><td><code>@m2-literature</code></td></tr>
    <tr><td>实验设计</td><td><code>@m3-experiment</code></td></tr>
    <tr><td>IMRAD 大纲</td><td><code>@m4-structure</code></td></tr>
    <tr><td>论证骨架 / DA 红队</td><td><code>@m5-argument</code></td></tr>
    <tr><td>写正文 / 段落润色</td><td><code>@m6-writing</code></td></tr>
    <tr><td>投稿前总检</td><td><code>@m7-final-check</code></td></tr>
    <tr><td>同行评审仿真</td><td><code>@m8-peer-review</code></td></tr>
    <tr><td>合规 + AI 披露</td><td><code>@m9-compliance-check</code></td></tr>
    <tr><td>看项目状态</td><td><code>@m0-dashboard</code></td></tr>
  </tbody>
</table>

---

## 架构

<details>
<summary><b>点开查看完整目录树</b></summary>

```
.claude-plugin/
└── plugin.json              # plugin manifest

skills/
├── citation-search/         # 独立检索/验证基座(横切被其他 9 个 skill 调用)
│   ├── SKILL.md
│   ├── scripts/             # paper_search.sh, verify_citations.sh, venue_lookup.sh, ...
│   ├── config/api.json      # S2/CrossRef 端点
│   ├── data/                # CCF + JCR IF sqlite
│   └── reference/           # 协议:literature-research / anti-hallucination / venue-quality / manifest-schema
├── m0-dashboard/            # 项目仪表盘(横切常驻)
├── m1-topic/                # 选题诊断
├── m2-literature/           # 文献管理
├── m3-experiment/           # 实验设计
├── m4-structure/            # 结构规划
├── m5-argument/             # 论证设计 + DA 协议
├── m6-writing/              # 写作辅助 + Anti-Leakage
├── m7-final-check/          # 投稿前总检
├── m8-peer-review/          # 同行评审仿真
└── m9-compliance-check/     # 合规与伦理检查

commands/
└── init.md                  # /paperfactory:init

hooks/
├── hooks.json               # plugin-enforced hooks 声明
├── session-start.sh         # 进 paper 项目自动跑 verify_config + M0 mini
├── pre-draft-write.sh       # 写 draft/ 前提示 commit checkpoint
├── post-draft-write.sh      # 新引用未跑 Tier 0 → 提醒
└── stop-scan-gaps.sh        # [NEEDS-EVIDENCE] 数变化 → 提醒

reference/                   # 跨 skill 共享的非检索类知识库
├── writing/                 # 15 文件,写作风格 / 语言 / 格式
├── research/                # 12 文件,研究方法论 / 实验设计
├── review/                  # 9 文件,同行评审 / 质量评估
└── compliance/              # 11 文件,PRISMA-trAIce / RAISE / AI 披露

templates/                   # 15 个输出模板(IMRAD / poster / review report 等)

docs/
├── README_CN.md             # 中文文档(本文件)
├── index.html               # GitHub Pages 网页版文档
└── MIGRATION.md             # 从 paper.skill v1 升级指南
```

</details>

---

## 核心特性

### 反幻觉硬约束

- **Tier 0 校验**:DOI 反查 + Levenshtein ≥ 0.70,识别 5 类幻觉(TF / PAC / IH / PH / SH)
- **三层验证**:Layer 1 来源 → Layer 2 引用 → Layer 3 内容一致性
- **红线清单**:模型记忆 cite 2024+ 论文 / preprint 当期刊 / 跳过 verify_citations.sh —— 任一触发立即 STOP
- **abstract-only cite 反模式**:严禁基于 abstract 做 paraphrase,必须读全文

详见 [`skills/citation-search/reference/anti-hallucination-protocol.md`](../skills/citation-search/reference/anti-hallucination-protocol.md)。

### Venue Quality 二道筛

反幻觉只保证文献**真实**,不保证够**顶**。M2 筛选阶段强制跑 `venue_lookup.sh`:

- 预印本(NBER WP / arXiv / SSRN)不能当方法论 baseline
- 顶刊白名单 + CCF + JCR IF 自动判级
- 真实事故复盘:2026-05-08 NBER WP w29166 当 baseline → 推倒重写一个 layer

详见 [`skills/citation-search/reference/venue-quality-protocol.md`](../skills/citation-search/reference/venue-quality-protocol.md)。

### 三段式文献工作流

广搜(`--mode multi`)→ 筛选(Stage 2)→ 收集(`collect_papers.sh` 自动入 manifest + OA PDF 下载)→ 用户补全闭源 → prune 找不到的。

详见 [`skills/citation-search/reference/literature-research-protocol.md`](../skills/citation-search/reference/literature-research-protocol.md)。

### Anti-Leakage Protocol(M6 写作铁律)

严禁用 parametric memory 填事实空白。所有数据点/引用/统计数字必须有 `relate-work/` 本地证据或 `find_evidence.sh` 实时检索结果。缺证据点必须插 `[MATERIAL GAP: ...]`,`check_material_gaps.sh` 拒绝输出含 GAP 的 final draft。

### Devil's Advocate Pass(M5 autonomous 强制)

反 cascade concession:对每个 core claim(3-7 个)执行 Attack/Rebuttal/Concession 三轮,rebuttal score < 4 触发 soften/drop。

---

## 凭据要求

```bash
# 在你的论文项目根创建 .env
cp ${CLAUDE_PLUGIN_ROOT}/.env.example .env

# 在 https://www.semanticscholar.org/product/api 申请 S2 API key
# 填入 .env:
S2_API_KEY=Bearer xxxxx

# multi mode 额外需 Python:
pip install -r ${CLAUDE_PLUGIN_ROOT}/requirements.txt
```

`/paperfactory:init` 会自动跑 `verify_config.sh` 检查。

---

## 升级指南

如果你之前在用 paper.skill v1(单 skill 形式),见 [`docs/MIGRATION.md`](MIGRATION.md)。

---

## 致谢

<table>
  <tr>
    <td valign="top" width="50%">
      <h4>citation-assistant</h4>
      <p><b>联网文献检索、期刊质量评估、BibTeX 生成</b>能力的种子来自
        <a href="https://github.com/ZhangNy301/citation-assistant">citation-assistant</a>。</p>
      <p><code>skills/citation-search/scripts/</code> 下的 <code>paper_search.sh</code> /
        <code>venue_lookup.sh</code> / <code>author_info.sh</code> / <code>doi2bibtex.sh</code>
        以及 CCF 与影响因子数据库均基于该项目改造。</p>
    </td>
    <td valign="top" width="50%">
      <h4>academic-research-skills (ARS)</h4>
      <p><b>M8/M9 模块设计、<code>reference/</code> 与 <code>templates/</code> 下 62 个参考文件和模板</b>
        来自 academic-research-skills 项目(Cheng-I Wu, CC-BY-NC 4.0)。</p>
      <p>包括 PRISMA-trAIce 协议、RAISE 框架、多视角审稿人模型、APA 7 风格指南、
        逻辑谬误目录、学术写作风格指南等。</p>
    </td>
  </tr>
</table>

### 平台

- [Semantic Scholar](https://www.semanticscholar.org/) — 学术检索 API
- [CrossRef](https://www.crossref.org/) — DOI 元数据与 BibTeX content negotiation
- [OpenAlex](https://openalex.org/) — 开放学术图谱
- [arXiv](https://arxiv.org/) — 预印本仓库
- [impact_factor](https://github.com/suqingdong/impact_factor) — 期刊 IF 数据库

---

<div align="center">
<sub><i>为科研效率而生。</i></sub>
</div>
