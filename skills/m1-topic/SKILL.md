---
name: m1-topic
description: |
  M1 选题诊断——数据驱动的研究 idea 可行性 / 创新性 / 领域契合度评估。
  必须先通过 citation-search 的"广搜→筛选→收集"三段式拉一批论文作为
  诊断基线,再用 Layer 0-8 八层提取法做主观判断。M1 出口处 manifest.jsonl
  应已沉淀 N 篇 pending/downloaded 候选,直接交给 M2。任何"我有个 idea
  值不值得做""多个选题方向筛优先级""导师让评估可行性"场景调用本 skill。
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

# M1 选题诊断

> **流程位置**:**[M1 选题诊断(本模块)]** → M2 文献 → M3 实验 → M4 结构 → M5 论证 → M6 写作 → M7 总检
> M0 项目仪表盘是横切的常驻模块,任何阶段都可以调。

---

## 工具依赖(必读)

本 skill 不实现文献检索 —— Layer 0(文献基线建立)整段委托给 [`citation-search`](../citation-search/SKILL.md):

| 工作 | 走哪 |
|---|---|
| 广搜建基线 | `citation-search/scripts/paper_search.sh --mode multi` |
| 筛选 + 入 manifest | `citation-search/scripts/collect_papers.sh` |
| Venue 分布分析(Layer 5) | `citation-search/scripts/venue_lookup.sh` + [`venue-quality-protocol`](../citation-search/reference/venue-quality-protocol.md) |
| 三段式工作流 | [`literature-research-protocol`](../citation-search/reference/literature-research-protocol.md) |

**铁律**:M1 出口处 `manifest.jsonl` 应**已有内容**——纯主观诊断不算 M1 完成,Layer 0 是硬前置。

---

## 功能

评估研究 idea 的可行性、创新性、与领域契合度。**数据驱动**:诊断必须建立在实际文献证据之上,不是凭印象。

## 输入

- 研究 idea(一句话描述)
- 初步文献(可选,3-5 篇关键文献)
- 目标期刊/会议(可选)
- 领域背景(可选)

## 输出

- 可行性评估(高/中/低)+ 理由
- 创新点提炼(3-5 个 bullets)
- 与领域热点契合度分析
- 潜在风险点识别
- 建议调整方向
- 下一步行动建议
- **`relate-work/manifest.jsonl` 沉淀的候选论文池**(供 M2 直接消费)

## 使用场景

1. 有初步想法,不确定是否值得深入
2. 多个选题方向,需要筛选优先级
3. 导师要求评估选题可行性
4. 投稿前最后检查选题定位

---

## 诊断流程(八层提取法)

### Layer 0:文献基线建立(硬前置)

在做任何主观判断之前,**先**通过 citation-search 拉一批与 idea 相关的论文作为诊断基线:

```bash
# 推荐:三源并发 + BM25 重排
bash "${CLAUDE_PLUGIN_ROOT}/skills/citation-search/scripts/paper_search.sh" \
     "<idea 关键词组合>" \
     --mode multi --year "2020-" --limit 30 \
     > relate-work/search-<idea-slug>-$(date +%Y%m%d).jsonl

# 备选:S2 单源大批量(>100 条候选池)
# --mode bulk --year "2020-" --limit 200
```

S2 触发 429 时 multi 模式自动 fallback(arXiv + OpenAlex 仍能返回)。bulk 模式 429 时切换到 `--mode crossref`。

**v0.6 强制 Stage 2/3**:Layer 0 完成后立即筛选 + 收集:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/citation-search/scripts/collect_papers.sh" \
     --search relate-work/search-<idea-slug>-$(date +%Y%m%d).jsonl \
     --bibkeys <筛选过的 bibkey 列表,逗号分隔>
```

闭源拿不到 PDF 的论文写入 `relate-work/missing.md` 等用户人工补全。详见 [`literature-research-protocol`](../citation-search/reference/literature-research-protocol.md)。

Layer 0 落盘后这批论文成为:
- M1 Layer 3 / 5 / 6 的**证据来源**
- M2 文献分类、M5 论证设计、M6 写作的**本地检索池**

### Layer 1:Idea 捕获

提取用户输入的核心研究问题。

### Layer 2:问题类型识别

判断是:新问题 / 新方法 / 新应用 / 理论拓展 / 实证补充。

### Layer 3:创新性评估(用 Layer 0 的搜索结果背书)

基于 `relate-work/search-*.jsonl` 回答:
- 与已发表工作的差异化程度——有几篇高度近似?分别差在哪个维度?
- 理论贡献潜力——已有方法是否已经覆盖你的核心机制?
- 实践价值——同方向论文的引用量趋势(涨/平/跌)说明热度走势

### Layer 4:可行性检查

- 数据/资源可获取性(看相关论文用的数据集是否公开)
- 技术难度(看 SOTA 方法的复杂度与本组能力差距)
- 时间成本

### Layer 5:领域契合度(用 Layer 0 的 venue 分布背书)

```bash
# 查 Layer 0 中高频出现的 venue 的 CCF/IF
bash "${CLAUDE_PLUGIN_ROOT}/skills/citation-search/scripts/venue_lookup.sh" "<venue 名>"
```

- 这些 venue 是否覆盖你的目标投稿目的地
- 当前领域热点关键词出现频次
- **筛选时直接应用** [`venue-quality-protocol`](../citation-search/reference/venue-quality-protocol.md) 的三把尺,把 NBER WP / arXiv-only / 水会标出来

### Layer 6:风险识别(用 Layer 0 找竞争工作)

- 潜在技术障碍
- 竞争工作风险——明确指出 `relate-work/` 中**最相似的 3 篇**论文,标注 idea 与它们的差异
- 伦理/法律问题

### Layer 7:综合评估

生成可行性评级 + 优先级建议。

### Layer 8:行动建议

输出具体下一步行动清单,并明确告知用户:
- `relate-work/` 中已沉淀了哪些论文,将作为 M2 / M5 / M6 的本地检索池
- 是否需要补充某类文献(基础 / 方法 / 对比 / 相关)→ 直接进入 M2

---

## 诊断标准

### 可行性评级

- **高**:资源充足、技术成熟、6 个月内可完成
- **中**:需要一定探索、可能遇到技术障碍、6-12 个月
- **低**:资源难以获取、技术挑战大、时间成本过高

### 创新性评级

- **高**:开辟新方向、解决长期难题、理论突破
- **中**:显著改进现有方法、新应用场景、较重要实证
- **低**:增量改进、已有类似工作、应用价值有限

---

## 示例 Prompt

```
请帮我诊断以下研究选题:

研究 idea:[填入]
目标期刊/会议:[填入]
相关文献:[填入]

按以下结构输出诊断报告:
1. 可行性评估(高/中/低)
2. 核心创新点(3-5 个)
3. 与领域契合度分析
4. 潜在风险点
5. 建议调整方向
6. 下一步行动建议
```

---

## 相关跨域 reference

- [`reference/writing/PAPER-WRITING-GUIDE.md`](../../reference/writing/PAPER-WRITING-GUIDE.md) 第 7.1 节(大纲生成 Prompt)
- [`reference/research/socratic_questioning_framework.md`](../../reference/research/socratic_questioning_framework.md) — idea 澄清与收敛
- [`reference/research/interdisciplinary_bridges.md`](../../reference/research/interdisciplinary_bridges.md) — 交叉领域创新性评估
- [`reference/compliance/ethics_checklist.md`](../../reference/compliance/ethics_checklist.md) — 早期伦理风险筛查
- [`reference/review/top_journals_by_field.md`](../../reference/review/top_journals_by_field.md) — 投稿目标选择
- [`reference/research/source_quality_hierarchy.md`](../../reference/research/source_quality_hierarchy.md) — 文献质量评估

## Passport I/O

- **Reads**: `research_question`(要诊断的 idea)、`corpus[]`(已有证据文件,若存在)
- **Writes**: `research_question`(诊断后精炼并 scope)、`methodology.description`、`methodology.data_source`、`current_stage` → `m1`、`corpus[]`(新增 search 结果路径)
- **Stage transition**: advances passport to `current_stage = m1`(pipeline 入口点,从 idea 引导到 diagnosed research question)
