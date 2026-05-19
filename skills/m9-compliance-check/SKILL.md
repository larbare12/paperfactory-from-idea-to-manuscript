---
name: m9-compliance-check
description: |
  M9 合规与伦理——投稿前最后一道硬门控。三段:A PRISMA-trAIce 17 项
  (AI 披露完整性)/ B RAISE 五维(可复现/可追责/诚信/安全/伦理)/
  C 期刊 AI 披露声明生成 / D 完整性门控(PASS/WARN/BLOCK)。任何
  RED 级别失败阻止投稿。包含 Tier 0 引用 audit 复检、剽窃检测、AI
  失败模式扫描、IRB 决策树、利益冲突声明检查。任何"投稿前合规检查"
  "AI 使用披露生成""伦理审计""期刊政策遵守"场景调用本 skill。
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

# M9 合规与伦理检查

> **流程位置**:M7 总检 → M8 同行评审 → **[M9 合规(本模块)]** → 投稿
>
> **门控级别**:本模块是投稿前的**最后一道硬门控**。任何 RED 级别的失败都会阻止投稿。

## 核心理念

学术论文中的 AI 辅助必须透明、可追溯。M9 确保论文满足:
1. **AI 使用披露**:清楚声明 AI 在哪些环节参与
2. **伦理合规**:研究过程符合伦理标准
3. **学术诚信**:无剽窃、无数据伪造、无引用捏造
4. **可复现性**:他人可以基于论文描述复现结果

---

## 工具依赖

| 工作 | 走哪 |
|---|---|
| Tier 0 引用真实性复检 | [`citation-search/scripts/verify_citations.sh`](../citation-search/scripts/verify_citations.sh) |
| 反幻觉协议(诚信段引用) | [`citation-search/reference/anti-hallucination-protocol`](../citation-search/reference/anti-hallucination-protocol.md) |

---

## 段 A:PRISMA-trAIce 检查(17 项清单)

> PRISMA-trAIce 是 ARS 项目对 PRISMA 2020 的 AI 化改编,用于审计 AI 辅助研究过程的完整性。**以下清单是简化摘要——执行段 A 前 agent 必须先读** [`reference/compliance/prisma_trAIce_protocol.md`](../../reference/compliance/prisma_trAIce_protocol.md) 获取完整的 17 项清单及其强制/高推荐/推荐/可选的四个层级(当前简化版丢失了层级信息,可能导致对非强制项做 BLOCK 误判)。

### A.1 标题与摘要
- [ ] **Item 1**:标题是否声明了 AI 辅助?(如要求)
- [ ] **Item 2**:摘要是否包含 AI 使用声明?

### A.2 方法
- [ ] **Item 3**:AI 工具的用途是否明确描述?
- [ ] **Item 4**:AI 介入的环节是否清晰标注?
- [ ] **Item 5**:人类监督的环节是否说明?
- [ ] **Item 6**:AI 输出的审核流程是否描述?

### A.3 结果
- [ ] **Item 7**:AI 生成的内容是否明确标注?
- [ ] **Item 8**:AI 辅助的分析是否独立验证?
- [ ] **Item 9**:是否报告了 AI 辅助的局限性?

### A.4 讨论
- [ ] **Item 10**:是否讨论了 AI 辅助对结论的影响?
- [ ] **Item 11**:AI 辅助的潜在偏差是否说明?
- [ ] **Item 12**:人类在最终决策中的角色是否明确?

### A.5 其他信息
- [ ] **Item 13**:是否声明了资金来源?**参照** [`reference/writing/funding_statement_guide.md`](../../reference/writing/funding_statement_guide.md) 按资助机构格式要求撰写——台湾 NSTC/MOST 需含学科代码和计划编号,国际机构各有模板;无资助也需声明。
- [ ] **Item 14**:是否声明了利益冲突?
- [ ] **Item 15**:数据和代码的可用性是否说明?
- [ ] **Item 16**:AI 工具的具体版本是否记录?
- [ ] **Item 17**:是否遵循了目标期刊的 AI 披露政策?**参照** [`reference/writing/venue_disclosure_policies.md`](../../reference/writing/venue_disclosure_policies.md) 按目标 venue 的 required phrasing 生成——若目标期刊不在已有的 6 个 venue 列表中,agent 应主动询问用户。

---

## 段 B:RAISE 框架检查

> RAISE = Reproducibility, Accountability, Integrity, Safety, Ethics。**注意:以下 B.1–B.5 五维度是 M9 的改编版——原始** [`reference/compliance/raise_framework.md`](../../reference/compliance/raise_framework.md) **定义了 4 项原则(人类监督/透明度/可复现性/适用性)+ 8 角色矩阵,且有明确的适用边界(系统综述 vs 一手研究)。执行段 B 前 agent 必须先读源文件,遇到改编版与源文件冲突时以源文件为准。**

### B.1 可复现性 (Reproducibility)
- [ ] 实验代码是否可获取?(或说明不可获取的原因)
- [ ] 数据集是否公开?(或说明访问方式)
- [ ] 方法描述是否足够详细可复现?
- [ ] 超参数和随机种子是否报告?
- [ ] 硬件和软件环境是否说明?
- **数据隔离**:参照 [`reference/research/ground_truth_isolation_pattern.md`](../../reference/research/ground_truth_isolation_pattern.md) 的三层架构(raw inputs / verified artifacts / ground-truth rubrics)确认评估答案从未进入生成上下文窗口,防止 reward hacking
- **参见**:[`reference/compliance/artifact_reproducibility_pattern.md`](../../reference/compliance/artifact_reproducibility_pattern.md)(`repro_lock` 结构化数据块格式)

### B.2 可追责性 (Accountability)
- [ ] AI 辅助内容是否有明确的负责人?
- [ ] 通讯作者是否对全稿负责?
- [ ] 作者贡献是否按 CRediT 标准声明?**参照** [`reference/writing/credit_authorship_guide.md`](../../reference/writing/credit_authorship_guide.md) 的 14 角色分类 + ICMJE 四条件——确认 AI 不列作者(9 大出版商政策汇总)、贡献矩阵模板正确、致谢与署名的边界清晰

### B.3 诚信 (Integrity)
- [ ] **引用是否经过 Tier 0 验证?** 运行 `verify_citations.sh`(M7 段 B 已跑过,M9 复检)
- [ ] 数据是否未篡改?
- [ ] 图表是否未被美化到误导程度?
- [ ] 实验结果是否全部报告(不选择性报告)?
- **AI 失败模式扫描**:参照 [`reference/compliance/ai_research_failure_modes.md`](../../reference/compliance/ai_research_failure_modes.md) 逐条检查 7 种模式的阻断条件——implementation errors / citation hallucination / experimental result hallucination / shortcut reliance / reframing errors as novel / methodology fabrication / early-stage perspective lock。每种模式有独立的检测问题和 CLEAR/SUSPECTED/INSUFFICIENT_EVIDENCE 判定规则
- **剽窃检测**:参照 [`reference/compliance/plagiarism_detection_protocol.md`](../../reference/compliance/plagiarism_detection_protocol.md) 执行第 D 阶段完整性检查——按采样率(Mode 1 为 30%、Mode 2 为 50%)对段落做原创性扫描,按严重度分级(VERBATIM > CLOSE_MATCH > PARAPHRASE > CLEAN)做不同处置

```bash
# Tier 0 复检(M9 强制门控)
bash "${CLAUDE_PLUGIN_ROOT}/skills/citation-search/scripts/verify_citations.sh" \
     draft/main.tex --bib relate-work/references.bib
```

### B.4 安全 (Safety)
- [ ] 研究是否涉及敏感数据?(如有,是否合规处理?)
- [ ] 研究是否涉及人类受试者?(如有,是否有 IRB 审批?)
- [ ] 研究成果是否可能被滥用?(如有,是否有 mitigations?)
- **参照** [`reference/compliance/ethics_checklist.md`](../../reference/compliance/ethics_checklist.md) 的安全部分进行双重用途评估、敏感数据合规检查

### B.5 伦理 (Ethics)
- [ ] 是否遵守了目标期刊的伦理政策?
- [ ] 是否获取了必要的数据使用许可?
- [ ] 是否考虑了研究的公平性和包容性?
- **参照** [`reference/compliance/ethics_checklist.md`](../../reference/compliance/ethics_checklist.md) 做全面伦理审计——包含 AI 披露完整性、归因诚信、公平代表性、数据伦理和利益冲突声明
- **IRB 相关用** [`reference/compliance/irb_decision_tree.md`](../../reference/compliance/irb_decision_tree.md) 判断审查级别

---

## 段 C:AI 使用披露

> **生成披露声明前先读两份文件**:[`reference/writing/venue_disclosure_policies.md`](../../reference/writing/venue_disclosure_policies.md) 提供 6 大 ML/NLP 会议(ICLR/NeurIPS/Nature/Science/ACL/EMNLP)的结构化字段(policy summary、required phrasing、preferred location、prohibited uses),按目标期刊匹配;[`reference/writing/funding_statement_guide.md`](../../reference/writing/funding_statement_guide.md) 提供台湾 NSTC/MOST 格式规范(含学科代码)、常见国际资助机构模板(NSF/NIH/ERC/JSPS)以及资助声明与利益冲突声明的区分规则。

### C.1 期刊 AI 披露政策速查

| 出版商 | 政策要求 |
|---|---|
| Nature / Springer | 披露 AI 工具名称、用途、版本;AI 不能列为作者 |
| Science / AAAS | AI 生成内容需标注;未经人类审核不可接受 |
| IEEE | 披露 AI 使用;对 AI 输出负责 |
| ACM | 披露 AI 工具及使用方式;作者对准确性负责 |
| Elsevier | 披露 AI 使用;区分人类撰写和 AI 辅助内容 |
| NeurIPS / ICML | 披露 AI 辅助;不能替代人类评审 |
| ACL / EMNLP | 需声明 AI 使用范围;鼓励标明具体段落 |

### C.2 披露声明模板

```markdown
## AI Usage Disclosure

The authors used Claude Code (Anthropic, version X.X) as an AI assistant
during the following stages of this research:

- **Literature search**: AI assisted in Semantic Scholar query formulation
  and initial paper screening. All papers were manually reviewed by the authors.
- **Experiment design**: AI helped generate an experiment checklist.
  All experiments were manually designed, executed, and verified.
- **Writing**: AI provided language polishing suggestions for selected paragraphs.
  All AI suggestions were manually reviewed and approved by the authors.
- **Citation verification**: AI ran the Tier 0 citation verification protocol
  via the Semantic Scholar API. All verification results were manually reviewed.

The authors take full responsibility for the content and accuracy of this paper.
```

---

## 段 D:完整性门控

> **执行段 D 前 agent 必须先读两份协议**:[`reference/compliance/compliance_checkpoint_protocol.md`](../../reference/compliance/compliance_checkpoint_protocol.md) 定义了 compliance_agent 的运行时行为——如何组合 PRISMA-trAIce 和 RAISE 决策、3 轮覆盖裁决升级阶梯、间隙标签词汇表以及阻断 UX 模板;[`reference/compliance/integrity_review_protocol.md`](../../reference/compliance/integrity_review_protocol.md) 定义了第 2.5/4.5 阶段门控的精确执行步骤(Stage A–E)、通过/失败规则和各阶段阻断条件。段 D 的 PASS/WARN/BLOCK 三态是两份协议的简化摘要,遇到边界情况以协议原文为准。

### 门控状态

| 状态 | 含义 | 行动 |
|---|---|---|
| 🟢 PASS | 所有项通过 | 可以投稿 |
| 🟡 WARN | 有需要声明的项 | 添加声明后过关 |
| 🔴 BLOCK | 有致命未解决项 | 回对应模块修复 |

### 硬门控触发条件(任一触发 = 🔴 BLOCK)

- 引用未经 Tier 0 验证(`verify_citations.sh` 未运行或存在未解释的 `S2_NOT_FOUND`)
- `[MATERIAL GAP]` 标记未全部解决或接受
- M5 DA pass 存在 score < 4 且无 recorded concession
- 存在未披露的利益冲突
- 目标期刊的 AI 政策要求未满足
- M7 段 A / M7 段 B 未通过

---

## 示例 Prompt

```
请对我的论文进行投稿前合规检查:

论文文件:[路径]
目标期刊:[填入]
AI 使用情况:[说明 AI 在哪些环节参与]

按段执行:
A. PRISMA-trAIce 17 项清单逐项检查
B. RAISE 五维度检查
C. 生成 AI 使用披露声明
D. 输出门控状态(PASS / WARN / BLOCK)
```

---

## 相关跨域 reference

- [`reference/compliance/prisma_trAIce_protocol.md`](../../reference/compliance/prisma_trAIce_protocol.md) — AI 研究 17 项完整清单
- [`reference/compliance/raise_framework.md`](../../reference/compliance/raise_framework.md) — 五维度学术诚信框架
- [`reference/compliance/compliance_checkpoint_protocol.md`](../../reference/compliance/compliance_checkpoint_protocol.md) — 双门控机制详解
- [`reference/compliance/cross_model_verification.md`](../../reference/compliance/cross_model_verification.md) — 可选的多模型交叉验证
- [`reference/compliance/ethics_checklist.md`](../../reference/compliance/ethics_checklist.md)
- [`reference/compliance/irb_decision_tree.md`](../../reference/compliance/irb_decision_tree.md)
- [`reference/writing/credit_authorship_guide.md`](../../reference/writing/credit_authorship_guide.md)
- [`reference/writing/funding_statement_guide.md`](../../reference/writing/funding_statement_guide.md)
- [`reference/writing/venue_disclosure_policies.md`](../../reference/writing/venue_disclosure_policies.md)
- [`reference/compliance/plagiarism_detection_protocol.md`](../../reference/compliance/plagiarism_detection_protocol.md)
- [`reference/compliance/ai_research_failure_modes.md`](../../reference/compliance/ai_research_failure_modes.md) — 7 种 AI 幻觉模式
- [`reference/compliance/integrity_review_protocol.md`](../../reference/compliance/integrity_review_protocol.md) — 2.5/4.5 阶段门控
- [`reference/research/ground_truth_isolation_pattern.md`](../../reference/research/ground_truth_isolation_pattern.md) — 三层数据隔离防 Reward Hacking

## Passport I/O

- **Reads**: _all fields_ — `current_stage`(必须 `m8` 才能进入)、`bibliography[]`(citation verification via Tier 0)、`material_gaps[]`(必须全部 resolved 或 accepted)、`argument_audit[]`(必须通过 DA threshold)、`corpus[]`(可复现性检查的证据文件)
- **Writes**: `current_stage` → `m9`(合规通过)或 blocks at `m8`(需修复)、`corpus[]`(合规报告路径)
- **Stage transition**: advances passport to `current_stage = m9` 若所有 gate 通过(PRISMA-trAIce + RAISE + AI 披露);否则 blocks with 结构化失败报告路由回责任模块
