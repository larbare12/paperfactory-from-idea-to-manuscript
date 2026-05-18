---
name: m6-writing
description: |
  M6 写作辅助——按 M5 论证骨架展开正文,按 M4 章节边界控制内容。
  **IRON RULE: Anti-Leakage Protocol**——严禁用 parametric memory 填事实
  空白,所有数据点/引用/统计数字必须有 relate-work/ 本地证据或
  find_evidence.sh 实时检索结果。缺证据点必须插 [MATERIAL GAP: ...] 标记,
  check_material_gaps.sh 会扫描 final draft。任何"撰写论文段落""语言润色"
  "逻辑连贯性检查""术语一致性"场景调用本 skill。
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

# M6 写作辅助

> **流程位置**:M1 → M2 → M3 → M4 → M5 → **[M6 写作(本模块)]** → M7 总检
> 本模块按 [m5-argument](../m5-argument/SKILL.md) 产出的论证骨架展开正文,依据 [m4-structure](../m4-structure/SKILL.md) 的章节边界控制内容。

---

## IRON RULE: Anti-Leakage Protocol

> **IRON RULE — 不可违反**:写作 agent **严禁**用 parametric memory(模型预训练知识)填充任何事实空白。所有数据点、引用、统计数字、人物言论必须有 `relate-work/` 中的本地证据或 `find_evidence.sh` 实时检索结果作为来源。

### When evidence is missing

遇到任何无法用 `find_evidence.sh` 找到证据的事实点,**必须**在草稿中插入 `[MATERIAL GAP: <一句话描述需要的证据类型>]` 标记。例如:

- `[MATERIAL GAP: 需要 2024 年 LLM hallucination 在医学领域的实证 benchmark]`
- `[MATERIAL GAP: 需要 GPT-4 vs Claude 在数学推理上的最新对比数据]`

### Why this matters in autonomous mode

Copilot 模式下用户每段都看,能当场抓出"AI 编了一个看起来合理的数字"。
Autonomous 模式下用户只看终稿,编造的数字混在真实数字中**几乎不可能被察觉**。
IRON RULE 的存在是为了**让缺证据的地方在终稿里显眼可见**,便于人类编辑回头补或删。

### Enforcement

- 写作过程中:agent 主动打标记,不许"略过"或"用相似数据替代"
- 终稿前:`check_material_gaps.sh` 扫描全文,发现 `[MATERIAL GAP]` 则拒绝输出 final draft
- 解决方式:要么补上证据后删除标记,要么明确接受标记保留作为"待补"

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/citation-search/scripts/check_material_gaps.sh" \
     draft/
```

---

## 工具依赖

| 工作 | 走哪 |
|---|---|
| 本地证据检索(corpus-first) | [`citation-search/scripts/find_evidence.sh`](../citation-search/scripts/find_evidence.sh) |
| 实时引用真实性校验 | [`citation-search/scripts/verify_citations.sh`](../citation-search/scripts/verify_citations.sh)(写完一章即跑) |
| 缺口扫描 | [`citation-search/scripts/check_material_gaps.sh`](../citation-search/scripts/check_material_gaps.sh) |
| 反幻觉协议 | [`citation-search/reference/anti-hallucination-protocol`](../citation-search/reference/anti-hallucination-protocol.md) |

---

## 功能

段落生成、语言润色、逻辑连贯性检查。
**核心约束**:每提出一个 claim,必须先在 `relate-work/` 找到本地证据;找不到才回退到 `find_evidence.sh`(corpus-first / search-fills-gap 流程)。

---

## 🔒 写作前置规则:观点必须有论据

> 这条规则**优先级高于所有润色和结构建议**。先有论据,再有观点。

### 流程

```
要写的 claim
    ↓
Step A. 在 relate-work/ 检索是否已有支撑材料
    ↓
   ├─ 找到 → 直接引用(cite key 取自 ref-*.md 或 manifest.jsonl)
   │
   └─ 没找到 → Step B. 调用 find_evidence.sh
                  ↓
                 ├─ S2 命中 → 写入 relate-work/ + 给出 cite key
                 │
                 └─ S2 也无果 → 标记 [NEEDS-EVIDENCE],继续写作不阻塞,事后回填
```

### 操作清单

```bash
# Step A:本地检索
grep -li "<claim 关键词>" relate-work/*.md relate-work/*.json relate-work/*.jsonl

# Step B:找不到时调 find_evidence
bash "${CLAUDE_PLUGIN_ROOT}/skills/citation-search/scripts/find_evidence.sh" \
     "<完整 claim 一句话>"
# exit 2 = 任何地方都未找到 → 草稿对应句子末尾插入 [NEEDS-EVIDENCE]
```

### 示例

> 草稿原句:
> > Vision Transformer outperforms ResNet-50 on ImageNet by 5%.
>
> 处理:
> 1. `grep -li "vision transformer.*imagenet" relate-work/*` → 命中 `ref-dosovitskiy2021vit.md`
> 2. 替换为:
>    > Vision Transformer outperforms ResNet-50 on ImageNet by 5%~\cite{dosovitskiy2021vit}.
>
> 若 grep 无命中:
> 1. `bash citation-search/scripts/find_evidence.sh "ViT outperforms ResNet-50 on ImageNet"`
> 2. exit 2 → 替换为:
>    > Vision Transformer outperforms ResNet-50 on ImageNet by 5% [NEEDS-EVIDENCE].
> 3. [m0-dashboard](../m0-dashboard/SKILL.md) 会列出所有 `[NEEDS-EVIDENCE]` 等待回填,[m7-final-check](../m7-final-check/SKILL.md) 会拒绝带有未回填标记的稿件进入投稿流程。

### 为什么不直接联网搜?

故意留 `find_evidence.sh` 作为优先入口而非直接 WebSearch,原因:
- 联网搜索结果应先经用户 review 再写入 `relate-work/`,避免引入未审核的引用
- 占位的存在让"哪些 claim 还没有论据"显式可见,而不是被自动填充掩盖
- 实现 corpus-first 流程后,本地缓存命中能省 S2 API 调用

---

## 输入

- 草稿段落
- 目标章节(Introduction / Method / Results 等)
- 写作规范要求
- 目标期刊风格

## 输出

- 语言润色版本
- 逻辑连贯性检查报告
- 术语一致性检查
- 时态和语态建议
- 学术风格改进建议

## 使用场景

1. 初稿撰写
2. 语言润色
3. 逻辑检查
4. 投稿前最终润色

---

## 风格校准(可选但推荐)

如果用户提供了 3 篇以上已发表论文样本,**参照** [`reference/writing/style_calibration_protocol.md`](../../reference/writing/style_calibration_protocol.md) 执行 3 步学习流程——Step 1 从样本中提取 6 维度作者风格特征(句长/段长/词汇偏好/引用整合方式/修饰语风格/语域切换模式)→ Step 2 生成风格 profile → Step 3 在写作中应用 profile,冲突时按 discipline > journal > personal 优先级裁决。注意区分"安全维度"和"风险维度"。

---

## 学术写作规范

> **写作 agent 在执行所有润色和段落生成前,必须先读** [`reference/writing/academic_writing_style.md`](../../reference/writing/academic_writing_style.md)——该文件定义了四项核心原则(精确性/简洁性/客观性/正式性)、6 大学科的语域差异表、hedging 和 strength 语言的正确使用方式,以及 TEEL 段落结构。下表的禁用词/推荐词/时态规则是该文件的快速参考子集。

### 禁用词替换

| 避免使用 | 替换为 | 原因 |
|---|---|---|
| "我觉得" | "实验结果表明" | 主观→客观 |
| "很明显" | "数据显示" | 断言→证据 |
| "非常好" | "显著优于" | 模糊→量化 |
| "可能大概" | "在 XX 条件下" | 含糊→具体 |
| "这个东西" | "该算法/模型" | 口语→专业 |
| "我们做了" | "我们实施/执行" | 口语→正式 |

### 推荐用词

- "基于..."(Based on...)
- "结果表明..."(The results demonstrate...)
- "相比之下..."(In contrast...)
- "值得注意的是..."(Notably...)
- "具体而言..."(Specifically...)
- "由此推断..."(This suggests that...)

### 时态使用

| 章节 | 时态 | 示例 |
|---|---|---|
| 引言/相关工作 | 现在时 | "XX is a critical problem..." |
| 方法描述 | 过去时 | "We implemented..." |
| 实验结果 | 过去时 | "The model achieved..." |
| 结论/讨论 | 现在时 | "These findings suggest..." |

---

## 段落结构

> **段落级决策参照** [`reference/writing/writing_judgment_framework.md`](../../reference/writing/writing_judgment_framework.md):用 Clarity Test 区分 load-bearing paragraphs(核心论证段落,需逐句打磨)vs supporting paragraphs(辅助段落,简明即可);用 Reader's Journey 四问(where am I / why / takeaway / next)确保读者在每个段落后都能回答"为什么这段在这里";用 So What 层次表确保每个章节都有明确的智识贡献而非仅描述。

### PEEL 结构

- **Point**:段落主旨句
- **Evidence**:证据支撑
- **Explanation**:解释说明
- **Link**:与下段连接

### 示例

```
Point: We propose a novel attention mechanism that
       addresses the limitation of standard self-attention.

Evidence: Standard self-attention computes pairwise
          interactions between all tokens, resulting in
          O(n²) complexity (Vaswani et al., 2017).

Explanation: Our method introduces a sparse attention
             pattern that only attends to local neighbors
             and global tokens, reducing complexity to O(n).

Link: This efficiency gain enables processing of longer
      sequences, which is crucial for document-level tasks
      (discussed in Section 4).
```

---

## 逻辑连贯性检查

### 检查清单
- [ ] 段落间是否有过渡句?
- [ ] 代词指代是否清晰?
- [ ] 逻辑连接词使用是否恰当?
- [ ] 论证顺序是否合理?
- [ ] 是否存在逻辑跳跃?

### 常用连接词

| 关系 | 词汇 |
|---|---|
| 因果 | therefore, thus, consequently, as a result |
| 对比 | however, in contrast, conversely, on the other hand |
| 递进 | furthermore, moreover, in addition, besides |
| 举例 | for example, for instance, specifically |
| 总结 | in summary, overall, taken together |

---

## 术语一致性

### 检查要点
- [ ] 术语首次出现是否定义?
- [ ] 缩写首次出现是否全称+缩写?
- [ ] 同一术语全文是否一致?
- [ ] 大小写是否统一?

### 术语表模板

```
Term        | First Appearance | Definition
------------|------------------|------------
Transformer | Section 1        | A neural architecture based on self-attention
BERT        | Section 2.1      | Bidirectional Encoder Representations from Transformers
```

---

## 章节特定建议

### Abstract

> **生成摘要时参照** [`reference/writing/abstract_writing_guide.md`](../../reference/writing/abstract_writing_guide.md)——结构化摘要(Background→Problem→Method→Results→Implications)与非结构化摘要有不同的句式模板和词数规则;中英双语摘要需分别遵循各自语言的 5 要素模型;关键词选择遵循领域标准术语。

### Introduction
- 从广泛背景到具体问题
- 突出研究 gap
- 明确 contribution

### Method
- 清晰、可复现
- 使用伪代码或算法框
- 复杂度分析

### Results
- 客观描述,不解释
- 引导读者看图表
- 报告统计显著性

### Discussion
- 解释结果意义
- 对比预期和实际
- 讨论局限性

---

## 常见错误

> **终稿自审时必须参照** [`reference/writing/writing_quality_check.md`](../../reference/writing/writing_quality_check.md) 执行 5 类规则扫描——(A) 25 个高频 AI 痕迹词自动替换、(B) 标点模式控制(破折号/分号/冒号列表密度)、(C) throat-clearing 开头句删除、(D) 结构模式警告(Rule of Three / 同义替换循环 / 二元对立 / 镜像结构)、(E) 句式变异度(burstiness)按章节目标调整。

| 错误 | 修正 |
|---|---|
| 模糊主语 "It is important" | 明确主语 "Accurate prediction is critical" |
| 冗余表达 "In order to" | 简洁 "To" |
| 被动滥用 "was done by us" | 主动 "We conducted" |
| 绝对化 "This is the best" | 谨慎 "This method outperforms" |

---

## 相关跨域 reference

- [`reference/writing/ACADEMIC-WRITING-GUIDE.md`](../../reference/writing/ACADEMIC-WRITING-GUIDE.md) — 数学符号、缩写、格式规范
- [`reference/writing/PAPER-WRITING-GUIDE.md`](../../reference/writing/PAPER-WRITING-GUIDE.md) 第 2 部分(用词与语言风格)+ 第 6 部分(常见错误)
- [`reference/writing/academic_writing_style.md`](../../reference/writing/academic_writing_style.md) — 英语学术写作语气
- [`reference/writing/writing_quality_check.md`](../../reference/writing/writing_quality_check.md) — 终稿前自检清单
- [`reference/writing/writing_judgment_framework.md`](../../reference/writing/writing_judgment_framework.md) — 写作质量多维评估
- [`reference/writing/abstract_writing_guide.md`](../../reference/writing/abstract_writing_guide.md) — 双语摘要撰写规范
- [`reference/writing/style_calibration_protocol.md`](../../reference/writing/style_calibration_protocol.md) — 风格学习
- [`reference/research/ground_truth_isolation_pattern.md`](../../reference/research/ground_truth_isolation_pattern.md) — 三层数据隔离防 Anti-Leakage
- 模板:[`templates/bilingual_abstract_template.md`](../../templates/bilingual_abstract_template.md) / [`templates/revision_tracking_template.md`](../../templates/revision_tracking_template.md)

## Passport I/O

- **Reads**: `outline`(章节写作目标)、`bibliography[]`(in-text 引用 cite key)、`argument_audit[]`(M5 claim 位置嵌入正文)、`corpus[]`(anti-leakage 协议的证据文件)
- **Writes**: `material_gaps[]`(每个插入的 `[MATERIAL GAP: ...]` 标记)、`current_stage` → `m6`
- **Stage transition**: advances passport to `current_stage = m6`(草稿正文写完,所有 claim 要么有证据支撑、要么明确标为 material gap)
