# M6 写作辅助模块

## 功能
段落生成、语言润色、逻辑连贯性检查

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
- 参见 refence/PAPER-WRITING-GUIDE.md 第2部分
- 参见 refence/ACADEMIC-WRITING-GUIDE.md
