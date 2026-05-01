# M9 合规与伦理检查模块

> **理论基础**：
> - 基于 ARS shared compliance agent（PRISMA-trAIce + RAISE）
> - 参见 [PRISMA-trAIce 协议](../reference/compliance/prisma_trAIce_protocol.md)
> - 参见 [RAISE 框架](../reference/compliance/raise_framework.md)
> - 参见 [合规检查点协议](../reference/compliance/compliance_checkpoint_protocol.md)

## 功能
投稿前最终合规门控：检查 AI 使用透明性、伦理合规、数据隐私、可复现性、学术诚信。

> **流程位置**：M7 总检 → M8 同行评审 → **M9 合规检查（本模块）** → 投稿
>
> **门控级别**：本模块是投稿前的**最后一道硬门控**。任何 RED 级别的失败都会阻止投稿。

## 核心理念

学术论文中的 AI 辅助必须透明、可追溯。M9 确保论文满足：
1. **AI 使用披露**：清楚声明 AI 在哪些环节参与
2. **伦理合规**：研究过程符合伦理标准
3. **学术诚信**：无剽窃、无数据伪造、无引用捏造
4. **可复现性**：他人可以基于论文描述复现结果

---

## 段 A：PRISMA-trAIce 检查（17 项清单）

> PRISMA-trAIce 是 ARS 项目对 PRISMA 2020 的 AI 化改编，用于审计 AI 辅助研究过程的完整性。

### A.1 标题与摘要
- [ ] **Item 1**: 标题是否声明了 AI 辅助？（如要求）
- [ ] **Item 2**: 摘要是否包含 AI 使用声明？

### A.2 方法
- [ ] **Item 3**: AI 工具的用途是否明确描述？
- [ ] **Item 4**: AI 介入的环节是否清晰标注？
- [ ] **Item 5**: 人类监督的环节是否说明？
- [ ] **Item 6**: AI 输出的审核流程是否描述？

### A.3 结果
- [ ] **Item 7**: AI 生成的内容是否明确标注？
- [ ] **Item 8**: AI 辅助的分析是否独立验证？
- [ ] **Item 9**: 是否报告了 AI 辅助的局限性？

### A.4 讨论
- [ ] **Item 10**: 是否讨论了 AI 辅助对结论的影响？
- [ ] **Item 11**: AI 辅助的潜在偏差是否说明？
- [ ] **Item 12**: 人类在最终决策中的角色是否明确？

### A.5 其他信息
- [ ] **Item 13**: 是否声明了资金来源？
- [ ] **Item 14**: 是否声明了利益冲突？
- [ ] **Item 15**: 数据和代码的可用性是否说明？
- [ ] **Item 16**: AI 工具的具体版本是否记录？
- [ ] **Item 17**: 是否遵循了目标期刊的 AI 披露政策？

---

## 段 B：RAISE 框架检查

> RAISE = Reproducibility, Accountability, Integrity, Safety, Ethics

### B.1 可复现性 (Reproducibility)
- [ ] 实验代码是否可获取？（或说明不可获取的原因）
- [ ] 数据集是否公开？（或说明访问方式）
- [ ] 方法描述是否足够详细可复现？
- [ ] 超参数和随机种子是否报告？
- [ ] 硬件和软件环境是否说明？
- **参见**: [artifact_reproducibility_pattern.md](../reference/compliance/artifact_reproducibility_pattern.md)

### B.2 可追责性 (Accountability)
- [ ] AI 辅助内容是否有明确的负责人？
- [ ] 通讯作者是否对全稿负责？
- [ ] 作者贡献是否按 CRediT 标准声明？
- **参见**: [credit_authorship_guide.md](../reference/writing/credit_authorship_guide.md)

### B.3 诚信 (Integrity)
- [ ] 引用是否经过 Tier 0 验证？（运行 `verify_citations.sh`）
- [ ] 数据是否未篡改？
- [ ] 图表是否未被美化到误导程度？
- [ ] 实验结果是否全部报告（不选择性报告）？
- **参见**: [plagiarism_detection_protocol.md](../reference/compliance/plagiarism_detection_protocol.md)

### B.4 安全 (Safety)
- [ ] 研究是否涉及敏感数据？（如有，是否合规处理？）
- [ ] 研究是否涉及人类受试者？（如有，是否有 IRB 审批？）
- [ ] 研究成果是否可能被滥用？（如有，是否有 mitigations？）
- **参见**: [ethics_checklist.md](../reference/compliance/ethics_checklist.md)

### B.5 伦理 (Ethics)
- [ ] 是否遵守了目标期刊的伦理政策？
- [ ] 是否获取了必要的数据使用许可？
- [ ] 是否考虑了研究的公平性和包容性？
- **参见**: [irb_decision_tree.md](../reference/compliance/irb_decision_tree.md)

---

## 段 C：AI 使用披露

### C.1 期刊 AI 披露政策速查

| 出版商 | 政策要求 |
|--------|---------|
| Nature / Springer | 披露 AI 工具名称、用途、版本；AI 不能列为作者 |
| Science / AAAS | AI 生成内容需标注；未经人类审核不可接受 |
| IEEE | 披露 AI 使用；对 AI 输出负责 |
| ACM | 披露 AI 工具及使用方式；作者对准确性负责 |
| Elsevier | 披露 AI 使用；区分人类撰写和 AI 辅助内容 |
| NeurIPS / ICML | 披露 AI 辅助；不能替代人类评审 |
| ACL / EMNLP | 需声明 AI 使用范围；鼓励标明具体段落 |

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

## 段 D：完整性门控

### 门控状态

| 状态 | 含义 | 行动 |
|------|------|------|
| 🟢 PASS | 所有项通过 | 可以投稿 |
| 🟡 WARN | 有需要声明的项 | 添加声明后过关 |
| 🔴 BLOCK | 有致命未解决项 | 回对应模块修复 |

### 硬门控触发条件（任一触发 = 🔴 BLOCK）

- 引用未经 Tier 0 验证（`verify_citations.sh` 未运行或存在未解释的 S2_NOT_FOUND）
- `[MATERIAL GAP]` 标记未全部解决或接受
- M5 DA pass 存在 score < 4 且无 recorded concession
- 存在未披露的利益冲突
- 目标期刊的 AI 政策要求未满足
- M7 段 A / M7 段 B 未通过

---

## 示例 Prompt

```
请对我的论文进行投稿前合规检查：

论文文件：[路径]
目标期刊：[填入]
AI 使用情况：[说明 AI 在哪些环节参与]

请按段执行：
A. PRISMA-trAIce 17 项清单逐项检查
B. RAISE 五维度检查
C. 生成 AI 使用披露声明
D. 输出门控状态（PASS / WARN / BLOCK）
```

---

## 参考资源
- ARS: [PRISMA-trAIce 协议](../reference/compliance/prisma_trAIce_protocol.md) — AI 研究 17 项完整清单
- ARS: [RAISE 框架](../reference/compliance/raise_framework.md) — 五维度学术诚信框架
- ARS: [合规检查点协议](../reference/compliance/compliance_checkpoint_protocol.md) — 双门控机制详解
- ARS: [跨模型验证](../reference/compliance/cross_model_verification.md) — 可选的多模型交叉验证
- ARS: [伦理检查清单](../reference/compliance/ethics_checklist.md)
- ARS: [IRB 决策树](../reference/compliance/irb_decision_tree.md)
- ARS: [作者署名指南](../reference/writing/credit_authorship_guide.md)
- ARS: [资助声明指南](../reference/writing/funding_statement_guide.md)
- ARS: [期刊披露政策](../reference/writing/venue_disclosure_policies.md)
- ARS: [剽窃检测协议](../reference/compliance/plagiarism_detection_protocol.md)
- ARS: [可复现性审计](../reference/compliance/reproducibility_audit.md)

## Passport I/O

- **Reads**: _all fields_ — `current_stage` (must be `m8` to enter), `bibliography[]` (citation verification via Tier 0), `material_gaps[]` (must all be resolved or accepted), `argument_audit[]` (must pass DA threshold), `corpus[]` (evidence files for reproducibility check)
- **Writes**: `current_stage` → `m9` (compliance passed) or blocks at `m8` (fixes required), `corpus[]` (compliance report path)
- **Stage transition**: advances passport to `current_stage = m9` if all gates pass (PRISMA-trAIce + RAISE + AI disclosure); otherwise blocks with a structured failure report routing back to the responsible module
