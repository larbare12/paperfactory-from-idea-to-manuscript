# relate-work/

本目录是**论据/相关工作仓库**，连接 M1（选题诊断）的产出与 M3/M6（论证设计 / 写作）的消费。

## 写入方
- **M1 选题诊断**：用 `paper_search.sh --mode bulk` 拉到的候选论文落到这里，作为后续模块的本地检索池
- **M4 文献管理**：手工补充的关键文献（基础/方法/对比/相关四类）也写入此处
- **手工添加**：你在 reading 时记录的笔记、引用、idea 也可以直接放进来

## 读取方
- **M3 论证设计**：构建证据链时优先在这里找支撑
- **M6 写作辅助**：提出一个 claim 时，第一步在 relate-work/ 检索；找不到才回退到 `find_evidence.sh`（未实现，详见 [`script/paper/find_evidence.sh`](../script/paper/find_evidence.sh)）

## 文件命名约定（扁平、无子目录）

```
relate-work/
├── README.md                                    # 本文件
├── search-<idea-slug>-<YYYYMMDD>.json           # M1 bulk 搜索原始 JSON
├── search-<idea-slug>-<YYYYMMDD>.md             # 同次搜索的人读摘要
├── note-<topic>.md                              # 手工阅读笔记
└── ref-<bibkey>.md                              # 单篇精读卡
```

> 命名前缀（`search-` / `note-` / `ref-`）用来在扁平目录里按用途快速过滤；
> idea-slug / topic 用 kebab-case；日期 YYYYMMDD。

## 典型工作流

```bash
# 1. M1 拉候选并落盘（结果同时给人和机器看）
bash script/paper/paper_search.sh "rPPG vision transformer" \
     --mode bulk --year "2020-" --limit 50 \
     > relate-work/search-rppg-vit-20260428.json

# 2. M6 写作时，先在本地检索
grep -l "transformer" relate-work/*.md relate-work/*.json

# 3. 找不到本地证据 → 调用占位脚本（当前会报错，提示在草稿里标 [NEEDS-EVIDENCE]）
bash script/paper/find_evidence.sh "self-attention reduces O(n^2) to O(n) under sparse mask"
```
