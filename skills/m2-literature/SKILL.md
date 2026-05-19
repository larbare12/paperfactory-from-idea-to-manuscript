---
name: m2-literature
description: |
  M2 文献管理(IMRAD 中的 Related Work + References)。消费 M1 沉淀的
  search-*.jsonl,做精读、引用网络分析、bibkey 整理、四类标签(基础/方法/
  baseline/相关)、引用密度审计、BibTeX 格式规范化,产出 manifest.jsonl +
  ref-*.md 笔记卡 + 引用校验报告,供 M3 baseline / M5 论证链 / M6 写作消费。
  任何"扩写 related work""整理 baseline 论文""投稿前 .bib 审计"
  "找方法论文""引用密度排查"场景调用本 skill。
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

# M2 文献管理

> M1 已用 `paper_search.sh --mode multi/bulk` 把候选论文落到 `relate-work/`。
> M2 在此基础上精读、分类、整 bib key、跑校验,把"一坨候选"变成 M3/M5/M6 可直接消费的结构化资源。

---

## 工具依赖(必读)

本 skill **不实现**检索/验证/venue 评估 —— 一律委托给
[`citation-search`](../citation-search/SKILL.md):

| 工作 | 走哪 |
|---|---|
| 三段式工作流(广搜→筛选→收集) | `citation-search/scripts/collect_papers.sh` + [`literature-research-protocol`](../citation-search/reference/literature-research-protocol.md) |
| 引用真实性校验(Tier 0 + 5 类幻觉) | `citation-search/scripts/verify_citations.sh` + [`anti-hallucination-protocol`](../citation-search/reference/anti-hallucination-protocol.md) |
| Venue 质量过滤(预印本 vs 顶刊) | `citation-search/scripts/venue_lookup.sh` + [`venue-quality-protocol`](../citation-search/reference/venue-quality-protocol.md) |
| DOI → BibTeX | `citation-search/scripts/doi2bibtex.sh` |
| 作者 H-index | `citation-search/scripts/author_info.sh` |
| Manifest 维护 | `citation-search/scripts/manifest.py` + [`manifest-schema`](../citation-search/reference/manifest-schema.md) |

**铁律**:M2 阶段任何 `\cite{...}` 入 .bib **必须** 经过 citation-search 的 verify mode。绝不允许 M2 末尾留下未校验的引用进 M3。

---

## 流程位置

```
M1 选题诊断 → [M2 文献管理] → M3 实验设计 → M4 结构 → M5 论证 → M6 写作 → M7 总检
```

## 输入

- M1 沉淀的 `relate-work/search-*.jsonl`(必须)
- 目标期刊/会议的引用格式要求(IEEE / ACM / APA / GB-T 7714 等)
- 领域关键词与方法论 baseline 候选(从 M1 idea 验证带过来)

## 输出

| 产物 | 路径 | 用途 |
|---|---|---|
| Manifest 主表 | `relate-work/manifest.jsonl` | M3/M5/M6 共享的 SoT |
| 精读笔记卡 | `relate-work/ref-<bibkey>.md` | Layer 3 内容一致性的人工备注层 |
| Manifest 可读渲染 | `relate-work/manifest.md` + `missing.md` | 给用户看的总览 + 待补清单 |
| 引用校验报告 | `relate-work/citation_verification_report_<date>.md` | M3 前 + 进 M7 前的 gate |
| BibTeX 主文件 | `relate-work/references.bib` | M6 写作时直接 `\bibliography{...}` |

---

## 工作流

### Step 1:确认 M1 已完成三段式工作流

进入 M2 时 `manifest.jsonl` 应该已经有 N 条 `pending` / `downloaded` 条目。如果是空的,**回 M1 跑一轮 `collect_papers.sh`**,不要在 M2 里自己广搜——M1 是检索的入口,M2 的入口是 manifest。

```bash
# 看看 manifest 状态分布
jq -r '.status // empty' relate-work/manifest.jsonl | sort | uniq -c
```

预期看到 `pending` / `downloaded` / `user-supplied` / `missing` 几种状态混合。若全是 `pending` → 跑 `manifest.py download`(在 citation-search/scripts/)。

### Step 2:精读 + 四类标签

对 status ∈ {downloaded, user-supplied} 的论文逐篇精读(method / experiments / results 章节),按下面四类标记 `manifest.jsonl` 的 `tags` 字段:

- **`foundational` 基础文献** — 领域开创性工作,引用通常 >1000
- **`method` 方法文献** — 直接相关的方法论文,本文方法的基础或扩展
- **`baseline` 对比文献** — 实验对照组(M3 直接消费)
- **`related` 相关文献** — 边缘相关,一句话提及

**venue gate**:被标 `baseline` 或 `method` 的论文,**必须** 跑 `venue_lookup.sh` 检查;若 venue 是 NBER WP / arXiv / SSRN / preprint,按 [`venue-quality-protocol §硬约束`](../citation-search/reference/venue-quality-protocol.md) 处理 —— 要么找等价已发表替代品,要么仅作 concurrent work 弱引用。

```bash
# 批量标 tags
py -3 "${CLAUDE_PLUGIN_ROOT}/skills/citation-search/scripts/manifest.py" tag \
     --bibkey vaswani-2017-attention --tags foundational,method
```

精读后给每篇关键论文写一张 `relate-work/ref-<bibkey>.md` 笔记卡,内容至少含:核心 claim / 实验设置 / 与本文的关系 / 可复用的图表数据。

**禁止 abstract-only cite**:见 [`anti-hallucination-protocol §abstract-only`](../citation-search/reference/anti-hallucination-protocol.md)。

### Step 3:引用网络分析(可选,综述章节有价值)

利用 `manifest.jsonl` 中的 `s2_paper_id` 字段调 S2 references API 看引用网络,识别核心节点。系统综述类论文还需走 [`reference/research/systematic_review_toolkit.md`](../../reference/research/systematic_review_toolkit.md)(PRISMA + RoB 2 / ROBINS-I + GRADE)。

### Step 4:引用密度检查(给 M6 留 hook)

按章节预期密度:

| 章节 | 期望密度 |
|---|---|
| Introduction | 每段 2-3 个引用 |
| Related Work | 密集,建立领域地图 |
| Method | 关键方法引用,避免过度堆砌 |
| Experiments | baseline 方法必须引用 |
| Discussion | 理论支撑引用 |

避免:连续多段无引用 / 单段 >5 个引用 / 关键 claim 缺引用支撑(M6 时会回查)。

### Step 5:BibTeX 规范化

```bash
# DOI → BibTeX
bash "${CLAUDE_PLUGIN_ROOT}/skills/citation-search/scripts/doi2bibtex.sh" "10.1038/..."

# 引用格式转换(APA/IEEE/ACM/MLA/Chicago/Vancouver/GB-T 7714)
# 走 reference/writing/citation_format_switcher.md
```

格式检查清单:
- [ ] 作者姓名格式统一(全名 vs 缩写,en-dash vs hyphen)
- [ ] 标题大小写符合规范(Title Case vs sentence case)
- [ ] 期刊名斜体(`\emph{...}`)
- [ ] 卷/期/页/年完整
- [ ] DOI(目标期刊要求时)
- [ ] **特别注意**:嵌套 `{...}` 大写保护会触发 verify_citations.sh parser bug(见 anti-hallucination 末节)

### Step 6:缺口识别 → 回 M1 补检索

```bash
py -3 "${CLAUDE_PLUGIN_ROOT}/skills/citation-search/scripts/manifest.py" list \
     --status missing,pending
```

如果发现某类论文(如 baseline 不够、缺综述、缺最近 2 年的)显著不足,**回到 M1 再补一轮 `--mode multi`**,不要在 M2 内重新做检索。

### Step 7:引用真实性校验(强制门控)

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/citation-search/scripts/verify_citations.sh" \
     relate-work/draft.tex --bib relate-work/references.bib
```

报告写入 `relate-work/citation_verification_report_<date>.md`,按 5 类幻觉(TF / PAC / IH / PH / SH)分类输出。

**任何 Tier 0 非 S2_UNAVAILABLE 的失败未消除 → 禁止进入 M3**(M3 baseline 论文若引用幻觉会污染整条论证链)。

### Step 8:生成最终 manifest 渲染

```bash
py -3 "${CLAUDE_PLUGIN_ROOT}/skills/citation-search/scripts/manifest.py" render
```

产出 `manifest.md`(全表)+ `missing.md`(待人工补全清单)给用户审。

---

## 关键文献分类标准(辅助 Step 2)

### 基础文献(`foundational`)
- 领域开创性工作 / 被广泛引用的经典论文 / 理论基础来源
- 通常引用 >1000
- 在 introduction / related work 出现

### 方法文献(`method`)
- 直接相关的方法论文,本文方法的基础或扩展
- 通常引用 100-1000
- 需要详细讨论
- **venue gate**:必须同行评审顶刊(见 venue-quality-protocol §硬约束)

### 对比文献(`baseline`)
- 实验 baseline 直接对标
- 性能相近的竞争方法
- **venue gate**:同上,**特别严格** —— baseline 用错会被审稿人质疑实验设计

### 相关文献(`related`)
- 边缘相关 / 应用场景类似但方法不同
- 一句话提及即可
- 引用次数不限

---

## 引用质量评估(辅助)

### 高质量引用特征
- 直接支撑核心 claim
- 来自顶级期刊/会议(`venue_lookup.sh` 验证)
- 近 5 年工作(经典文献除外)
- 作者亲自精读过(对应 manifest.jsonl `status` ∈ {downloaded, user-supplied} 且有 ref-*.md 笔记)

### 避免的问题
- 过度自引(>20%)
- 引用二手文献(SH 类幻觉源头)
- 引用未阅读文献(abstract-only 反模式)
- 无关引用堆砌

---

## 相关跨域 reference

- [`reference/writing/ACADEMIC-WRITING-GUIDE.md`](../../reference/writing/ACADEMIC-WRITING-GUIDE.md) 第三部分(参考文献格式规范)
- [`reference/writing/PAPER-WRITING-GUIDE.md`](../../reference/writing/PAPER-WRITING-GUIDE.md) 第 5 部分(引用与参考文献)
- [`reference/writing/citation_format_switcher.md`](../../reference/writing/citation_format_switcher.md) — 多格式引文转换
- [`reference/research/source_quality_hierarchy.md`](../../reference/research/source_quality_hierarchy.md) — A-F 证据等级
- [`reference/research/systematic_review_toolkit.md`](../../reference/research/systematic_review_toolkit.md) — PRISMA 2020
- [`reference/review/claim_verification_protocol.md`](../../reference/review/claim_verification_protocol.md) — Claim 交叉验证

---

## Passport I/O

- **Reads**: `research_question`(限定文献 scope)、`corpus[]`(M1 search 结果路径)、`bibliography[]`(增量补全的已有条目)
- **Writes**: `bibliography[]`(verified entries: key/title/authors/year/doi/s2_id/verification_status)、`corpus[]`(新增 ref-*.md 路径)、`material_gaps[]`(未闭合的引用缺口,触发回 M1)、`current_stage` → `m2`
- **Stage transition**:advances passport to `current_stage = m2`
