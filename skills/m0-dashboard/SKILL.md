---
name: m0-dashboard
description: |
  M0 项目仪表盘——流程外的常驻横切模块,**不属于线性步骤**。任何时点
  扫描 relate-work/ + draft/ 输出三态报表:已完成 / 待回填(NEEDS-EVIDENCE
  / TODO / 未读论文)/ 阻塞。M1-M7 任何阶段都可以调用 M0 看状态。/paper-
  assistant:init 命令首次扫描就是它。M0 只读不写,不动 manifest 也不动 draft。
allowed-tools: Bash, Read, Grep, Glob
---

# M0 项目仪表盘

> **定位**:横切常驻模块。**不是线性步骤的一环**。M1-M7 之间任何时点都可以调用 M0 看当前状态。

## 功能

扫 `relate-work/` + 当前论文草稿,输出三态报表:

- **✅ 已完成(done)**:有论据的 claim、有数据的实验、已写完的章节
- **🟡 待回填(pending)**:`[NEEDS-EVIDENCE]` 标记 / `TODO` / 空段落 / 已搜到但未引用的论文
- **🔴 阻塞(blocked)**:依赖外部(合作者数据、审稿意见、未实现的脚本)

## 输入

- 项目根目录(默认 `$PWD`)
- 草稿路径(`draft/**/*.tex` / `*.md`,可选)

## 输出

- 三态报表(Markdown 表格)
- 下一步建议(卡在哪个模块)

## 何时调用

| 触发 | 用途 |
|---|---|
| 每次写作 session 开始 | 看上次留下哪些 `[NEEDS-EVIDENCE]` 要回填 |
| M1 诊断完成后 | 确认 `relate-work/` 沉淀了多少候选 |
| M3 实验完成后 | 看实验结果是否覆盖 M5 论证链上每个 claim |
| 投稿前 | 进入 M7 总检之前先看是否有未闭合的 pending |

## 典型扫描命令

```bash
# 1. NEEDS-EVIDENCE / TODO / FIXME 标记
grep -rn '\[NEEDS-EVIDENCE\]\|\[MATERIAL GAP:\|TODO\|FIXME\|XXX' draft/ 2>/dev/null

# 2. relate-work/ 沉淀统计
ls relate-work/search-*.jsonl 2>/dev/null | wc -l
ls relate-work/ref-*.md       2>/dev/null | wc -l
ls relate-work/note-*.md      2>/dev/null | wc -l

# 3. manifest 状态分布
jq -r '.status // empty' relate-work/manifest.jsonl 2>/dev/null | sort | uniq -c

# 4. 已搜到但未引用的论文(在 manifest 但不在 .bib)
# 留作未来实现 - 需要 jq + bibtool 联合
```

## 报表模板

```markdown
## 项目状态报告(YYYY-MM-DD)

### ✅ 已完成
- [x] M1 选题诊断(search-<idea>-*.jsonl,N 篇候选)
- [x] M2 文献管理(M ref-*.md 精读卡,K 类已分类)
- [x] M3 实验设计(实验脚本 + 结果落到 ...)
- [x] M4 结构规划(draft/outline.md)
- [x] M5 论证设计(论证骨架 v0.x)
- [ ] M6 写作辅助(进度 P%)
- [ ] M7 投稿前总检

### 🟡 待回填
| 位置 | 类型 | 内容 |
|---|---|---|
| draft/intro.tex:42 | NEEDS-EVIDENCE | "ViT outperforms ResNet-50 by 5%" |
| draft/method.tex:118 | TODO | 复杂度分析 |
| relate-work/search-rppg-20260428.jsonl | UNREAD | 12 篇高引用未读 |

### 🔴 阻塞
| 项目 | 原因 | 解锁条件 |
|---|---|---|
| 实验结果 X | 等合作者算力 | 估计 2 周内 |

### 下一步建议
卡点在 M6(写作)。优先处理 N 个 `[NEEDS-EVIDENCE]`,先扫一遍 relate-work/ref-*.md。
```

## 与其他模块的关系

```
${CLAUDE_PLUGIN_ROOT}/                       $PWD (= 用户论文项目根)
  skills/                                    ┌─────────────────────────────┐
    citation-search/  (检索/验证基座)         │  M0 项目仪表盘(横切常驻)     │
    m0-dashboard/     (本 skill)             └─────────────────────────────┘
    m1-...m9-/        (各阶段 skill)                ↑读       ↑读       ↑读
  reference/  (跨域知识库)                   ┌──────────┴───┬─────┴────┐
  templates/                                 relate-work/   draft/      references.bib
                                             ↑写            ↑写         ↑写
                                             M1, M2, M6     M4, M5, M6  M2
```

**M0 只读不写**——扫别人的产物并汇总,从不修改任何文件 / passport 字段。

## 参考资源

- `relate-work/`(M1/M2 写入)
- [`citation-search/scripts/find_evidence.sh`](../citation-search/scripts/find_evidence.sh) — M6 触发 `[NEEDS-EVIDENCE]` 的脚本
- M7 投稿前总检会消费 M0 报表:pending 为 0 时才放行投稿

## Passport I/O

- **Reads**: `current_stage`, `research_question`, `methodology`, `bibliography[]`, `outline`, `corpus[]`, `material_gaps[]`, `argument_audit[]`, `reset_boundary`
- **Writes**: _none_(M0 是只读 dashboard,扫文件输出报表,从不 mutate passport)
- **Stage transition**: _none_(M0 stage-agnostic,任何 stage 都可调)
