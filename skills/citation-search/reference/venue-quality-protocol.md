---
name: venue-quality-protocol
description: |
  Venue 质量评估三把尺(同行评审 vs 预印本、顶会 vs 水会、IF/CCF ranking)
  + 方法论 baseline 引用的 venue 硬约束 + 真实事故复盘。M1 选题、M2 文献
  筛选、M5 论证设计、M7 总检 venue audit、M8 同行评审仿真时必读。
applies_to: [m1, m2, m5, m7, m8]
related:
  - literature-research-protocol.md
  - anti-hallucination-protocol.md
---

# Venue Quality 协议

> **反幻觉验证只能保证引用的论文存在;它不保证引用的论文学术力度足够支撑你想做的论证。**
>
> Agent 在筛选阶段(Stage 2)必须用 venue quality 作为第二把尺,特别是当引用要被用作"方法论 baseline"或"公式来源"时。

---

## 三把尺(常见误区)

### 🚫 预印本 / 工作论文当期刊用

`NBER Working Paper` / `arXiv` / `SSRN` / `RePEc WP` 都**不是同行评审期刊**,它们是 preprint。

- **NBER** 是 National Bureau of Economic Research(机构名),它发布的 WP series 没有同行评审。许多 NBER WP 后续会发到 JF / RFS / AER 等顶刊,但**也有永远停在 WP 阶段的**
- 如果一篇文章的 venue 字段是 `National Bureau of Economic Research Working Paper Series` 或 `arXiv` → 标记为预印本,并查 DOI / Semantic Scholar 看是否有期刊版本

### 🚫 会议 proceedings ≠ 顶会

`Other Conferences` / `Online World Conference on...` / 大量水会的 proceedings 都不是 top venue,不能用作核心方法依据。

**Top AI/ML 会议白名单**:
- AAAI / NeurIPS / ICML / ICLR / KDD / WWW
- ACL / EMNLP / SIGIR
- CVPR / ICCV / ECCV

### 🚫 同主题选最低 IF 的

检索返回多篇同主题论文时**不要按 citation 排序选第一篇**——查 venue。

**领域顶刊清单**:

| 领域 | 顶刊白名单 |
|---|---|
| OM / Production | FT50(M&SOM, Operations Research, Management Science, J. Operations Management, Production and Operations Management) + IJPR, IJPE, Annals of OR, Computers & Industrial Engineering |
| Finance | FT50(JF / RFS / JFE / Journal of Financial and Quantitative Analysis) |

CCF 中国计算机学会分级 + JCR 影响因子查询通过 `skills/citation-search/scripts/venue_lookup.sh`,数据库在 `skills/citation-search/data/{ccf_2026.sqlite, impact_factor.sqlite3}`。

---

## 硬约束:方法论 baseline 引用

**当一篇文章被作为"我们要采用的方法 / 公式 / 范式来源"时(不只是背景文献),Agent 必须报告 venue quality**:

1. 是否同行评审正式发表(不是 working paper / preprint)
2. 期刊在所属领域的 ranking(FT50? JCR Q1? 顶刊白名单内?)
3. 如果有同主题更顶刊的替代论文,先列出来让用户选

### 判读规则

venue 字段含 `Working Paper` / `arXiv` / `SSRN` / `preprint` / `WP` → preprint,方法论引用力弱。

**论文里只能用 `concurrent work` 或 `see also` 弱引用,不能作为核心方法 baseline。**

例外条件(至少满足一条):
1. 该论文已被引用 50+ 次且未发表说明顶刊拒稿不是质量问题
2. 找不到等价的已发表替代品

---

## 真实事故复盘

### 2026-05-08:NBER WP 当 baseline 事故

**事件**:我把 Lu et al. 2021 (NBER WP w29166) 当作"价格弹性公式 baseline"放进 SHOCK_FORMULA_PROPOSAL,作为论文核心方法依据。

**用户复审挑出**:"NBER 不是期刊"。

**后果**:整个 Layer B 推倒重写——最终改用 Zhu et al. 2023 IJPR(IF≈9 OM 顶刊)的 piecewise demand profile 替代。

**代价**:返工一个 layer 的设计。

**教训**:venue 字段必须在 Stage 2 筛选时就过滤,不要等 M5 论证阶段才发现 baseline 不够顶。`venue_lookup.sh` 应该在每次决定"采用 X 论文作为方法源"前调用,而不是只在 M7 audit 时才查。

---

## 与反幻觉协议的关系

反幻觉协议管"这篇论文是否存在 / 引用是否真实",venue-quality 管"这篇论文是否够顶 / 引用能否支撑论证"。

两者**正交且互补**:
- 一篇 NBER WP 可以通过反幻觉验证(DOI 真、作者真、abstract 真)
- 但同时被 venue-quality 拒绝(WP 不是同行评审,不能当 baseline)

Agent 必须**两道筛子都过**才能引用。
