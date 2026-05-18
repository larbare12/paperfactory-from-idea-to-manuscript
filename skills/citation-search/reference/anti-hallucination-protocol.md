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
