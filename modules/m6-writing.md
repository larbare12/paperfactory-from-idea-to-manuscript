# M6 写作辅助模块

> **理论基础**：
> - 参见 [ACADEMIC-WRITING-GUIDE.md](../reference/ACADEMIC-WRITING-GUIDE.md) 全文（数学符号、缩写、格式规范）
> - 参见 [PAPER-WRITING-GUIDE.md](../reference/PAPER-WRITING-GUIDE.md) 第2部分（用词与语言风格）
> - 参见 [PAPER-WRITING-GUIDE.md](../reference/PAPER-WRITING-GUIDE.md) 第6部分（常见错误与避免方法）

> **流程位置**：M1 → M2 → M3 → M4 → M5 → **M6（本模块）** → M7 总检
> 本模块按 [M5 论证设计](m5-argument.md) 产出的论证骨架展开正文，依据 [M4 结构规划](m4-structure.md) 的章节边界控制内容。

## 功能
段落生成、语言润色、逻辑连贯性检查。
**核心约束**：每提出一个 claim，必须先在 `relate-work/` 找到本地证据；找不到才回退到 `find_evidence.sh` 占位（当前未实现，自动标记 `[NEEDS-EVIDENCE]`）。

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
- 占位检索脚本：[`script/paper/find_evidence.sh`](../script/paper/find_evidence.sh)（未实现）
