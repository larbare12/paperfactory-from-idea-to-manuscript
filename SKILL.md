---
name: paper-assistant
description: |
  全流程论文写作辅助 Skill。基于 Relic 论文的八层提取法，整合 academic-research-skills (ARS) 
  的丰富 prompt 资产，形成 M0-M9 十模块架构，从 idea 到投稿提供系统化支持。
  
  使用场景：
  (1) 评估研究选题的可行性和创新性
  (2) 规划论文结构和论证逻辑
  (3) 管理文献和引用格式
  (4) 设计完整的实验方案
  (5) 学术写作语言润色
  (6) 模拟同行评审预判问题
  (7) 投稿前格式与合规检查
---

# 论文写作助手 (Paper Assistant)

## 快速开始

本 Skill 旨在实现：**人只需提供 idea，论文全流程自动化**。

### 模块架构（M0 + M1–M9）

基于 [Relic 论文](https://arxiv.org/abs/2604.16116) 的八层提取法思想，并整合 [academic-research-skills](https://github.com/) 的 prompt 资产，扩展为 1+9 架构：M0 是横切的常驻模块，M1–M9 按"研究 → 写作 → 评审 → 合规 → 投稿"的真实顺序排列。

| 模块 | 名称 | 功能 | 对应阶段 |
|-----|------|------|---------|
| **M0** | [项目仪表盘](modules/m0-dashboard.md) | 扫描 relate-work/ 与草稿，输出"已完成 / 待回填 / 阻塞"报表 | 横切（任何阶段可调） |
| **M1** | [选题诊断](modules/m1-topic.md) | 用 bulk 搜索做数据驱动的可行性、创新性、契合度评估 | 选题 |
| **M2** | [文献管理](modules/m2-literature.md) | 在 M1 沉淀的检索池上分类、精读、bib 整理、引用验证 | 文献综述 |
| **M3** | [实验设计](modules/m3-experiment.md) | 实验方案、指标、对比方法、消融、显著性检验 | 实验 |
| **M4** | [结构规划](modules/m4-structure.md) | 实验完成后规划 IMRAD 骨架、篇幅、章节边界（**只管骨架，不管论证**） | 规划 |
| **M5** | [论证设计](modules/m5-argument.md) | 论证主线、跨章节呼应、拒绝模式、反驳预判（**血肉**） | 方法论 |
| **M6** | [写作辅助](modules/m6-writing.md) | 按 M5 论证骨架展开正文；relate-work 优先 + `[NEEDS-EVIDENCE]` 标记 | 撰写 |
| **M7** | [投稿前总检](modules/m7-final-check.md) | A 内容红队（回扫 M3/M5）+ B 格式合规 + C rebuttal 撰写 | 修改 |
| **M8** | [同行评审仿真](modules/m8-peer-review.md) | 多视角审稿模拟（领域/方法/专家/跨领域/DA）+ 编辑决策 + 修改路线图 | 评审 |
| **M9** | [合规与伦理检查](modules/m9-compliance-check.md) | PRISMA-trAIce 17 项 + RAISE 五维度 + AI 披露 + 最终门控 | 合规 / 投稿 |

> **v0.3 变更说明**：扩展为 M0-M9 十模块架构。新增 M8（同行评审仿真，整合 ARS academic-paper-reviewer 的 5 审稿人模型）和 M9（合规与伦理检查，整合 ARS compliance agent 的 PRISMA-trAIce + RAISE 双框架）。M1-M7 增强了对 ARS 参考资料的引用。新增 `templates/` 目录（15 个模板）和 `reference/ars/` 目录（46 个参考资料）。

## 使用方式

### 方式一：流程式（推荐新手）
按顺序调用模块（M0 横切，任何阶段都能查状态）：
```
idea → M1 → M2 → M3 → M4 → M5 → M6 → M7 → M8 → M9 → 投稿
              ↑
          M0 项目仪表盘（横切）
```

### 方式二：按需调用（推荐老手）
根据当前卡点选择模块：
- "我的选题可行吗？" → [M1](modules/m1-topic.md)
- "不知道当前进度卡在哪儿" → [M0](modules/m0-dashboard.md)
- "文献怎么组织、引用怎么管" → [M2](modules/m2-literature.md)
- "实验设计有缺陷" → [M3](modules/m3-experiment.md)
- "不知道怎么组织论文骨架" → [M4](modules/m4-structure.md)
- "论证不充分 / 审稿人会怎么挑" → [M5](modules/m5-argument.md)
- "下笔难、找不到论据" → [M6](modules/m6-writing.md)
- "投稿前最后总检 / 写 rebuttal" → [M7](modules/m7-final-check.md)
- "模拟审稿人怎么看我的论文" → [M8](modules/m8-peer-review.md)
- "AI 使用披露 / 伦理合规检查" → [M9](modules/m9-compliance-check.md)

### 方式三：全自动（终极目标）
```
输入：idea + 数据
↓
M1–M7 自动串联（M0 持续监控状态）
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
- [ ] M0：仪表盘的 pending 列表为空
- [ ] M1：选题经过数据驱动诊断（relate-work/ 已沉淀候选）
- [ ] M2：文献分类完成、bib 规范、Tier 0 引用验证通过
- [ ] M3：实验充分完整（数据/对比/消融/显著性）
- [ ] M4：章节骨架清晰、篇幅符合期刊
- [ ] M5：论证主线完整、DA pass 通过（score >= 4）
- [ ] M6：所有 [MATERIAL GAP] 和 [NEEDS-EVIDENCE] 已回填
- [ ] M7：内容红队 + 格式合规 双双通过
- [ ] M8：同行评审仿真通过、修改路线图已完成
- [ ] M9：PRISMA-trAIce + RAISE 合规、AI 披露声明已添加

## 详细规范

### 学术写作规范
参见 [ACADEMIC-WRITING-GUIDE.md](reference/ACADEMIC-WRITING-GUIDE.md)

### 论文写作指南
参见 [PAPER-WRITING-GUIDE.md](reference/PAPER-WRITING-GUIDE.md)

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
- ✅ M0-M9 十模块写作支持系统
- ✅ 每个模块的详细指南和 Prompt 模板
- ✅ 基于学术规范的质量检查清单
- ✅ 多视角同行评审仿真（M8）
- ✅ PRISMA-trAIce + RAISE 合规检查（M9）
- ✅ 46 个 ARS 参考资料（reference/ars/）
- ✅ 15 个结构化输出模板（templates/）
- ✅ 可执行脚本（搜索、引用验证、证据查找）

后续规划：
- 🔄 模块间自动化串联 (Material Passport)
- 📋 跨模型交叉验证集成
- 🚀 一键生成可投稿论文

---

*Skill 版本: 0.3*
*最后更新: 2026-04-30*
*基于 Relic 论文八层提取法 + academic-research-skills prompt 资产整合*
