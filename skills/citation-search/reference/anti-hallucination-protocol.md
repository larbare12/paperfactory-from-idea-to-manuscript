---
name: anti-hallucination-protocol
description: |
  引用真实性三层验证机制 + 红线清单 + 实战陷阱(abstract-only cite、
  BibTeX parser 假阳性)。M2 文献入库、M5 论证引用、M6 写作时新增 \cite、
  M7 总检审计前必读。这是 paper-assistant 最严重的红线协议——违反会直接
  导致论文撤稿风险。
applies_to: [m2, m5, m6, m7]
related:
  - literature-research-protocol.md
  - venue-quality-protocol.md
---

# 反幻觉硬约束(Anti-Hallucination Protocol)

> **论文检索(M1/M2)完成后,所有引用必须经过真实性验证才能进入 M6 写作。这是最严重的红线,违反将导致论文撤稿风险。**

---

## 三层验证机制

### Layer 1:来源验证(每篇文献入库时)

- 任何文献从外部进入 `relate-work/` 之前,必须有可验证的来源标识:**DOI / arXiv ID / Semantic Scholar paperId 至少一个**
- 没有标识符的"凭印象引用" → 直接丢弃,不允许"先写上再说"
- 检索结果必须通过 `skills/citation-search/scripts/paper_search.sh` 或同等脚本获得,**禁止 Agent 自行"回忆"论文标题、作者、年份**

### Layer 2:引用验证(写作阶段,每次新增 \cite 时)

- 草稿中每个 `\cite{key}` 或 `[@key]` 必须在 `references.bib` 中有完整条目
- 进入 M7 前必须运行:
  ```bash
  bash skills/citation-search/scripts/verify_citations.sh relate-work/draft.tex --bib relate-work/references.bib
  ```
- 报告会按"五类幻觉分类"(虚构标题、错配作者、年份偏差、虚假 venue、不存在 DOI)输出
- **任何 Tier 0(高风险)幻觉未消除 → 禁止进入 M7**

### Layer 3:内容一致性(论证阶段)

- 引用论文的核心论点、数值、结论,Agent 不得复述记忆,必须从 `relate-work/manifest.jsonl` 中 status=`downloaded`/`user-supplied` 的论文全文里摘录(以 manifest 为唯一权威清单)
- 若 manifest 中该 bibkey 的 status=`missing` 或 `pending`(PDF 尚未到位)→ 标记 `[NEEDS-EVIDENCE]` 并在 M6 检查中回填
- 见 M6 写作辅助的 "MATERIAL GAP IRON RULE"(`../../m6-writing/SKILL.md` after Step 6 migration)

---

## 红线清单(任何一条触发立即 STOP)

- 🚫 用模型记忆引用 2024 年之后的论文(知识截止前后的论文都不可信)
- 🚫 凭"似乎读过"补全 BibTeX 字段(作者、期刊、卷号、页码)
- 🚫 把 arXiv 预印本当作正式期刊版本引用(见 [venue-quality-protocol.md](venue-quality-protocol.md))
- 🚫 跳过 `verify_citations.sh` 直接进入 M7

> Agent 在 **M2 结束、M6 进入前、M7 进入前** 三个时点,必须主动运行 `verify_citations.sh` 并把报告路径告诉用户。

---

## 实战陷阱

### 🚫 Abstract-only cite 反模式(最严重的隐性幻觉源)

检索结果中的 abstract 通常只够支撑**框架性提及**("... such as \cite{X}"),**绝不够**支撑 paraphrase 类陈述("X 论文做了 Y / 复现了 Z / 验证了 W")。abstract 会让你**无法分辨**:

- 论文用的是 LLM agent 还是 transformer foundation model(例:MarS 不是 LLM agent,是 order-level generative foundation model)
- 论文是否真的复现了你想引用的现象(例:SimFin abstract 说 "consistent with preliminary findings" 而不是 "reproduce price bubbles")
- 论文研究的对象是什么(例:InvestAlign 研究 SFT 数据生成,不研究 willingness 系数)

**硬约束**:只要你打算 paraphrase "论文 X 做了什么/发现了什么/复现了什么",**必须**:

1. `relate-work/pdf/<bibkey>.pdf` 已存在
2. `manifest.jsonl` 中该 bibkey `status ∈ {downloaded, user-supplied}`
3. 你**亲自**精读了相关章节(method/experiments/results),不是只看 abstract

如果以上任何一条不满足,必须先用 `[NEEDS-EVIDENCE]` 占位,**严禁直接 cite**。

**OA 优先策略**:Stage 3 的 `collect_papers.sh` 会自动尝试 arXiv → OpenAlex → S2 OA 下载,OA 命中率通常 60–90%。**对 OA 论文(status=downloaded),Agent 必须立即精读再 cite**——能下载没读、然后只看 abstract 写引用是双重失误。对闭源论文(status=missing),按 Stage 4 流程引导用户从机构订阅手动补全,**未补全前严禁 paraphrase**。

### ⚠️ verify_citations.sh 的 BibTeX parser 已知缺陷

**嵌套 `{...}` 大写保护会截断 title。**

例如 `title = {{OASIS}: Open Agent Social ...}` 会被解析为 `{OASIS`,与 S2 真实 title 的 fuzzy match 失败,归类为 `DOI_MISMATCH / PAC`,但 DOI 实际能 resolve("DOI resolves but title mismatch")——这是**假阳性**,不是反幻觉失败。

**判读规则**:报告显示 `DOI resolves` + `match_score < 0.7` + 该条目 .bib title 含嵌套 `{...}` 时,按照 known issue 处理;可临时建一份去掉大括号保护的 minimal .bib 重跑一次确认。修复 parser 是 paper-assistant 的待办(issue 待提)。

---

## 引用幻觉 5 类分类法

> 源自 PaperOrchestra (Song et al., 2026) 的引用审计经验。autonomous 模式下 LLM 端到端生成引用时,必须对这 5 类做编程防御。Tier 0(`verify_citations.sh`)能捕获前 4 类的相当部分,第 5 类(SH)需 Tier 2+ 全文核验。

| 缩写 | 中文 | 定义 | Tier 0 能否捕获 |
|---|---|---|---|
| **TF** | Total Fabrication 完全捏造 | 标题/作者/venue/DOI 全部虚构,论文根本不存在 | ✅ S2 search 返回 0 条 Lev ≥ 0.70 → `S2_NOT_FOUND` |
| **PAC** | Partial Author Confusion 作者错配 | 论文真实,但作者归属错(同名学者 / 不同领域) | ⚠️ DOI 解析得到但 Levenshtein < 0.70 → `DOI_MISMATCH`,标记为 PAC 疑似 |
| **IH** | Imaginary Hosting 虚假 venue | 论文存在,但 venue(会议/期刊)是编造的——如把 arXiv 预印本说成发表在 "NeurIPS 2024" | ❌ 目前 venue 比对未自动化(TODO),需人工对照 S2 返回的 venue 字段 |
| **PH** | Partial Homonym 同名作者错引 | "Wei Wang" 类 namespace 冲突——LLM 引用了错误的同名学者的论文 | ❌ S2 返回 authorId 可比对,但白名单未实现(TODO) |
| **SH** | Secondhand 二手引用错传 | A 引用了 B,LLM 把 B 的结论错误归给 A;或读了 A 的 abstract 把别人的话当成 A 自己说的 | 🚫 **Tier 0 无能为力**——论文真、metadata 真、就是内容归属错。需 M6 `[NEEDS-EVIDENCE]` + `find_evidence.sh` Tier 2+ 全文核验 |

**与"abstract-only cite 反模式"的关系**:SH 类幻觉的最常见成因就是 abstract-only cite——LLM 读了摘要,把摘要里"引述其他工作"的内容当成本论文的结论。这就是为什么"只看 abstract 写 paraphrase"被列为最严重的隐性幻觉源。

---

## Tier 0 校验协议(verify mode 实现细节)

### 触发时点

- **强制**:M6 终稿生成后必须运行 `verify_citations.sh`
- **门控**:Tier 0 报告中除 `S2_UNAVAILABLE` 外 0 条失败,才允许进入 M7
- **审计**:NDJSON verdict 写入 `relate-work/citation_verification_report_<timestamp>.md`

### 三层兜底架构(当前仅 Tier 0 自动化)

```
Tier 0 (编程校验):  S2 /paper/search + DOI 反查
                      └── PASS                   → 通过
                      └── S2_NOT_FOUND           → 降级 Tier 1
                      └── S2_UNAVAILABLE         → 降级 Tier 1
                      └── DOI_MISMATCH (Lev<0.7) → 标 PAC 疑似,人工复核
Tier 1 (手工 fallback): doi.org 直接解析
                      └── 200  → 记录元数据
                      └── 404  → 降级 Tier 2
Tier 2 (手工 fallback): WebSearch 抽样 Google/Bing
                      └── 仍无 → 标 TF 疑似
```

### Levenshtein 阈值 0.70 的来源

源自 PaperOrchestra (Song et al., 2026) 附录 D.3 的 Citation Verification 实验。在 68 条真实发表的引用上验证,该阈值能有效区分真引用与 TF/PAC 类幻觉。本 plugin 直接沿用。

### 实现位置

- 引擎:`skills/citation-search/scripts/paper_search.sh --mode verify`
- 批扫:`skills/citation-search/scripts/verify_citations.sh`(扫 .tex 提取 `\cite{...}` → 批量校验 → 出报告)
- 全文级 SH 防御:`skills/citation-search/scripts/find_evidence.sh`(M5 论证用)

### 已知限制

| 限制 | 缓解方式 |
|---|---|
| SH 类幻觉无法自动检测 | M6 `[NEEDS-EVIDENCE]` + `find_evidence.sh` |
| Venue 模糊比对未自动化 | TODO,verify mode 后续加入 |
| 同名作者(PH)消歧未自动化 | TODO,加入领域作者白名单 |
| 中文/灰色文献可能不在 S2 | `S2_NOT_FOUND` 不直接判定为幻觉,降级 Tier 1+2 人工 |
| BibTeX parser 嵌套大括号 bug | 见上节 known issue,临时去括号重跑 |
