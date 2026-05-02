# Paper Assistant Skill

## 初衷

这个 Skill 的诞生源于一个简单的愿景：**让研究者从繁琐的论文写作事务中解放出来，专注于真正的创新——idea本身。**

## 目标

**终极目标：人只需要提供 idea，代码、验证、论文全部自动化。**

- ✅ **已实现**：论文写作规范、结构规划、语言润色、格式检查
- 🔄 **进行中**：代码辅助生成、实验设计自动化
- 📋 **规划中**：实验自动运行、论文初稿自动生成

## 当前功能

### 十模块工作流（M0-M9）
1. **M0 项目仪表盘** - 横切状态总览
2. **M1 选题诊断** - 数据驱动的可行性/创新性评估
3. **M2 文献管理** - 引用网络分析、Tier 0 校验、bib 规范化
4. **M3 实验设计** - 实验方案、指标、消融、显著性全检查
5. **M4 结构规划** - IMRAD 骨架、章节边界声明
6. **M5 论证设计** - Toulmin 论证模型、Devil's Advocate 自审
7. **M6 写作辅助** - Anti-Leakage 协议、PEEL 段落、术语一致性
8. **M7 投稿前总检** - 内容红队 + 格式合规 + rebuttal 撰写
9. **M8 同行评审仿真** - 多视角审稿模拟 + 编辑决策（新增）
10. **M9 合规与伦理检查** - PRISMA-trAIce + RAISE + AI 披露（新增）

### 可执行工具
- Semantic Scholar / CrossRef / DOI API 调用
- CCF 期刊分级 + JCR 影响因子查询
- Tier 0 引用幻觉验证（Levenshtein 相似度）
- 证据查找（corpus-first / search-fills-gap）

### Prompt 资产（整合自 academic-research-skills）
- 46 个参考文件（研究/写作/评审/合规/方法论）
- 15 个结构化输出模板

## 快速开始

```
1. 提供你的研究 idea
2. 使用本 Skill 生成论文大纲
3. 按规范撰写各章节
4. 使用检查清单确保质量
5. 提交！
```

## 文档结构

```
.
├── SKILL.md                          # Skill 主文档（使用说明）
├── README.md                         # 本文件（项目介绍）
├── IMPROVEMENT_PLAN.md               # 改进计划文档
├── modules/                          # 十模块工作流（M0–M9）
│   ├── m0-dashboard.md               # 横切项目仪表盘
│   ├── m1-topic.md                   # 选题诊断
│   ├── m2-literature.md              # 文献管理 + 引用验证
│   ├── m3-experiment.md              # 实验设计
│   ├── m4-structure.md               # 结构规划
│   ├── m5-argument.md                # 论证设计 + DA 协议
│   ├── m6-writing.md                 # 写作辅助 + Anti-Leakage
│   ├── m7-final-check.md             # 投稿前总检
│   ├── m8-peer-review.md             # 同行评审仿真（新）
│   └── m9-compliance-check.md        # 合规与伦理检查（新）
├── reference/                        # 按主题组织的参考资料库
│   ├── writing/                       # 写作风格、语言、格式指南（15 文件）
│   ├── research/                      # 研究方法论、文献管理、实验设计（12 文件）
│   ├── review/                        # 同行评审、质量评估（9 文件）
│   ├── compliance/                    # 伦理、PRISMA-trAIce、RAISE、AI 披露（11 文件）
│   ├── handoff_schemas.md             # 跨阶段数据契约
│   ├── mode_spectrum.md               # 保真度 vs 原创性频谱
│   ├── ccf_2026.sqlite                # CCF 分级数据
│   ├── ccf_2026.jsonl
│   └── impact_factor.sqlite3          # 影响因子数据库
├── templates/                        # 结构化输出模板（15 文件，新）
│   ├── imrad_template.md
│   ├── conference_paper_template.md
│   ├── peer_review_report_template.md
│   └── ...（更多）
├── script/paper/                     # 联网检索 + 文献质量评估脚本
│   ├── init.sh
│   ├── paper_search.sh               # S2 standard / bulk + CrossRef fallback
│   ├── venue_lookup.sh               # CCF + 影响因子综合查询
│   ├── author_info.sh                # 作者 H-index
│   ├── doi2bibtex.sh                 # DOI → BibTeX
│   ├── find_evidence.sh              # 证据查找（已实现）
│   ├── verify_citations.sh           # 引用验证
│   └── check_material_gaps.sh        # 物料缺口扫描
└── relate-work/                      # 论据/相关工作仓库（M1 写入，M3/M6 读取）
```

## 适用场景

- 系统性组织论文结构和写作流程
- 规范学术写作语言和格式
- 管理参考文献和引用格式
- 生成论文大纲或润色段落
- 检查实验设计完整性

## 🙏 致谢

本项目的核心能力来源于以下开源项目的杰出工作：

### citation-assistant
**联网文献检索、期刊质量评估、BibTeX 生成**能力来自
[**citation-assistant**](https://github.com/ZhangNy301/citation-assistant)。
`script/paper/` 下的脚本（`paper_search.sh` / `venue_lookup.sh` / `author_info.sh` / `doi2bibtex.sh`）
以及 CCF 与影响因子数据库均源自该项目。

### academic-research-skills (ARS)
**M8/M9 模块设计及 reference/ 与 templates/ 中的 62 个参考文件和模板**
来自 [**academic-research-skills**](https://github.com/) 项目（Cheng-I Wu, CC-BY-NC 4.0）。
包括 PRISMA-trAIce 协议、RAISE 框架、多视角审稿人模型、APA 7 风格指南、
逻辑谬误目录、学术写作风格指南等参考资料。

特别感谢：
- [Semantic Scholar](https://www.semanticscholar.org/) 提供学术检索 API
- [CrossRef](https://www.crossref.org/) 提供 DOI 元数据与 BibTeX 协商
- [impact_factor](https://github.com/suqingdong/impact_factor) 提供期刊影响因子数据库

---

*为科研效率而生。*
