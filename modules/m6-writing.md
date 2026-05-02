# M6 写作辅助模块

> **理论基础**：
> - 参见 [ACADEMIC-WRITING-GUIDE.md](../reference/ACADEMIC-WRITING-GUIDE.md) 全文（数学符号、缩写、格式规范）
> - 参见 [PAPER-WRITING-GUIDE.md](../reference/PAPER-WRITING-GUIDE.md) 第2部分（用词与语言风格）
> - 参见 [PAPER-WRITING-GUIDE.md](../reference/PAPER-WRITING-GUIDE.md) 第6部分（常见错误与避免方法）

> **流程位置**：M1 → M2 → M3 → M4 → M5 → **M6（本模块）** → M7 总检
> 本模块按 [M5 论证设计](m5-argument.md) 产出的论证骨架展开正文，依据 [M4 结构规划](m4-structure.md) 的章节边界控制内容。

## IRON RULE: Anti-Leakage Protocol

> **IRON RULE — 不可违反**: 写作 agent 严禁用 parametric memory（模型预训练知识）填充任何事实空白。所有数据点、引用、统计数字、人物言论必须有 relate-work/ 中的本地证据或 find_evidence.sh 实时检索结果作为来源。

### When evidence is missing

遇到任何无法用 find_evidence.sh 找到证据的事实点，必须在草稿中插入 `[MATERIAL GAP: <一句话描述需要的证据类型>]` 标记。例如：

- `[MATERIAL GAP: 需要 2024 年 LLM hallucination 在医学领域的实证 benchmark]`
- `[MATERIAL GAP: 需要 GPT-4 vs Claude 在数学推理上的最新对比数据]`

### Why this matters in autonomous mode

Copilot 模式下用户每段都看，能当场抓出"AI 编了一个看起来合理的数字"。
Autonomous 模式下用户只看终稿，编造的数字混在真实数字中**几乎不可能被察觉**。
IRON RULE 的存在是为了**让缺证据的地方在终稿里显眼可见**，便于人类编辑回头补或删。

### Enforcement

- 写作过程中：agent 主动打标记，不许"略过"或"用相似数据替代"
- 终稿前：自动脚本 `script/paper/check_material_gaps.sh` 扫描全文，发现 `[MATERIAL GAP]` 则拒绝输出 final draft
- 解决方式：要么补上证据后删除标记，要么明确接受标记保留作为"待补"

---

## 功能
段落生成、语言润色、逻辑连贯性检查。
**核心约束**：每提出一个 claim，必须先在 `relate-work/` 找到本地证据；找不到才回退到 `find_evidence.sh`（corpus-first / search-fills-gap 流程）。

---

## 🔒 写作前置规则：观点必须有论据

> 这条规则**优先级高于所有润色和结构建议**。先有论据，再有观点。

### 流程

```
要写的 claim
    ↓
Step A. 在 relate-work/ 检索是否已有支撑材料
    ↓
   ├─ 找到 → 直接引用（cite key 取自 ref-*.md 或 search-*.json）
   │
   └─ 没找到 → Step B. 调用 find_evidence.sh（占位脚本）
                  ↓
                 ├─ 脚本实现后 → 自动检索 + 写入 relate-work/ + 给出 cite key
                 │
                 └─ 当前未实现（exit 1）→ 在草稿对应位置标记 [NEEDS-EVIDENCE]，
                                          继续写作不阻塞，事后回填
```

### 操作清单

```bash
# Step A：本地检索（扁平目录里 grep 即可）
grep -li "<claim 关键词>" relate-work/*.md relate-work/*.json

# Step B：找不到时调占位脚本
bash script/paper/find_evidence.sh "<完整 claim 一句话>"
# 当前会 exit 1，stderr 输出 {"error": "not implemented yet", ...}
# 触发约定：在草稿对应句子末尾插入 [NEEDS-EVIDENCE]
```

### 示例

> 草稿原句：
> > Vision Transformer outperforms ResNet-50 on ImageNet by 5%.
>
> 处理：
> 1. `grep -li "vision transformer.*imagenet" relate-work/*` → 命中 `ref-dosovitskiy2021vit.md`
> 2. 替换为：
>    > Vision Transformer outperforms ResNet-50 on ImageNet by 5%~\cite{dosovitskiy2021vit}.
>
> 若 grep 无命中：
> 1. `bash script/paper/find_evidence.sh "ViT outperforms ResNet-50 on ImageNet"` → exit 1
> 2. 替换为：
>    > Vision Transformer outperforms ResNet-50 on ImageNet by 5% [NEEDS-EVIDENCE].
> 3. [M0 项目仪表盘](m0-dashboard.md) 会列出所有 `[NEEDS-EVIDENCE]` 等待回填，[M7 投稿前总检](m7-final-check.md) 会拒绝带有未回填标记的稿件进入投稿流程。

### 为什么不直接联网搜？

故意留 `find_evidence.sh` 作为**占位** 而非默认行为，原因：
- 联网搜索的结果应当先经用户 review 再写入 relate-work/，避免引入未审核的引用
- 占位的存在让"哪些 claim 还没有论据"显式可见，而不是被自动填充掩盖
- 等 `find_evidence.sh` 真正实现后，行为切换是单点改动

---

## 输入
- 草稿段落
- 目标章节（Introduction/Method/Results等）
- 写作规范要求
- 目标期刊风格

## 输出
- 语言润色版本
- 逻辑连贯性检查报告
- 术语一致性检查
- 时态和语态建议
- 学术风格改进建议

## 使用场景
1. 初稿撰写
2. 语言润色
3. 逻辑检查
4. 投稿前最终润色

## 学术写作规范

### 禁用词替换
| 避免使用 | 替换为 | 原因 |
|---------|--------|------|
| "我觉得" | "实验结果表明" | 主观→客观 |
| "很明显" | "数据显示" | 断言→证据 |
| "非常好" | "显著优于" | 模糊→量化 |
| "可能大概" | "在XX条件下" | 含糊→具体 |
| "这个东西" | "该算法/模型" | 口语→专业 |
| "我们做了" | "我们实施/执行" | 口语→正式 |

### 推荐用词
- "基于..."（Based on...）
- "结果表明..."（The results demonstrate...）
- "相比之下..."（In contrast...）
- "值得注意的是..."（Notably...）
- "具体而言..."（Specifically...）
- "由此推断..."（This suggests that...）

### 时态使用
| 章节 | 时态 | 示例 |
|-----|------|------|
| 引言/相关工作 | 现在时 | "XX is a critical problem..." |
| 方法描述 | 过去时 | "We implemented..." |
| 实验结果 | 过去时 | "The model achieved..." |
| 结论/讨论 | 现在时 | "These findings suggest..." |

## 段落结构

### PEEL 结构
- **Point**：段落主旨句
- **Evidence**：证据支撑
- **Explanation**：解释说明
- **Link**：与下段连接

### 示例
```
Point: We propose a novel attention mechanism that 
       addresses the limitation of standard self-attention.

Evidence: Standard self-attention computes pairwise 
          interactions between all tokens, resulting in 
          O(n²) complexity (Vaswani et al., 2017).

Explanation: Our method introduces a sparse attention 
             pattern that only attends to local neighbors 
             and global tokens, reducing complexity to O(n).

Link: This efficiency gain enables processing of longer 
      sequences, which is crucial for document-level tasks 
      (discussed in Section 4).
```

## 逻辑连贯性检查

### 检查清单
- [ ] 段落间是否有过渡句？
- [ ] 代词指代是否清晰？
- [ ] 逻辑连接词使用是否恰当？
- [ ] 论证顺序是否合理？
- [ ] 是否存在逻辑跳跃？

### 常用连接词
| 关系 | 词汇 |
|-----|------|
| 因果 | therefore, thus, consequently, as a result |
| 对比 | however, in contrast, conversely, on the other hand |
| 递进 | furthermore, moreover, in addition, besides |
| 举例 | for example, for instance, specifically |
| 总结 | in summary, overall, taken together |

## 术语一致性

### 检查要点
- [ ] 术语首次出现是否定义？
- [ ] 缩写首次出现是否全称+缩写？
- [ ] 同一术语全文是否一致？
- [ ] 大小写是否统一？

### 术语表模板
```
Term        | First Appearance | Definition
------------|------------------|------------
Transformer | Section 1        | A neural architecture based on self-attention
BERT        | Section 2.1      | Bidirectional Encoder Representations from Transformers
```

## 示例 Prompt

### 语言润色
```
请润色以下段落，要求：
1. 保持学术语气
2. 消除口语化表达
3. 增强逻辑连贯性
4. 检查时态正确性
5. 确保术语一致

原文：[填入段落]

目标期刊风格：[填入]
```

### 段落生成
```
请帮我撰写关于以下内容的段落：

主题：[填入]
章节：[填入]
关键信息：[填入]
引用：[填入]

要求：
1. 使用 PEEL 结构
2. 符合学术写作规范
3. 包含过渡句
4. 长度：[填入] 词
```

## 章节特定建议

### Introduction
- 从广泛背景到具体问题
- 突出研究 gap
- 明确 contribution

### Method
- 清晰、可复现
- 使用伪代码或算法框
- 复杂度分析

### Results
- 客观描述，不解释
- 引导读者看图表
- 报告统计显著性

### Discussion
- 解释结果意义
- 对比预期和实际
- 讨论局限性

## 常见错误

| 错误 | 修正 |
|-----|------|
| 模糊主语 "It is important" | 明确主语 "Accurate prediction is critical" |
| 冗余表达 "In order to" | 简洁 "To" |
| 被动滥用 "was done by us" | 主动 "We conducted" |
| 绝对化 "This is the best" | 谨慎 "This method outperforms" |

## 参考资源
- 参见 [PAPER-WRITING-GUIDE.md](../reference/PAPER-WRITING-GUIDE.md) 第2部分
- 参见 [ACADEMIC-WRITING-GUIDE.md](../reference/ACADEMIC-WRITING-GUIDE.md)
- 本地论据池：[`relate-work/`](../relate-work/)
- 占位检索脚本：[`script/paper/find_evidence.sh`](../script/paper/find_evidence.sh)（已实现，corpus-first / search-fills-gap 流程）
- ARS: [学术写作风格](../reference/writing/academic_writing_style.md) — 英语学术写作语气与风格指南
- ARS: [写作质量检查](../reference/writing/writing_quality_check.md) — 终稿前写作质量自检清单
- ARS: [写作判断框架](../reference/writing/writing_judgment_framework.md) — 写作质量多维评估
- ARS: [摘要写作指南](../reference/writing/abstract_writing_guide.md) — 双语摘要撰写规范
- ARS: [风格校准协议](../reference/writing/style_calibration_protocol.md) — 从历史论文学习作者写作风格
- 模板：[双语摘要](../templates/bilingual_abstract_template.md) / [修改追踪](../templates/revision_tracking_template.md)

---

## find_evidence.sh I/O Contract

> **版本**: v0.3（autonomous-ready）
> **流程**: corpus-first → search-fills-gap → merge & dedup → NDJSON output

### CLI 签名

```bash
bash script/paper/find_evidence.sh "<claim 一句话>" \
    [--topic <搜索主题>] \
    [--limit <最大返回数量>] \
    [--year-from <起始年份>] \
    [--output <输出文件路径>]
```

### 参数说明

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| 位置参数 | string | 是 | — | claim 文本，用于报告 |
| `--topic` | string | 否 | = claim | 实际搜索关键词 |
| `--limit` | int | 否 | 5 | 最多返回证据数量 |
| `--year-from` | int | 否 | — | 起始年份过滤（传递给 S2 搜索） |
| `--output` | path | 否 | stdout | 输出文件路径 |

### 执行流程

```
输入 claim
    ↓
Step A. 检索 relate-work/ 本地语料库
    ↓
   ├─ 本地匹配数 >= limit → 输出本地结果，不调 S2
   │
   └─ 本地匹配数 < limit → Step B. 调用 paper_search.sh 补充
                              ↓
                             ├─ S2 成功 → 合并 + 去重 → 输出
                             │
                             └─ S2 失败 → 仅返回本地结果，stderr 记录 [S2-API-UNAVAILABLE]
```

### 匹配规则（本地语料库）

- **文件名匹配**: 在 relate-work/ 的文件名中 case-insensitive grep topic
- **内容匹配**: 在文件内容中 case-insensitive grep topic
- **JSON 文件** (`search-*.json`): 逐条提取匹配的论文条目（title/abstract/venue 中包含 topic）
- **Markdown 文件** (`note-*.md`, `ref-*.md`, `search-*.md`): 匹配整文件，提取 metadata
- **score 分配**: 文件名匹配 = 0.6，内容匹配 = 0.3
- **README.md 被排除**（仅为目录说明，非证据文件）

### 输出 Schema（NDJSON，每行一个 JSON 对象）

```json
{
  "source": "local" | "s2",
  "title": "论文标题",
  "authors": ["作者1", "作者2"],
  "year": 2024,
  "doi": "10.xxxx/xxxxx",
  "match_score": 0.5,
  "path_or_url": "relate-work/search-example.json 或 https://..."
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `source` | string | `"local"`（来自 relate-work/）或 `"s2"`（来自 Semantic Scholar API） |
| `title` | string | 论文标题 |
| `authors` | array | 作者列表（最多 5 个） |
| `year` | int \| null | 发表年份 |
| `doi` | string \| null | DOI 标识符 |
| `match_score` | float | 匹配分数：local 文件名 0.6 / local 内容 0.3 / s2 默认 0.5 |
| `path_or_url` | string | 本地文件相对路径或 S2 URL |

### Exit Codes

| 退出码 | 含义 | 输出 |
|--------|------|------|
| `0` | 成功找到证据 | stdout: NDJSON 结果 |
| `2` | 任何地方都未找到证据 | stderr: 结构化错误 JSON |
| `3` | S2 不可用但本地有结果 | stderr: `[S2-API-UNAVAILABLE]`，stdout: 本地 NDJSON |

### 4 IRON RULES

> 1. **同标准（Same Standard）**: 本地 corpus 和远程 S2 使用相同的检索标准。当本地有结果时，不得隐式放宽搜索条件。
> 2. **不静默跳过（No Silent Skip）**: 如果任何地方都找不到证据，必须以 exit code 2 退出并输出结构化错误 JSON，绝不得 exit 0 + 空结果。
> 3. **不变更数据（No Mutation）**: 绝不修改 relate-work/ 目录中的任何文件（只读访问）。
> 4. **优雅降级（Graceful Degradation）**: 如果 S2 API 失败（网络、限速、5xx），降级为仅本地搜索并在 stderr 记录 `[S2-API-UNAVAILABLE]`，绝不使整个管线崩溃。

### 示例

```bash
# 基础用法：搜索 claim 的支撑证据
bash script/paper/find_evidence.sh "ViT outperforms ResNet-50 on ImageNet"

# 指定搜索主题和数量限制
bash script/paper/find_evidence.sh "LLMs produce hallucinated citations" \
    --topic "large language model hallucination" --limit 3

# 加年份过滤，输出到文件
bash script/paper/find_evidence.sh "sparse attention reduces complexity" \
    --year-from 2020 --output relate-work/evidence-sparse-attn.ndjson

# 完整参数
bash script/paper/find_evidence.sh "claim text" \
    --topic "search query" --limit 5 --year-from 2022 --output results.ndjson
```

### 失败场景行为

| 场景 | 行为 | Exit Code |
|------|------|-----------|
| 本地 0 匹配 + S2 成功 | 输出 S2 结果 | 0 |
| 本地 0 匹配 + S2 失败 | 结构化错误 JSON → stderr | 2 |
| 本地 N 匹配 + S2 成功 | 合并去重后输出 | 0 |
| 本地 N 匹配 + S2 失败 | 仅输出本地结果 + [S2-API-UNAVAILABLE] | 0 |
| 本地 0 匹配 + 无 S2 调用（已足够） | 结构化错误 JSON → stderr | 2 |

## Passport I/O

- **Reads**: `outline` (chapter-by-chapter writing targets), `bibliography[]` (cite keys for in-text citations), `argument_audit[]` (M5 claim positions to embed in prose), `corpus[]` (evidence files for the anti-leakage protocol)
- **Writes**: `material_gaps[]` (each `[MATERIAL GAP: ...]` marker inserted when evidence is missing), `current_stage` → `m6`
- **Stage transition**: advances passport to `current_stage = m6` (draft prose is written with all claims either evidence-backed or explicitly marked as material gaps)
