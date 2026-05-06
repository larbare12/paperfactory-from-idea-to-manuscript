# M5 论证设计模块

> **理论基础**：
> - 参见 [PAPER-WRITING-GUIDE.md](../reference/writing/PAPER-WRITING-GUIDE.md) 第1.1节（明确的目标导向）
> - 基于 [Relic 论文](https://arxiv.org/abs/2604.16116) 推理架构提取思想

## 功能
设计核心论点、证据链、跨章节论证呼应、反驳预判。

> **范围说明**：本模块吸收了旧 M2 中关于论证的全部内容（论证主线、章节呼应、拒绝模式、发展导向），让"骨架（M4）"和"血肉（M5）"彻底分离。

> **流程位置**：M1 选题 → M2 文献 → M3 实验 → M4 结构 → **M5 论证（本模块）** → M6 写作 → M7 总检
>
> **为什么排在结构之后？** 论证主线必须扣住已有实验结果（M3）和章节骨架（M4）。在 M5 完成时，每个 claim 已经能定位到具体证据和具体章节。

> **证据来源约定**：本模块构建证据链时，所有证据必须可追溯到 [`relate-work/`](../relate-work/) 中的具体文件或 M3 实验结果。不在 relate-work/ 里的文献不算证据。这条约束让 M6 写作时可以无歧义地引用。

## 功能边界
本模块**不写正文**（那是 M6 的工作），只产出**论证骨架文件**（建议命名 `draft/argument-skeleton.md`），供 M6 按章节展开。

## 输入
- 核心 claim（一句话）
- M3 已有实验证据
- M2 已分类的 relate-work 文献
- 目标读者
- 潜在反对意见（可选）

## 输出
- 论证主线（从 Introduction 到 Conclusion 的连贯逻辑）
- 论证结构图（论点-证据-推论）
- 跨章节呼应表（每个 claim 在哪一章被提出、在哪一章被验证）
- 拒绝模式（明确什么 claim 不在本文范围内）
- 潜在漏洞识别 + 反驳预判
- 证据链完整性检查

## 使用场景
1. 设计论文核心论证
2. 准备答辩/演讲的论证逻辑
3. 回应审稿人质疑（M7 会回流到本模块）
4. 设计实验验证策略（如果 M3 实验未覆盖某 claim，回 M3）

---

## A. 核心论点提取与证据链

### A.1 提取核心 claim
明确论文的 main claim，用一句话概括

### A.2 构建证据链
识别支撑 claim 的关键证据，建立逻辑链条。**参照 [Claim 验证协议](../reference/review/claim_verification_protocol.md) 执行 E1-E3 三级验证管线**——E1 提取所有定量/事实性 claim → E2 追溯每条 claim 到其引用源 → E3 交叉比对 claim 文本与源文，按 verdict 分类（VERIFIED/MISMATCH/UNVERIFIABLE/SOURCE_NOT_FOUND）标记每条 claim。

### A.3 推理模式识别
确定论证类型：演绎/归纳/类比/因果。**参照 [论证推理框架](../reference/research/argumentation_reasoning_framework.md) 使用 Toulmin 模型（Claim/Data/Warrant/Backing/Qualifier/Rebuttal 六要素）和 IBE（最佳解释推理）系统化分析每条 claim 的论证强度**——若无法明确识别 Warrant，则该论证无论数据量多大都是弱论证。

### A.4 评估阈值设定
明确什么程度的证据可以支持 claim

### A.5 引用逻辑设计
选择关键文献支撑论证（**必须从 M2 已分类的 relate-work 中选**）

## B. 跨章节论证呼应（**原 M2 "Module 7/8" 内容并入本节**）

### B.1 论证主线
从 Introduction 到 Conclusion 应该是一条线：
```
Intro 提问 → Related Work 定位 → Method 提方案
        → Experiments 验证 → Results 出数字
        → Discussion 解释 → Conclusion 收口
```
每段必须为下一段铺垫，不能孤立。

### B.2 跨章节呼应表
列出每个核心 claim 的"提出位置 / 验证位置 / 复述位置"：

| Claim | 提出 | 验证 | 复述 |
|---|---|---|---|
| 方法 X 比 baseline 准确率高 | Intro 第3段 | Results 表1 | Conclusion 第1段 |
| 组件 B 是关键贡献 | Intro 第4段 | 消融实验（M3） | Discussion 第2段 |

这张表是 M6 写作的**必读输入**——它保证每个章节的内容都在为整体论证服务。

## C. 拒绝模式（**原 M2 "Module 5: 拒绝模式预设"并入本节**）

明确**本文不主张什么**，避免 over-claim 也避免审稿人误读：

| 拒绝模式 | 范例 |
|---|---|
| 不主张通用性 | "本文方法在领域 X 有效，未声明在领域 Y 也有效" |
| 不主张最优 | "在指标 M 上优于 baseline，未声明全方位最优" |
| 不主张取代 | "作为补充而非取代经典方法 Z" |

> 拒绝模式直接转化为论文中的 *limitations* 段落和 *future work* 段落。

## D. 反驳预判（红队）

提前列出审稿人最可能挑的刺，在写作阶段就把回应植入正文，而不是等 rebuttal 才回应。**DA 攻击阶段参照 [逻辑谬误目录](../reference/research/logical_fallacies.md) 逐条扫描论证链中的 32 种常见逻辑谬误**——formal / informal（相关性/证据/因果/推理）/ statistical 五大类，每种谬误有检测问题和研究案例——确保证据链不依赖谬误推理。

> **本节是 M7 投稿前总检的红队环节直接消费的输入**。M7 不重新造清单，而是回扫 M5 这份反驳预判是否每一条都已在论文中有 preempt。

---

## 论证结构模板（Toulmin 模式）

```
Claim: 本文提出的方法 X 在任务 Y 上优于现有方法 Z

Evidence 1: 在数据集 A 上，X 的准确率比 Z 高 15%
  → Support: 实验结果（M3 输出，Table 1）

Evidence 2: 消融实验显示组件 B 是关键贡献
  → Support: 消融实验（M3 输出，Table 2）

Evidence 3: 复杂度分析显示 X 与 Z 相当
  → Support: 理论分析（Section 3.4）

Warrant: 更高的准确率 + 可接受的复杂度 → 更好的方法

Backing: 领域共识认为准确率是首要指标
        （ref-vaswani2017.md, ref-he2016.md，来自 M2）

Qualifier: 在数据集 A 的条件下（**对应 C 节拒绝模式**）

Rebuttal: 如果考虑实时性要求，X 可能不如 Z
  → Response: X 的推理时间也在可接受范围内（M3 Table 3）
```

## 常见论证模式

### 模式 1: 新方法优于 baseline
```
Claim: 方法 X 优于现有方法
Evidence: 在多个数据集上的实验对比（M3）
Support: 消融实验验证关键组件（M3）
Counter: 复杂度/可解释性/泛化性讨论
```

### 模式 2: 理论分析指导实践
```
Claim: 理论 T 可以解释现象 P
Evidence: 理论推导 + 实证验证
Support: 文献中的类似现象（M2）
Counter: 边界条件和例外情况（C 节拒绝模式）
```

### 模式 3: 新任务/新数据集
```
Claim: 任务 T 具有重要意义
Evidence: 应用场景 + 现有方法的不足（M2 文献缺口）
Support: 初步实验结果（M3）
Counter: 与相关任务的区分度
```

## 示例 Prompt

```
请帮我设计以下核心论点的论证框架：

核心 Claim：[填入]
M3 实验证据概要：[填入]
M2 已分类文献：[指向 relate-work/ref-*.md 列表]
目标读者：[填入]

请输出：
1. 论证主线（章节级别）
2. 跨章节呼应表
3. 拒绝模式（本文不主张什么）
4. 反驳预判及回应（M7 总检会消费此项）
5. 证据链完整性评估
```

## 论证检查清单

- [ ] Claim 是否清晰明确？
- [ ] 每个证据是否可追溯到 M2 文献或 M3 实验？
- [ ] 推理过程是否有逻辑跳跃？
- [ ] 是否考虑了替代解释？
- [ ] 是否界定了适用范围（拒绝模式）？
- [ ] 是否回应了潜在反驳（红队）？
- [ ] 跨章节呼应表是否完整？

## 参考资源
- 参见 [PAPER-WRITING-GUIDE.md](../reference/writing/PAPER-WRITING-GUIDE.md) 第2.1节
- 上游：[M3 实验设计](m3-experiment.md)（提供实验证据）、[M2 文献管理](m2-literature.md)（提供文献证据）、[M4 结构规划](m4-structure.md)（提供章节骨架）
- 下游：[M6 写作辅助](m6-writing.md)（按论证骨架展开）、[M7 投稿前总检](m7-final-check.md)（回扫反驳预判）
- 论据池：[`relate-work/`](../relate-work/)
- ARS: [论证推理框架](../reference/research/argumentation_reasoning_framework.md) — Toulmin/Walton 论证模型详解
- ARS: [逻辑谬误目录](../reference/research/logical_fallacies.md) — DA 攻击时的常见逻辑谬误清单
- ARS: [AI 研究失败模式](../reference/compliance/ai_research_failure_modes.md) — AI 辅助写作的高频失败模式（Lu et al., 2026, Nature）

---

## Devil's Advocate Pass (autonomous-mode mandatory)

### 为什么 autonomous 模式下 DA 是强制项

| 模式 | 论证强度兜底方 | DA 需求 |
|---|---|---|
| Copilot | 用户在每章稿子上反驳，论证强度由用户兜底 | 可选，用户充当 DA |
| Autonomous | 没有用户反驳，AI 必须自己跟自己 argue | **强制**，无外部校验 |

**经验事实**：autonomous AI 多轮自审会出现 **cascade concession**（连续让步）——论证逐轮软化，claim 越改越保守。DA 协议是反 cascade concession 的硬约束，不是可选的"审稿辅助"。

### DA pass protocol

对论文中每个 CORE CLAIM（通常 3-7 个）执行以下三轮：

#### 1. Attack phase

Agent 生成它能想到的最强反驳。输出：

| 字段 | 说明 |
|---|---|
| counter_claim | 反方主张（一句话） |
| supporting_evidence | 反方可引用的支撑证据列表 |
| severity | 攻击严重度，1-5 整数（5 = 致命） |

#### 2. Rebuttal phase

Agent 反驳自己的攻击。输出：

| 字段 | 说明 |
|---|---|
| text | 反驳正文 |
| score | 反驳评分，1-5 整数（见下表） |
| evidence_cited | 反驳中引用的证据列表 |

**Rebuttal score 量表**：

| Score | 定义 |
|---|---|
| **1** | hand-wavy，无新证据，纯断言 |
| **2** | 部分回应，攻击的最强部分未回答 |
| **3** | 回应了主力但不如攻击方证据强 |
| **4** | 用相当或更强的证据回应了攻击 |
| **5** | 决定性反驳——证明攻击基于错误前提 |

#### 3. Concession decision

- **Rebuttal score >= 4**：KEEP 该 claim，将 DA 交换记录写入审计
- **Rebuttal score < 4**：CONCEDE——soften the claim / add a limitation / drop it
- 每次 concession 必须记录：原始 claim 文本、rebuttal 文本、score

### IRON RULES（不可违反）

**No consecutive concessions**：如果 claim N 让步了，claim N+1 必须 NOT concede，除非 rebuttal score < 2（迫使 agent 在某处反击，防止连续软化）。

**No frame-lock**：如果所有 rebuttal 都打 5 分（全部"决定性反驳"），说明 agent 没有真正尝试攻击（frame-lock：自我巩固而非反思）。阈值触发：换一个不同的 attack persona 重跑 DA。

**Audit trail mandatory**：每次 DA 交换必须写入 `schemas/da_audit.json` 实例文件（按 schema 校验）。不允许静默让步。

### 输出到 passport

passport.yaml 的 `argument_audit` 数组，每个 core claim 一条：

```yaml
argument_audit:
  - claim_id: "claim-1"
    claim_text: "..."
    da_attacks:
      - counter_claim: "..."
        supporting_evidence: ["..."]
        severity: 4
    rebuttal_score: 4
    frame_lock_detected: false
    decision: keep   # keep | soften | drop
```

### Limits

- **Min 3 core claims** per paper（少于 3 个说明论证骨架不足）
- **Max 7 core claims**（多于 7 个需拆分为 sub-claims，挂在 parent claim 下）
- 每个 claim 每轮 draft revision 恰好执行 **一次** DA pass

## Passport I/O

- **Reads**: `research_question` (main claim source), `outline` (M4 chapter structure for cross-chapter呼应), `bibliography[]` (M2 literature evidence), `corpus[]` (M3 experiment results as evidence)
- **Writes**: `argument_audit[]` (DA pass records: claim_id, claim_text, da_attacks[], rebuttal_score, frame_lock_detected, decision), `current_stage` → `m5`
- **Stage transition**: advances passport to `current_stage = m5` (argument backbone is audited and every core claim has a DA exchange with score >= 4 or a recorded concession)
