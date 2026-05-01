# M4 结构规划模块

> **理论基础**：
> - 参见 [PAPER-WRITING-GUIDE.md](../reference/PAPER-WRITING-GUIDE.md) 第1.2节（IMRAD 标准结构）

## 功能
生成 IMRAD 大纲、章节边界、篇幅分配、写作顺序。

> **范围说明**：本模块**只管骨架，不管论证逻辑**。
> 论证主线、章节间的论点呼应、反驳预判等都归 [M5 论证设计](m5-argument.md)。
> 这条边界在旧版本是混的（M2 里塞了 4 个 sub-module 做论证），现在已经分开。

> **流程位置**：M1 选题 → M2 文献 → M3 实验 → **M4 结构（本模块）** → M5 论证 → M6 写作 → M7 总检
>
> **为什么排在实验之后？** 实验结果决定了哪些章节有内容、哪些章节是核心。先做完实验再分配篇幅，避免空骨架。

## 输入
- 选题（来自 M1）
- M3 已经产出的实验结果概要
- 预期贡献（理论/方法/实证）
- 目标期刊/会议
- 字数/页数限制

## 输出
- 完整大纲（章节 + 子章节 + 字数分配）
- 各章节的内容边界（什么应该写、什么不该写）
- 写作顺序建议

## 使用场景
1. 实验完成后，规划论文框架
2. 写作过程中，调整结构
3. 转投不同期刊，调整篇幅

## 规划步骤（4 步，不是 9 步）

### Step 1: 论文类型定位
理论型 / 方法型 / 实证型 / 综述型 → 决定篇幅模板（见下表）

### Step 2: 选定 IMRAD 骨架
按下方模板生成章节列表

### Step 3: 篇幅分配
按论文类型配比，给每章节分配字数/页数

### Step 4: 章节边界声明
每章节明确**写什么** + **不写什么**（拒绝模式），避免章节间内容串台

## IMRAD 标准结构模板

```
├── Abstract (200-300字)
│   └── 背景→问题→方法→结果→意义
│
├── Introduction (15-20%)
│   ├── 研究背景
│   ├── 问题陈述
│   ├── 研究目标
│   └── 贡献概述
│
├── Related Work (15-20%)
│   ├── 领域概述
│   ├── 现有方法分类
│   └── 本文与已有工作的区别
│
├── Methodology (25-30%)
│   ├── 问题定义
│   ├── 算法/模型描述
│   ├── 实现细节
│   └── 复杂度分析
│
├── Experiments (20-25%)
│   ├── 数据集描述
│   ├── 评估指标
│   ├── 对比方法
│   └── 实验设置
│
├── Results (10-15%)
│   ├── 主要结果
│   ├── 消融实验
│   └── 误差分析
│
├── Discussion (5-10%)
│   ├── 结果解释
│   ├── 局限性
│   └── 启示
│
└── Conclusion (5%)
    ├── 主要发现
    ├── 理论/实践意义
    └── 未来工作
```

## 篇幅分配参考

| 论文类型 | Introduction | Related Work | Method | Experiments | Results | Discussion | Conclusion |
|---------|-------------|--------------|--------|-------------|---------|------------|------------|
| 理论型 | 20% | 25% | 30% | 10% | 5% | 5% | 5% |
| 方法型 | 15% | 15% | 35% | 20% | 10% | 3% | 2% |
| 实证型 | 15% | 20% | 20% | 25% | 15% | 3% | 2% |

## 章节边界声明（最容易被忽略的一步）

**写大纲时，每章节都要明确"不写什么"**，否则下笔就串台：

| 章节 | 写什么 | 不写什么 |
|---|---|---|
| Introduction | 问题动机、贡献概述 | 详细方法、实验数字 |
| Related Work | 已有工作的分类与比较 | 本文的新方法 |
| Method | 本文方法 + 复杂度 | 实验结果、消融分析 |
| Experiments | 数据/指标/baseline 设置 | 解释为什么效果好（→ Discussion） |
| Results | 数字、图表 | 主观判断 |
| Discussion | 结果含义、局限性 | 重复 Results 的数字 |

## 写作顺序建议
1. **先写**：Method, Experiments（最容易，已有实验结果支撑）
2. **后写**：Introduction, Abstract（需要全文视角）
3. **穿插**：Related Work, Results, Discussion

## 示例 Prompt

```
请帮我规划以下论文的结构：

选题：[填入]
M3 实验结果概要：[填入]
预期贡献：[填入]
目标期刊：[填入]
字数限制：[填入]

请输出：
1. 论文类型定位
2. 完整大纲（章节 + 子章节 + 字数分配）
3. 章节边界声明（每章节"写什么/不写什么"）
4. 写作顺序建议
```

## 参考资源
- [PAPER-WRITING-GUIDE.md](../reference/PAPER-WRITING-GUIDE.md) 第1.2节
- 论文结构模板：[IMRaD](../templates/imrad_template.md) / [会议论文](../templates/conference_paper_template.md) / [案例研究](../templates/case_study_template.md) / [理论论文](../templates/theoretical_paper_template.md) / [文献综述](../templates/literature_review_template.md)
- 论证逻辑设计：[M5 论证设计](m5-argument.md)
- 写作执行：[M6 写作辅助](m6-writing.md)
- ARS: [论文结构模式](../reference/ars/paper/paper_structure_patterns.md) — IMRaD 变体与替代结构

## Passport I/O

- **Reads**: `research_question`, `methodology`, `bibliography[]`, `corpus[]` (M3 experiment result paths inform which chapters have content)
- **Writes**: `outline` (chapter keys with section arrays + word count allocation), `current_stage` → `m4`
- **Stage transition**: advances passport to `current_stage = m4` (paper skeleton with IMRAD chapter structure and section boundaries is now defined)
