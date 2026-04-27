# M7 评审模拟模块

> **理论基础**：
> - 参见 [PAPER-WRITING-GUIDE.md](refence/PAPER-WRITING-GUIDE.md) 第3部分（写作流程规范）
> - 基于 [Relic 论文](https://arxiv.org/abs/2604.16116) 专家评估方法

## 功能
模拟审稿人视角、预判问题、修改建议

## 输入
- 完整论文或章节
- 目标期刊/会议
- 投稿类型（全文/短文/摘要）
- 已知审稿意见（可选）

## 输出
- 模拟审稿意见（major/minor concerns）
- 常见问题预判
- 修改优先级排序
- 回复信模板
- 修改建议

## 使用场景
1. 投稿前自我检查
2. 回应审稿意见
3. 改进论文质量
4. 准备 rebuttal

## 审稿人视角检查清单

### 主要关注点（Major Concerns）
- [ ] **新颖性**：是否有新的理论/方法/发现？
- [ ] **正确性**：方法是否有效？实验是否可靠？
- [ ] **完整性**：是否包含必要的实验和分析？
- [ ] **清晰度**：论文是否易于理解？
- [ ] **相关性**：是否适合该期刊/会议？

### 次要关注点（Minor Concerns）
- [ ] 格式规范
- [ ] 语言表达
- [ ] 图表质量
- [ ] 引用完整性
- [ ] 拼写和语法

## 常见问题预判

### 新颖性问题
- "与 XXX 方法的区别是什么？"
- "这个 idea 似乎很直接，创新性在哪里？"
- "为什么之前没有人做？"

### 正确性问题
- "实验设置是否公平？"
- "统计显著性检验在哪里？"
- "能否证明方法的收敛性？"

### 完整性问题
- "为什么没有与 XXX 对比？"
- "消融实验是否充分？"
- "失败案例分析在哪里？"

### 清晰度问题
- "算法描述不够清晰，无法复现"
- "符号定义不明确"
- "图 X 难以理解"

### 相关性问题
- "更适合投 XXX 会议"
- "贡献不够重大，建议投 workshop"

## 模拟审稿流程

### Step 1: 快速浏览
- 读标题、摘要、结论
- 看图表
- 初步判断贡献

### Step 2: 详细阅读
- 逐节阅读，做笔记
- 标记疑问点
- 记录优缺点

### Step 3: 评估
- 评估新颖性、正确性、完整性
- 给出总体评价
- 确定推荐意见

### Step 4: 撰写意见
- 总结主要贡献
- 列出主要问题
- 列出次要问题
- 给出推荐

## 推荐意见类型

### Accept
- 论文质量高，贡献明确
- 只有 minor revisions

### Weak Accept / Minor Revision
- 论文有价值，但需要小修改
- 修改后可接受

### Borderline
- 论文处于边界
- 需要较大修改，可能需重审

### Weak Reject / Major Revision
- 论文有潜力，但需要重大修改
- 修改后可能重投

### Reject
- 论文不符合要求
- 新颖性不足或存在严重问题

## 回复信撰写

### 结构
1. **感谢**：感谢审稿人时间和意见
2. **总体回应**：概述主要修改
3. **逐条回应**：
   - 引用审稿人原话
   - 给出明确回应
   - 说明修改位置
4. **修改列表**：详细列出所有修改

### 回应原则
- 礼貌、专业
- 直接回答问题
- 不辩解，除非确实误解
- 所有意见都要回应

### 回应模板
```
Reviewer Comment: "The comparison with XXX is missing."

Response: We thank the reviewer for this suggestion. 
We have added a comparison with XXX in Section 4.2. 
Specifically, we re-run XXX on our dataset using their 
publicly available code. The results (Table 3) show that 
our method outperforms XXX by 5.2% in terms of accuracy.

Change: Added comparison with XXX in Section 4.2, 
