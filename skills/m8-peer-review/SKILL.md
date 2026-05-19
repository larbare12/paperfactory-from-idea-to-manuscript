---
name: m8-peer-review
description: |
  M8 同行评审仿真——投稿前从 5 个视角(领域分析师 / 方法论审稿人 /
  领域专家 / 跨领域审稿人 / 魔鬼代言人)模拟完整审稿,生成审稿报告 +
  编辑决策(Accept/Minor/Major/Reject)+ 修改路线图 + rebuttal 模板。
  与 M7 是**补充关系不是替代**——M7 逐条 item-level,M8 综合 paper-level。
  任何"投稿前最终自我审查""模拟不同视角审稿意见""为实际修改准备路线图"
  场景调用本 skill。
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

# M8 同行评审仿真

> **流程位置**:M7 总检(段 A 内容红队)→ **[M8 同行评审(本模块)]** → M9 合规检查 → 投稿
>
> M7 的红队检查是逐条的、清单式的。M8 在此基础上做**整体评审**——模拟真实审稿人的完整审稿流程。
>
> **注意**:本模块不是 M7 的替代,而是其**补充**。M7 检查具体问题(格式、by-item rebuttal),M8 做综合性评审。

---

## 工具依赖

| 工作 | 走哪 |
|---|---|
| 反向检索质疑性文献(DA 审稿人用) | [`citation-search/scripts/paper_search.sh --mode multi`](../citation-search/scripts/paper_search.sh) |
| Venue 评级(可信度对照) | [`citation-search/scripts/venue_lookup.sh`](../citation-search/scripts/venue_lookup.sh) |

## 核心理念

学术论文的同行评审需要从多个角度审视:
- **领域分析师**:检查论文在领域中的定位和贡献
- **方法论审稿人**:深入检查方法的正确性和可复现性
- **领域专家审稿人**:从专业角度评估论文的深度和准确性
- **跨领域审稿人**:评估论文的清晰度和可理解性
- **魔鬼代言人**:主动寻找论证中的漏洞

## 输入

- 终稿 PDF/源文件(来自 M6)
- M5 论证审计记录(来自 passport `argument_audit[]`)
- M3 实验记录
- 目标期刊/会议的审稿 criteria

## 输出

- 多视角审稿报告(5 份)
- 编辑决策建议(Accept / Minor / Major / Reject)
- 修改路线图(按优先级排序的修改项)
- 修改回复草稿模板

## 使用场景

1. 投稿前最终自我审查
2. 准备应对审稿人可能的质疑
3. 模拟不同视角的审稿意见
4. 为实际修改准备路线图

---

## 评审模式

### Mode 1:完整评审(推荐投稿前使用)
5 个视角的审稿人 + 编辑综合决策 + 修改路线图。

### Mode 2:快速评审(15 分钟)
仅编辑视角的快速评估,适合初筛。

### Mode 3:方法论聚焦
深入审查方法部分的可复现性和正确性。

### Mode 4:引导式评审
逐议题 Socratic 对话式评审,适合与导师讨论。

---

## 评审代理角色

### Agent 1:领域分析师 (Field Analyst)

**职责**:评估论文在领域中的定位
- 该领域的核心问题是什么?
- 论文是否正确定位了相关工作?
- 贡献是否具有领域意义?
- 与最相似的 3 篇工作(M1 Layer 6)的差异是否充分论证?

**产出**:领域定位评估报告

### Agent 2:方法论审稿人 (Methodology Reviewer)

**职责**:深入审查方法部分
- 问题定义是否清晰?
- 方法描述是否可复现?
- 数学推导是否正确?
- 实验设计是否合理?
- 结论是否有实验支撑?
- **统计学报告审查**:参照 [`reference/research/statistical_reporting_standards.md`](../../reference/research/statistical_reporting_standards.md) 执行 8 维度评分(描述性统计/效应量/置信区间/统计效力/缺失数据处理/假设检验/方法选择/报告完整性),按 7 步审计序列检查,识别 p-hacking / HARKing / 选择性报告等红旗信号。

**产出**:方法论严谨性评估报告

### Agent 3:领域专家审稿人 (Domain Reviewer)

**职责**:从领域专家角度评估
- 方法是否解决了领域真实痛点?
- 实验结果是否可信?
- 与 SOTA 的对比是否公平?
- 论证是否有领域特定的逻辑漏洞?

**产出**:领域专家审稿意见

### Agent 4:跨领域审稿人 (Perspective Reviewer)

**职责**:评估跨领域贡献和可理解性
- 非本领域读者能否理解核心思想?
- 写作是否清晰?
- 图表是否自解释?
- 是否过多使用领域黑话?

**产出**:可读性和跨领域贡献评估

### Agent 5:魔鬼代言人审稿人 (Devil's Advocate Reviewer)

**职责**:主动寻找论证漏洞
- 核心 claim 的最强反驳是什么?
- 实验是否有未考虑的替代解释?
- 哪些结论需要软化?
- 是否存在未被 M5 DA pass 覆盖的盲点?

**产出**:攻击性审稿意见 + rebuttal 预判

---

## 评审流程

### Step 1:准备(读 M7 输出)

读 M5 的 `argument_audit[]` 和 M7 段 A 的红队结果,了解已知问题和已 preempt 的反驳。

### Step 2:并行评审

5 个 Agent 并行生成审稿报告(在 LLM 上下文中模拟,实际是同一个 AI 切换 5 个 persona)。**每个 reviewer agent 评分时必须参照两份文件**——[`reference/review/review_criteria_framework.md`](../../reference/review/review_criteria_framework.md) 定义评什么(7 个通用维度 + 5 种论文类型的专属 criteria 集、权重分配、aggregation 规则),[`reference/review/quality_rubrics.md`](../../reference/review/quality_rubrics.md) 定义怎么评(7 维度 × 0-100 分的 behavioral indicators、校准锚点、aggregation 公式)。两份互补,缺一不可。

### Step 3:编辑综合决策

综合 5 份报告,**参照** [`reference/review/editorial_decision_standards.md`](../../reference/review/editorial_decision_standards.md) 的决策矩阵将 reviewer 评分映射为 Accept / Minor / Major / Reject——考虑 reviewer 间一致性、confidence calibration、revision round 政策,以及 desk reject 条件。生成:
- 总体评估
- 编辑决策(Accept / Minor Revision / Major Revision / Reject)
- 决策理由
- 关键修改项(优先级排序)

### Step 4:修改路线图

按优先级罗列修改项,标注:
- 致命项(blockers,必须修改)
- 重要项(major,强烈建议修改)
- 建议项(minor,可选修改)
- 回流模块(M3 / M4 / M5 / M6)

### Step 5:修改回复草稿

为每个修改项预写回复模板(实际投稿时填写具体修改位置和内容)。

---

## 审稿标准(ICLR/NeurIPS 风格)

| 维度 | 评分 (1-10) | 权重 |
|---|---|---|
| 新颖性 (Novelty) | /10 | 25% |
| 正确性 (Correctness) | /10 | 25% |
| 完整性 (Completeness) | /10 | 20% |
| 清晰度 (Clarity) | /10 | 15% |
| 相关性 (Relevance) | /10 | 15% |

**编辑决策映射**:
- 总分 ≥ 8.0 且无致命项 → Accept
- 总分 6.0–7.9 → Minor Revision
- 总分 4.0–5.9 → Major Revision
- 总分 < 4.0 或有致命未解决项 → Reject

---

## 示例 Prompt

```
请对我的论文进行投稿前同行评审仿真:

论文文件:[路径]
目标期刊/会议:[填入]
M5 论证审计:[指向 passport argument_audit]
M3 实验记录:[路径]

输出:
1. [Mode: full] 5 视角审稿报告
2. 编辑决策建议 + 理由
3. 修改路线图(按优先级排序)
4. 修改回复草稿模板
```

---

## 与 M7 / M9 的边界

| 模块 | 职责 | 粒度 |
|---|---|---|
| M7 段 A | 逐条红队检查 | item-level |
| M8(本模块) | 综合评审 | paper-level |
| M7 段 B | 格式合规 | format-level |
| M9 | 合规伦理 | compliance-level |

---

## 相关跨域 reference

- [`reference/review/review_criteria_framework.md`](../../reference/review/review_criteria_framework.md)
- [`reference/review/review_quality_thinking.md`](../../reference/review/review_quality_thinking.md)
- [`reference/review/editorial_decision_standards.md`](../../reference/review/editorial_decision_standards.md)
- [`reference/review/quality_rubrics.md`](../../reference/review/quality_rubrics.md)
- [`reference/review/top_journals_by_field.md`](../../reference/review/top_journals_by_field.md)
- 模板:[`templates/peer_review_report_template.md`](../../templates/peer_review_report_template.md) / [`templates/editorial_decision_template.md`](../../templates/editorial_decision_template.md) / [`templates/revision_response_template.md`](../../templates/revision_response_template.md)

## Passport I/O

- **Reads**: `argument_audit[]`(M5 DA records,已知 weaknesses)、`outline`(verify paper matches planned structure)、`bibliography[]`(reviewer 视角的引用完整性交叉检查)、`corpus[]`(fact-check reviewer claims 的证据文件)、`material_gaps[]`(若未解决,reviewer 会标 blocker)
- **Writes**: `current_stage` → `m8`、`corpus[]`(5 份审稿报告 + 编辑决策 + 修改路线图的新路径)、`argument_audit[]`(DA reviewer 可能发现 M5 未覆盖的新攻击向量)
- **Stage transition**: advances passport to `current_stage = m8`(peer review simulation 完成;修改路线图 ready)
