---
name: paper-assistant
description: |
  全流程论文写作辅助 Skill。基于 Relic 论文的八层提取法和八模块架构，
  从 idea 到投稿提供系统化支持。
  
  使用场景：
  (1) 评估研究选题的可行性和创新性
  (2) 规划论文结构和论证逻辑
  (3) 管理文献和引用格式
  (4) 设计完整的实验方案
  (5) 学术写作语言润色
  (6) 模拟同行评审预判问题
  (7) 投稿前格式检查
---

# 论文写作助手 (Paper Assistant)

## 快速开始

本 Skill 旨在实现：**人只需提供 idea，论文全流程自动化**。

### 八模块架构

基于 [Relic 论文](https://arxiv.org/abs/2604.16116) 的八层提取法思想，设计八模块写作支持系统：

| 模块 | 名称 | 功能 | 对应阶段 |
|-----|------|------|---------|
| **M1** | [选题诊断](modules/m1-topic.md) | 评估 idea 可行性、创新性、契合度 | 选题 |
| **M2** | [结构规划](modules/m2-structure.md) | 生成 IMRAD 大纲、章节逻辑、篇幅分配 | 规划 |
| **M3** | [论证设计](modules/m3-argument.md) | 设计核心论点、证据链、反驳预判 | 方法论 |
| **M4** | [文献管理](modules/m4-literature.md) | 引用网络分析、关键文献识别、格式规范 | 文献综述 |
| **M5** | [实验设计](modules/m5-experiment.md) | 实验方案检查、指标选择、对比方法建议 | 实验 |
| **M6** | [写作辅助](modules/m6-writing.md) | 段落生成、语言润色、逻辑连贯性检查 | 撰写 |
| **M7** | [评审模拟](modules/m7-review.md) | 模拟审稿人视角、预判问题、修改建议 | 修改 |
| **M8** | [格式检查](modules/m8-format.md) | 期刊格式、参考文献、最终提交检查 | 投稿 |

## 使用方式

### 方式一：流程式（推荐新手）
按顺序调用模块：
```
idea → M1 → M2 → M3 → M4 → M5 → M6 → M7 → M8 → 投稿
```

### 方式二：按需调用（推荐老手）
根据当前卡点选择模块：
- "我的选题可行吗？" → [M1](modules/m1-topic.md)
- "不知道怎么组织论文" → [M2](modules/m2-structure.md)
- "审稿人说论证不充分" → [M3](modules/m3-argument.md) + [M7](modules/m7-review.md)
- "实验设计有问题" → [M5](modules/m5-experiment.md)

### 方式三：全自动（终极目标）
```
输入：idea + 数据
↓
M1-M8 自动串联
↓
输出：可投稿论文
```

## 快速参考

### 项目命名规范
```
姓名_标题_类型0x_年月

例：Y.Nie_EM-SDPD_final_2409
    Z.Wang_DRL-AF_paper02_2407
```

### 写作顺序建议
1. **先写**：Method, Experiments（最容易）
2. **后写**：Introduction, Abstract（需要全文视角）
3. **穿插**：Related Work, Results, Discussion

### 投稿前检查清单
- [ ] M1：选题经过诊断
- [ ] M2：结构完整合理
- [ ] M3：论证逻辑清晰
- [ ] M4：文献引用规范
- [ ] M5：实验充分完整
- [ ] M6：语言润色完成
- [ ] M7：评审问题预判
- [ ] M8：格式符合要求

## 详细规范

### 学术写作规范
参见 [ACADEMIC-WRITING-GUIDE.md](refence/ACADEMIC-WRITING-GUIDE.md)

### 论文写作指南
参见 [PAPER-WRITING-GUIDE.md](refence/PAPER-WRITING-GUIDE.md)

## 理论基础

本 Skill 的设计参考了以下研究：

### Relic 条件论文
> Liu, C. (2026). The Relic Condition: When Published Scholarship Becomes Material for Its Own Replacement. arXiv:2604.16116.

**核心思想**：
- 八层提取法：从已发表论文中提取稳定的推理架构
- 九模块技能架构：将提取的推理系统组织为可部署的技能约束
- 高可蒸馏性：学术写作本身具有结构化和可提取的特征

**对本 Skill 的启发**：
- 论文写作流程可以模块化、系统化
- 每个模块对应特定的写作任务和检查点
- 通过结构化约束提升写作质量和效率

## 目标愿景

> **最终目标：研究者只需提供 idea，论文全流程自动化完成。**

当前版本已实现：
- ✅ 八模块写作支持系统
- ✅ 每个模块的详细指南和 Prompt 模板
- ✅ 基于学术规范的质量检查清单

后续规划：
- 🔄 模块间自动化串联
- 📋 智能写作助手集成
- 🚀 一键生成可投稿论文

---

*Skill 版本: 0.2*
*最后更新: 2026-04-27*
*基于 Relic 论文八层提取法和八模块架构*
