# M2 文献管理模块

> **理论基础**：
> - 参见 [ACADEMIC-WRITING-GUIDE.md](../reference/ACADEMIC-WRITING-GUIDE.md) 第三部分（参考文献格式规范）
> - 参见 [PAPER-WRITING-GUIDE.md](../reference/PAPER-WRITING-GUIDE.md) 第5部分（引用与参考文献）
> - 基于 [Relic 论文](https://arxiv.org/abs/2604.16116) 引用逻辑分析思想

## 功能
引用网络分析、关键文献识别、格式规范。
本模块的工作产物（分类结果、bib key、笔记卡）写入 [`relate-work/`](../relate-work/) 供 M3/M5/M6 复用。

> **流程位置**：M1 选题诊断 → **M2 文献管理（本模块）** → M3 实验设计 → M4 结构 → M5 论证 → M6 写作 → M7 总检
>
> M1 已经用 `paper_search.sh --mode bulk` 把候选论文落到 `relate-work/`，本模块在此基础上做精读、分类、bib key 整理。

## 输入
- M1 沉淀的 `relate-work/search-*.json`
- 引用格式要求（IEEE/ACM/APA 等）
- 目标期刊/会议
- 领域关键词（可选）

## 输出
- 引用网络分析
- 关键文献分类（基础/方法/对比/相关）→ 写到 `relate-work/ref-<bibkey>.md`
- 引用密度检查
- 格式自动校正
- 缺失文献建议（触发回到 M1 补一轮 bulk 检索）

## 使用场景
1. 文献综述写作
2. 投稿前引用格式统一
3. 识别关键文献缺口
4. 转投不同期刊格式转换

## 文献管理流程

### Step 1: 文献采集
读取 `relate-work/search-*.json`，必要时再补一次 `paper_search.sh`

### Step 2: 引用网络构建
分析文献间的引用关系，识别核心节点

### Step 3: 关键文献分类
- **基础文献**：领域奠基性工作
- **方法文献**：直接相关的方法论文
- **对比文献**：需要对比的 baseline（→ M3 实验对照组直接消费）
- **相关文献**：拓展阅读、边缘相关

每篇精读论文写一张卡 `relate-work/ref-<bibkey>.md`。

### Step 4: 引用密度分析
检查引用分布是否均衡（M6 写作时会回查）

### Step 5: 格式规范化
- DOI → BibTeX：`bash script/paper/doi2bibtex.sh "10.1038/..."`
- 期刊质量：`bash script/paper/venue_lookup.sh "Nature Medicine"`
- 作者 H-index：`bash script/paper/author_info.sh "<author_id>"`

### Step 6: 缺失识别
识别关键文献缺口，触发新一轮 M1 bulk 检索

### Step 7: 引用逻辑优化
确保引用支撑论证逻辑（与 M5 论证设计联动）

### Step 8: 最终检查
生成引用完整性报告（M0 仪表盘消费此报告）

## 关键文献分类标准

### 基础文献（Foundational）
- 领域开创性工作
- 被广泛引用的经典论文
- 理论基础来源
- 通常引用次数 > 1000

### 方法文献（Methodological）
- 直接相关的方法论文
- 本文方法的基础或扩展
- 需要详细讨论的工作
- 通常引用次数 100-1000

### 对比文献（Comparative）
- 作为 baseline 的方法
- 需要实验对比的工作（**M3 实验设计的直接输入**）
- 性能相近的竞争方法
- 通常引用次数 50-500

### 相关文献（Related）
- 边缘相关的拓展工作
- 应用场景类似但方法不同
- 一句话提及即可
- 引用次数不限

## 引用密度检查

### 密度标准
- Introduction：每段 2-3 个引用
- Related Work：密集引用，建立领域地图
- Method：关键方法引用，避免过度
- Experiments：baseline 方法必须引用
- Discussion：理论支撑引用

### 分布检查
- 避免连续多段无引用
- 避免单段引用过多（>5个）
- 确保关键 claim 有引用支撑（与 M5/M6 的 `[NEEDS-EVIDENCE]` 流程一致）

## 格式规范

### IEEE 格式
```
[1] C. Chang and J. Tabaczynski, ``Application of state estimation to target tracking,'' \emph{IEEE Trans. Autom. Control}, vol. 29, no. 2, pp. 98--109, 1984.
```

### 格式检查清单
- [ ] 作者姓名格式统一
- [ ] 标题大小写符合规范
- [ ] 期刊名称斜体
- [ ] 卷号、期号、页码完整
- [ ] 年份准确
- [ ] DOI（如要求）

## 示例 Prompt

```
请帮我管理以下文献：

文献列表：[粘贴 BibTeX 或指向 relate-work/search-*.json]
目标期刊：[填入]
领域关键词：[填入]

请输出：
1. 引用网络分析（核心节点识别）
2. 文献分类建议（基础/方法/对比/相关）
3. 引用密度检查
4. 格式校正建议
5. 缺失文献建议
```

## 引用质量评估

### 高质量引用特征
- 直接支撑核心 claim
- 来自顶级期刊/会议（用 `venue_lookup.sh` 验证）
- 近5年工作（除经典文献）
- 作者亲自阅读过

### 避免的问题
- 过度自引（>20%）
- 引用二手文献
- 引用未阅读文献
- 无关引用堆砌

## 参考资源
- 参见 [ACADEMIC-WRITING-GUIDE.md](../reference/ACADEMIC-WRITING-GUIDE.md) 第三部分
- DOI → BibTeX：[`script/paper/doi2bibtex.sh`](../script/paper/doi2bibtex.sh)
- 期刊质量：[`script/paper/venue_lookup.sh`](../script/paper/venue_lookup.sh)
- 作者 H-index：[`script/paper/author_info.sh`](../script/paper/author_info.sh)
- 文献仓库：[`relate-work/`](../relate-work/)
