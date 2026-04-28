# Paper Assistant Skill

## 初衷

这个 Skill 的诞生源于一个简单的愿景：**让研究者从繁琐的论文写作事务中解放出来，专注于真正的创新——idea本身。**

## 目标

**终极目标：人只需要提供 idea，代码、验证、论文全部自动化。**

- ✅ **已实现**：论文写作规范、结构规划、语言润色、格式检查
- 🔄 **进行中**：代码辅助生成、实验设计自动化
- 📋 **规划中**：实验自动运行、论文初稿自动生成

## 当前功能

1. **论文结构规划** - IMRAD 标准大纲生成
2. **写作规范指导** - 学术语言、术语、时态规范
3. **格式规范管理** - Overleaf 项目命名、参考文献格式
4. **Prompt 模板库** - 大纲生成、段落润色、摘要撰写、实验检查

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
├── modules/                          # 八大写作模块（M1–M8）
├── reference/                          # 写作规范 + 期刊数据库
│   ├── ACADEMIC-WRITING-GUIDE.md     # 学术写作规范
│   ├── PAPER-WRITING-GUIDE.md        # 论文写作指南
│   ├── ccf_2026.sqlite               # CCF 分级数据
│   ├── ccf_2026.jsonl
│   └── impact_factor.sqlite3         # 期刊影响因子 / JCR / 中科院分区
├── script/paper/                     # 联网检索 + 文献质量评估脚本
│   ├── init.sh
│   ├── paper_search.sh               # S2 standard / bulk + CrossRef fallback
│   ├── venue_lookup.sh               # CCF + 影响因子综合查询
│   ├── author_info.sh                # 作者 H-index
│   ├── doi2bibtex.sh                 # DOI → BibTeX
│   └── find_evidence.sh              # 占位：自动找论据（待实现）
└── relate-work/                      # 论据/相关工作仓库（M1 写入，M3/M6 读取）
```

## 适用场景

- 系统性组织论文结构和写作流程
- 规范学术写作语言和格式
- 管理参考文献和引用格式
- 生成论文大纲或润色段落
- 检查实验设计完整性

## 🙏 致谢

本项目的**联网文献检索、期刊质量评估、BibTeX 生成**能力来自开源项目
[**citation-assistant**](https://github.com/ZhangNy301/citation-assistant)。

`script/paper/` 下的脚本（`paper_search.sh` / `venue_lookup.sh` / `author_info.sh` / `doi2bibtex.sh`）
以及 `reference/` 中的 CCF 与影响因子数据库（`ccf_2026.sqlite` / `impact_factor.sqlite3`）
均源自该项目，已根据本仓库的目录约定与八模块工作流做了路径与接口适配（多脚本合并、统一 `--mode` 参数、
DATA_DIR 重定向到 `reference/`）。

特别感谢：
- [Semantic Scholar](https://www.semanticscholar.org/) 提供学术检索 API
- [CrossRef](https://www.crossref.org/) 提供 DOI 元数据与 BibTeX 协商
- [impact_factor](https://github.com/suqingdong/impact_factor) 提供期刊影响因子数据库

---

*为科研效率而生。*
