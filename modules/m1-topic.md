# M1 选题诊断模块

> **理论基础**：
> - 参见 [PAPER-WRITING-GUIDE.md](../reference/PAPER-WRITING-GUIDE.md) 第7.1节（论文大纲生成 Prompt）
> - 基于 [Relic 论文](https://arxiv.org/abs/2604.16116) 八层提取法思想

## 功能
评估研究 idea 的可行性、创新性、与领域契合度。
**本模块是数据驱动的**：诊断必须建立在实际文献证据之上，而不是凭印象。
诊断流程会调用 `script/paper/paper_search.sh --mode bulk` 大批量拉取相关论文，
并把结果落到 `relate-work/`，供后续 M2 文献管理 / M5 论证设计 / M6 写作辅助消费。

> **流程位置**：**M1（本模块）** → M2 文献 → M3 实验 → M4 结构 → M5 论证 → M6 写作 → M7 总检
> M0 项目仪表盘是横切的常驻模块，任何阶段都可以调。

## 输入
- 研究 idea（一句话描述）
- 初步文献（可选，3-5篇关键文献）
- 目标期刊/会议（可选）
- 领域背景（可选）

## 输出
- 可行性评估（高/中/低）及理由
- 创新点提炼（3-5个 bullet points）
- 与领域热点契合度分析
- 潜在风险点识别
- 建议调整方向
- 下一步行动建议

## 使用场景
1. 有初步想法，不确定是否值得深入
2. 多个选题方向，需要筛选优先级
3. 导师要求评估选题可行性
4. 投稿前最后检查选题定位

## 诊断流程（基于八层提取法思想）

### Layer 0: 文献基线建立（先做，**所有后续判断的依据**）

在做任何主观判断之前，先拉一批与 idea 相关的论文作为诊断基线：

```bash
# 大批量拉相关论文（bulk 端点支持年份过滤、limit 上限大）
bash script/paper/paper_search.sh "<idea 关键词组合>" \
     --mode bulk --year "2020-" --limit 50 \
     > relate-work/search-<idea-slug>-$(date +%Y%m%d).json
```

落盘后这批论文成为：
- 本模块 Layer 3 / Layer 5 / Layer 6 的**证据来源**
- 后续 M2 文献分类、M5 论证设计、M6 写作时的**本地检索池**（不要丢）

如果 S2 触发 429，切换到 `--mode crossref` 重试。

### Layer 1: Idea 捕获
提取用户输入的核心研究问题

### Layer 2: 问题类型识别
判断是：新问题/新方法/新应用/理论拓展/实证补充

### Layer 3: 创新性评估（**用 Layer 0 的搜索结果背书**）
基于 `relate-work/search-*.json` 回答：
- 与已发表工作的差异化程度——有几篇高度近似？分别差在哪个维度？
- 理论贡献潜力——已有方法是否已经覆盖了你的核心机制？
- 实践价值——同方向论文的引用量趋势（涨/平/跌）说明热度走势

### Layer 4: 可行性检查
- 数据/资源可获取性（看相关论文用的数据集是否公开）
- 技术难度（看 SOTA 方法的复杂度与本组能力差距）
- 时间成本

### Layer 5: 领域契合度（**用 Layer 0 的 venue 分布背书**）
- 用 `script/paper/venue_lookup.sh` 查 Layer 0 中高频出现的 venue 的 CCF/IF
- 这些 venue 是否覆盖了你的目标投稿目的地
- 当前领域热点关键词出现频次

### Layer 6: 风险识别（**用 Layer 0 找竞争工作**）
- 潜在技术障碍
- 竞争工作风险——明确指出 relate-work/ 中**最相似的 3 篇**论文，标注 idea 与它们的差异
- 伦理/法律问题

### Layer 7: 综合评估
生成可行性评级和优先级建议

### Layer 8: 行动建议
输出具体下一步行动清单，并明确告知用户：
- relate-work/ 中已沉淀了哪些论文，将作为 M2 文献分类、M5 论证设计、M6 写作的本地检索池
- 是否需要补充某类文献（基础/方法/对比/相关）→ 直接进入 M2

## 示例 Prompt

```
请帮我诊断以下研究选题：

研究 idea：[填入]
目标期刊/会议：[填入]
相关文献：[填入]

请按以下结构输出诊断报告：
1. 可行性评估（高/中/低）
2. 核心创新点（3-5个）
3. 与领域契合度分析
4. 潜在风险点
5. 建议调整方向
6. 下一步行动建议
```

## 诊断标准

### 可行性评级
- **高**：资源充足、技术成熟、6个月内可完成
- **中**：需要一定探索、可能遇到技术障碍、6-12个月
- **低**：资源难以获取、技术挑战大、时间成本过高

### 创新性评级
- **高**：开辟新方向、解决长期难题、理论突破
- **中**：显著改进现有方法、新应用场景、较重要实证
- **低**：增量改进、已有类似工作、应用价值有限

## 参考资源
- 参见 [PAPER-WRITING-GUIDE.md](../reference/PAPER-WRITING-GUIDE.md) 第7.1节
- 搜索脚本：[`script/paper/paper_search.sh`](../script/paper/paper_search.sh)（bulk/standard/crossref 三模式）
- 期刊查询：[`script/paper/venue_lookup.sh`](../script/paper/venue_lookup.sh)（CCF + IF）
- 本地论文池：[`relate-work/`](../relate-work/)（M1 写入、M3/M6 读取）
- ARS: [Socratic 提问框架](../reference/research/socratic_questioning_framework.md) — idea 澄清与收敛
- ARS: [跨学科桥梁](../reference/research/interdisciplinary_bridges.md) — 交叉领域创新性评估
- ARS: [伦理检查清单](../reference/compliance/ethics_checklist.md) — 早期伦理风险筛查
- ARS: [各领域顶级期刊](../reference/review/top_journals_by_field.md) — 投稿目标选择参考
- ARS: [文献来源质量层级](../reference/research/source_quality_hierarchy.md) — 文献质量评估框架

## Passport I/O

- **Reads**: `research_question` (the idea to diagnose), `corpus[]` (existing evidence files, if any)
- **Writes**: `research_question` (refined and scoped after diagnosis), `methodology.description`, `methodology.data_source`, `current_stage` → `m1`, `corpus[]` (new search result paths like `relate-work/search-<slug>-*.json`)
- **Stage transition**: advances passport to `current_stage = m1` (entry point of the pipeline; bootstrap from an initial idea to a diagnosed research question)
