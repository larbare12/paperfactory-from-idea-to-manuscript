# M7 投稿前总检模块

> **必读规范（进入本模块前必读）**：
> - [literature-research-protocol.md](../reference/literature-research-protocol.md) — 反幻觉三层验证 + 红线清单（M7 入口前必跑 `verify_citations.sh`）

> **理论基础**：
> - 参见 [PAPER-WRITING-GUIDE.md](../reference/writing/PAPER-WRITING-GUIDE.md) 第3部分（写作流程规范）
> - 参见 [PAPER-WRITING-GUIDE.md](../reference/writing/PAPER-WRITING-GUIDE.md) 附录（投稿前检查清单）
> - 参见 [ACADEMIC-WRITING-GUIDE.md](../reference/writing/ACADEMIC-WRITING-GUIDE.md) 全文（格式规范、参考文献、图表）

## 功能
**合并旧版 M7（评审模拟）+ M8（格式检查）**，分三段：A 内容红队 / B 格式合规 / C rebuttal 撰写。

> **流程位置**：M1 → M2 → M3 → M4 → M5 → M6 → **M7（本模块）** → 投稿
>
> **设计原则**：本模块**不重新造审稿人清单**——红队问题已经在 M5（反驳预判）和 M3（实验缺陷清单）里准备好。M7 的工作是**触发并回扫**这些清单，确保正文已经 preempt 了每一条；如果没有，就标 `[NEEDS-RESPONSE]` 退回到 M5/M6。

> **进入条件**：先调 [M0 项目仪表盘](m0-dashboard.md) 确认 pending 列表为空。pending 不空就回到对应模块继续。

---

## 段 A：内容红队（替代旧 M7 评审模拟）

### A.1 触发器：回扫 M5 反驳预判

```bash
# 列出 M5 论证骨架中的所有 Rebuttal
grep -A 2 'Rebuttal:' draft/argument-skeleton.md

# 对每条 Rebuttal，确认正文中是否已有对应的 preempt 段落
```

每条审稿人可能挑的刺，正文里要么已经回应、要么明确归到拒绝模式（M5 C 节）。两者都没有 → `[NEEDS-RESPONSE]`。

### A.2 触发器：回扫 M3 实验缺陷清单

逐条核对：

- [ ] 数据泄露：训练/测试是否完全隔离
- [ ] 对比公平性：相同设置、多次运行
- [ ] 指标完整性：主指标 + 互补指标
- [ ] 消融完整性：每个关键组件都有消融
- [ ] 显著性检验：报告了 p-value 或置信区间
- [ ] 误差分析：失败案例 + 按类别分析

未通过的项 → 回到 M3 补实验。

### A.3 五维总评（仅在 A.1 / A.2 通过后做）

| 维度 | 检查 |
|---|---|
| **新颖性** | 与最相似的 3 篇（来自 M1 Layer 6）差异是否在 Intro 明确 |
| **正确性** | 方法描述是否可复现、实验是否可信 |
| **完整性** | 必要的实验/分析都在 |
| **清晰度** | 算法/符号/图表是否易读 |
| **相关性** | 是否符合目标期刊定位（M2 的 venue_lookup 验证） |

### A.4 推荐意见自评

不通过 A.3 任何一项 → 不投。通过则进入段 B。

---

## 段 B：格式合规（替代旧 M8）

> **执行段 B 前先读 [期刊投稿指南](../reference/writing/journal_submission_guide.md)**——该文件包含完整的投稿前准备清单、cover letter 模板、各期刊特定要求速查表（含台湾 TSSCI 期刊）、数据可用性声明模板、AI 披露模板和审稿回复信结构。段 B 的 B.1–B.8 清单是该文件的基础子集，细节以该文件为准。

### B.1 文档结构清单
- [ ] 必需章节齐全
- [ ] 章节顺序正确
- [ ] 页码连续
- [ ] 目录完整（如要求）

### B.2 标题/作者/摘要
- [ ] 标题长度符合要求
- [ ] 作者信息完整、通讯作者标注
- [ ] 摘要字数符合要求
- [ ] 关键词数量符合要求

### B.3 正文格式
- [ ] 字体、字号、行距、页边距符合模板
- [ ] 公式编号连续
- [ ] 段落缩进一致

### B.4 图表
- [ ] 编号连续、caption 完整
- [ ] 矢量图优先（PDF/EPS）、≥300 dpi
- [ ] 字体 ≥8 pt
- [ ] 黑白可读
- [ ] 三线表，数字右对齐

### B.5 参考文献
- [ ] 格式符合要求（IEEE/ACM/APA）
- [ ] 排序正确（字母序 / 出现顺序）
- [ ] 所有引用都在 bib 中、所有 bib 项都被引用
- [ ] DOI/URL 完整
- [ ] 用 `bash script/paper/doi2bibtex.sh` 二次确认 BibTeX 正确

### B.6 期刊特定要求

| 期刊系列 | 关键约束 |
|---|---|
| IEEE Transactions | 双栏；公式 IEEEeqnarray；ref 按出现顺序编号 |
| ACM | acmart 模板；CCS 概念；figure/table 环境 |
| NeurIPS / ICML / ICLR | 单栏 9 页（含 ref）；第 9 页只允许 ref；匿名 |
| ACL / EMNLP | 官方模板；匿名；通常 8 页正文 + ref |

### B.7 LaTeX 编译
```bash
pdflatex paper.tex
bibtex paper
pdflatex paper.tex
pdflatex paper.tex
```
注意 Overfull/Underfull hbox 警告、未定义引用、缺图。

### B.8 提交材料清单
- [ ] 主文档（PDF）
- [ ] 源文件（LaTeX/Word）
- [ ] 补充材料
- [ ] 作者信息表
- [ ] 版权 / 利益冲突声明
- [ ] Cover letter（如要求）

---

## 段 C：rebuttal 撰写（投稿后）

### C.1 时机
段 C 在收到审稿意见后启用。如果意见命中 M5 已经 preempt 的反驳 → 直接引用正文段落回应；如果是新问题 → 走以下流程。

### C.2 回复信结构
1. 感谢审稿人时间和意见
2. 总体回应（概述主要修改）
3. 逐条回应：
   - 引用审稿人原话
   - 给出明确回应
   - 说明修改位置
4. 修改列表（详细列出所有修改）

### C.3 回应原则
- 礼貌、专业
- 直接回答问题
- 不辩解，除非确实误解
- **所有意见都要回应**

### C.4 回应模板
```
Reviewer Comment: "The comparison with XXX is missing."

Response: We thank the reviewer for this suggestion.
We have added a comparison with XXX in Section 4.2.
Specifically, we re-run XXX on our dataset using their
publicly available code. The results (Table 3) show that
our method outperforms XXX by 5.2% in terms of accuracy.

Change: Added comparison with XXX in Section 4.2,
Table 3 updated.
```

### C.5 回流到上游模块
| 审稿意见类型 | 回流到 |
|---|---|
| 实验不足 / 对比缺失 | M3 实验设计 |
| 论证有漏洞 | M5 论证设计 |
| 文献遗漏 | M2 文献管理 |
| 写作模糊 | M6 写作辅助 |
| 格式不符 | 段 B 重做 |

---

## 示例 Prompt

```
请对以下论文做投稿前总检：

论文文件：[上传或路径]
目标期刊：[填入]
M5 论证骨架：[路径]
M3 实验记录：[路径]

请按段执行：
A. 内容红队：回扫 M5 反驳预判和 M3 实验缺陷清单，
   列出未 preempt 的 [NEEDS-RESPONSE]
B. 格式合规：按目标期刊清单逐项检查
C. （投稿后）按收到的审稿意见生成 rebuttal 草稿
```

## 常见问题对照表

| 问题 | 触发段 | 修正 |
|---|---|---|
| 页数超限 | B | 精简内容或用附录 |
| 格式不符 | B | 用官方模板 |
| 图表模糊 | B | 矢量图替换 |
| 反驳未 preempt | A.1 | 回 M5/M6 补段落 |
| 实验缺漏 | A.2 | 回 M3 补实验 |
| 引用格式混乱 | B.5 | `doi2bibtex.sh` 重生成 |

## 参考资源
- [ACADEMIC-WRITING-GUIDE.md](../reference/writing/ACADEMIC-WRITING-GUIDE.md)
- [PAPER-WRITING-GUIDE.md](../reference/writing/PAPER-WRITING-GUIDE.md)
- BibTeX 工具：[`script/paper/doi2bibtex.sh`](../script/paper/doi2bibtex.sh)
- 上游：[M0 仪表盘](m0-dashboard.md) / [M3 实验](m3-experiment.md) / [M5 论证](m5-argument.md) / [M6 写作](m6-writing.md)
- ARS: [质量评估 rubrics](../reference/review/quality_rubrics.md) — 论文质量多维度评分标准
- ARS: [审稿标准框架](../reference/review/review_criteria_framework.md) — 期刊审稿 criteria 完整框架
- ARS: [编辑决策标准](../reference/review/editorial_decision_standards.md) — 编辑视角的接收/修改/拒绝决策
- ARS: [期刊投稿指南](../reference/writing/journal_submission_guide.md) — 各期刊投稿流程与要求
- ARS: [剽窃检测协议](../reference/compliance/plagiarism_detection_protocol.md) — 文本原创性检查
- ARS: [常见失败路径](../reference/review/failure_paths.md) — 投稿被拒的高频失败模式
- ARS: [APA 7th 快速参考](../reference/writing/apa7_style_guide.md) — 文档格式/引用/参考文献/图表规范
- ARS: [各领域顶级期刊](../reference/review/top_journals_by_field.md) — 投稿目标选择与 EIC 身份校准
- ARS: [作者署名指南](../reference/writing/credit_authorship_guide.md) — 作者贡献声明规范
- ARS: [资助声明指南](../reference/writing/funding_statement_guide.md) — 资助信息披露规范
- ARS: [期刊披露政策](../reference/writing/venue_disclosure_policies.md) — 各期刊 AI 使用披露要求
- 模板：[同行评审报告](../templates/peer_review_report_template.md) / [编辑决策](../templates/editorial_decision_template.md) / [修改回复](../templates/revision_response_template.md)

## Passport I/O

- **Reads**: _all fields_ — `current_stage` (must be m6 to enter), `research_question`, `methodology`, `bibliography[]` (ref format + completeness via B.5), `outline` (chapter checklist via B.1), `corpus[]` (evidence file verification), `material_gaps[]` (must be empty or all "accepted" to proceed), `argument_audit[]` (rebuttal preempt scan via A.1), `reset_boundary` (checkpoint hash before final submission)
- **Writes**: `current_stage` → `done` (only if all A/B segments pass; any failure blocks this transition and routes back to the responsible module), `material_gaps[]` (may mark newly discovered gaps during red-team scan)
- **Stage transition**: advances passport to `current_stage = done` (paper is submission-ready; all claims audited, all formats compliant, all material gaps resolved or accepted)
