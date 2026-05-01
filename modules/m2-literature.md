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
- ARS: [文献来源质量层级](../reference/ars/deep-research/source_quality_hierarchy.md) — 引用质量评估体系
- ARS: [系统综述工具包](../reference/ars/deep-research/systematic_review_toolkit.md) — PRISMA 2020 系统综述方法
- ARS: [文献监控策略](../reference/ars/deep-research/literature_monitoring_strategies.md) — 持续文献追踪
- ARS: [引用格式切换器](../reference/ars/paper/citation_format_switcher.md) — 多格式引文转换
- ARS: [Claim 验证协议](../reference/ars/pipeline/claim_verification_protocol.md) — 文献 claim 交叉验证

---

## 引用幻觉 5 类分类法（autonomous 模式必备）

> 以下分类法源自 PaperOrchestra (Song et al., 2026) 的引用审计经验，经 ARS 项目整理为 `deep-research/references/semantic_scholar_api_protocol.md` 中的校验协议。autonomous 模式下 AI 端到端生成引用，必须对这 5 类幻觉进行编程防御。

### TF — Total Fabrication（完全捏造）

**定义**：论文完全不存在——标题、作者、venue、DOI 全部为模型 parametric memory 生成的虚构内容。

**危险原因**：autonomous 模式没有人类在每阶段审查，LLM 的 parametric memory 会"自信地"捏造一篇标题合理、作者可信、venue 存在的论文。终稿审阅者逐条 Google 核实成本极高，通常只会抽样。

**Tier 0 捕获方式**：S2 `/paper/search` 对标题搜索返回 0 条 Levenshtein >= 0.70 的结果 -> `S2_NOT_FOUND`。如果 DOI 也同时捏造，DOI lookup 返回 404 -> 同样 `S2_NOT_FOUND`。Tier 0 对此类最有效。

### PAC — Partial Author Confusion（部分作者错）

**定义**：论文确实存在，但作者列表被篡改——真实的领域知名学者被错误地归功到这篇论文上（或真实作者被替换为同名但不同领域的学者）。

**危险原因**：审稿人会注意到作者归属错误，直接质疑研究可信度。且作者列表错误常伴随着引用内容（结论、数据）的连带错误。

**Tier 0 捕获方式**：DOI lookup 能解析到论文但标题相似度仍可 >= 0.70（论文是真的），但作者列表不同。当前 Tier 0 暂未做作者比对，需在后续版本中加入 author 字段 diff。**DOI 错配时标记为 DOI_MISMATCH -> 归类为 PAC 疑似**。

### IH — Imaginary Hosting（不存在的会议/期刊）

**定义**：论文标题和作者可能是真实的（或接近真实），但发表的 venue（会议/期刊名）是编造的。例如把一篇 arXiv 预印本说成发表在 "NeurIPS 2024"。

**危险原因**：venue 是审稿人最快速判断论文质量的信号之一。伪造 venue 等同于伪造引用影响力，是学术不端的直接证据。

**Tier 0 捕获方式**：S2 API 返回真实 venue 字段。可比较 input venue 与 S2 venue（需模糊匹配，因为缩写形式不同）。**当前 Tier 0 未自动化 venue 比对**，S2_ID 解析后返回的 venue 可供后续人工或自动化比对。TODO: 在 verify mode 中加入 venue 相似度检查。

### PH — Partial Homonym（同名作者错配）

**定义**：作者名对，但其实是另一个研究方向的同名学者。例如 "Wei Wang" 在 S2 上可能有数百条记录，LLM 引用了错误的 "Wei Wang" 的论文。

**危险原因**：作者 ID 和 author page 在 S2 上可验证，但仅凭标题和 DOI 无法区分。审稿人若点进作者主页会发现研究方向完全不匹配。

**Tier 0 捕获方式**：S2 API 返回作者 ID（authorId）。可通过比对 authorId 与领域专家列表来识别。**当前 Tier 0 未自动化 author ID 比对**，但返回结果中已包含 authorId 字段。TODO: 加入领域作者白名单比对。

### SH — Secondhand（二手引用错传）

**定义**：论文 A 引用了论文 B，但 LLM 把 B 的内容/结论错误地归给了 A，或者 A 实际上并没有说过那句话——LLM 读了 A 的摘要，把 A 引用 B 的内容当成了 A 自己的结论。

**危险原因**：这是最隐蔽的幻觉类型。论文确实存在，DOI 能解析，标题匹配，S2 全部通过。但引用内容是错的——你引用的那篇论文根本没有说过那句话。

**Tier 0 捕获方式**：**Tier 0 无法捕获 SH 类幻觉**。因为论文本身是真的，所有 metadata 都匹配。防御 SH 需要读取论文全文并验证具体 claim，属于 Tier 2+ 范围。TODO: 在 M6 写作阶段加入 `[NEEDS-EVIDENCE]` 标记，对关键 claim 做全文级验证（见 `find_evidence.sh`）。

---

## Tier 0 引用校验协议

> 本协议借鉴自 ARS 项目 `deep-research/references/semantic_scholar_api_protocol.md`（v3.3），为 paper.skill autonomous 模式下的引用验证基线。

### 校验时机

- **强制**：M6 终稿生成后必须运行 `verify_citations.sh`
- **门控**：Tier 0 返回 0 条失败（除 `S2_UNAVAILABLE` 外）才允许进入 M7 总检
- **审计**：所有 NDJSON verdict 写入 `relate-work/citation_verification_report_<timestamp>.md`，供终稿审阅

### 三层兜底架构

```
Tier 0（编程校验）: S2 API --> 每条引用 100% 覆盖
                      |
                      +-- PASS --> 跳过后续层级
                      +-- S2_NOT_FOUND --> 降级到 Tier 1
                      +-- S2_UNAVAILABLE --> 降级到 Tier 1
                            |
Tier 1（手工 fallback）: DOI 解析 --> doi.org 直接解析
                            |
                            +-- 200 --> 记录元数据
                            +-- 404 --> 降级到 Tier 2
                                  |
Tier 2（手工 fallback）: WebSearch 抽样 --> Google/Bing 搜索标题
                            |
                            +-- 仍无结果 --> 标记为 [TF 疑似]
```

**当前状态**：仅实现 Tier 0（`paper_search.sh --mode verify`）。Tier 1（DOI 解析）和 Tier 2（WebSearch）是手工 fallback，尚未自动化。autonomous 模式下建议后续补全。

### Levenshtein 阈值来源

- 阈值 **0.70** 源自 PaperOrchestra (Song et al., 2026) 附录 D.3 的 Citation Verification 实验
- 论文中采用两阶段 pipeline（broad discovery + sequential verification），Semantic Scholar API 阶段的标题匹配阈值为 0.70
- ARS 直接沿用此阈值，经验证在 68 条真实发表的引用上能有效区分真引用和幻觉

### 实现位置

- `script/paper/paper_search.sh --mode verify`：S2 Tier 0 核心引擎
- `script/paper/verify_citations.sh`：扫描草稿 -> 提取引用 -> 批量校验 -> 生成报告
- `modules/m2-literature.md`：本文档（5 类分类法 + 协议说明）

### 已知限制

| 限制 | 说明 | 缓解 |
|------|------|------|
| SH 类幻觉 | Tier 0 无法检测（论文存在但内容错传） | M6 `[NEEDS-EVIDENCE]` + `find_evidence.sh` |
| Venue 比对 | 未自动化 venue 模糊匹配 | TODO: 在 verify mode 加入 |
| Author ID 比对 | 未自动化同名作者消歧 | TODO: 加入领域作者白名单 |
| 非 S2 索引 | 中文/灰色文献可能不在 S2 中 | `S2_NOT_FOUND` 不自动判定为幻觉，需 Tier 1+2 |

## Passport I/O

- **Reads**: `research_question` (guides literature scope), `corpus[]` (M1 search result paths to ingest), `bibliography[]` (existing entries for incremental enrichment)
- **Writes**: `bibliography[]` (populated with verified entries: key/title/authors/year/doi/s2_id/verification_status), `corpus[]` (new ref-*.md card paths), `material_gaps[]` (identified citation gaps that trigger a return to M1), `current_stage` → `m2`
- **Stage transition**: advances passport to `current_stage = m2` (bibliography and corpus are now populated from raw M1 search results)

