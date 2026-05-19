---
name: citation-search
description: |
  学术文献检索与质量验证。覆盖 Semantic Scholar / CrossRef / arXiv /
  OpenAlex 四源,内置 Tier 0 反幻觉校验(DOI 反查 + Levenshtein ≥ 0.70)
  和 venue quality 过滤(CCF + JCR 影响因子,arXiv 引用阈值)。任何需要
  查文献、验证引用真实性、评估期刊/会议质量、生成 BibTeX、或建立证据池
  的场景都应调用本 skill,而不是让 Claude 凭记忆产出引用。M0-M9 模块在
  执行文献检索时统一委托给本 skill,不重复实现。
allowed-tools: Bash Read Write Edit Grep Glob
---

# citation-search

> 论文检索 + 真实性验证 + venue 质量评估,paper-assistant 的检索基座。
> 任何"我需要查文献 / 我需要验证引用 / 我需要看 venue 质量"的场景,都先来这里。

---

## 何时调用本 skill

本 skill 是 paper-assistant 的**横切工具**,被以下场景调用:

| 来源场景 | 典型操作 | 推荐 mode |
|---|---|---|
| **idea 验证** | "有人做过 X 吗?" | `mode=multi` 广搜 |
| **M1 选题诊断** | 建立候选研究池,评估创新性 | `mode=multi` + 写入 `relate-work/` |
| **M2 文献综述** | 引用网络分析 + Tier 0 校验 + bib 规范化 | 五种 mode 都用 |
| **M3 实验设计** | 找同类实验 / baseline 论文 | `mode=standard` 相关性排序 |
| **M5 论证设计** | 为每条 claim 找证据支撑或反驳 | `find_evidence.sh` + `mode=verify` |
| **M6 写作** | 写作时实时校验 `\cite{...}` | `mode=verify` 增量 |
| **M7 总检** | 全文引用 audit + BibTeX 检查 | `verify_citations.sh` 批量 |
| **M8 同行评审仿真** | 反向检索质疑性文献 + venue 评级 | `mode=multi` + `venue_lookup.sh` |
| **M9 PRISMA-trAIce** | 系统检索(指定年份范围) | `mode=bulk` + `--year` 过滤 |

**反例**:Claude 自己"记得"某篇论文然后直接写 `\cite{vaswani-2017-attention}` —— **禁止**。所有引用必须经过本 skill 的检索 + 校验流程。详见 [`reference/anti-hallucination-protocol.md`](reference/anti-hallucination-protocol.md)。

---

## 五种检索 mode 速查

`scripts/paper_search.sh` 是统一入口,通过 `--mode` 分发:

| mode | 平台 | 用途 | 限制 | 何时用 |
|---|---|---|---|---|
| `standard` | Semantic Scholar `/paper/search` | **相关性排序首选** | limit ≤ 100 | 一般检索,要相关性 |
| `bulk` | Semantic Scholar `/paper/search/bulk` | 大量、year 过滤,token 分页 | 无相关性排序 | 综述、PRISMA 系统检索 |
| `crossref` | CrossRef `/works` | 元数据较弱但**无严格限流** | 字段少 | S2 限流(429)时 fallback |
| `multi` | arXiv + S2 + OpenAlex 并发 + BM25 重排 | 覆盖最广 | 需 Python 依赖 | 综述、idea 验证、找漏网论文 |
| `verify` | S2 (DOI 反查或 title 搜索) | **Tier 0 真实性校验** | 输入 NDJSON | 引用入库 / M7 audit |

### 决策树

```
有 DOI / 知道具体论文?
  → verify mode (DOI 反查 + Levenshtein 0.70)

要相关性排序、limit ≤ 100?
  → standard mode

要大量结果 + year 过滤(综述、PRISMA)?
  → bulk mode

要最广覆盖(arXiv + 期刊 + OpenAlex)?
  → multi mode (注意需 pip install -r requirements.txt)

S2 限流(429)?
  → crossref mode fallback
```

### 示例

```bash
# 一般检索(默认 standard,limit=20)
bash skills/citation-search/scripts/paper_search.sh "deep learning"

# 综述场景(bulk + year filter)
bash skills/citation-search/scripts/paper_search.sh "transformer attention" \
     --mode bulk --year 2020- --limit 200

# 三源广搜(综述、idea 验证)
bash skills/citation-search/scripts/paper_search.sh "graph neural network" \
     --mode multi --limit 30

# Tier 0 校验(输入 NDJSON,输出 NDJSON verdict)
echo '{"title":"Attention Is All You Need","doi":"10.48550/arXiv.1706.03762"}' \
  | bash skills/citation-search/scripts/paper_search.sh \
       --mode verify --input /dev/stdin
```

---

## 配套脚本

除 `paper_search.sh` 外,本 skill 提供以下专用工具:

| 脚本 | 用途 |
|---|---|
| [`scripts/venue_lookup.sh`](scripts/venue_lookup.sh) | venue 分级查询(CCF + JCR IF),数据库在 `data/` |
| [`scripts/verify_citations.sh`](scripts/verify_citations.sh) | 全文 `\cite{...}` 批量校验,生成 citation_verification_report |
| [`scripts/find_evidence.sh`](scripts/find_evidence.sh) | 为 claim 找证据(M5 论证用) |
| [`scripts/author_info.sh`](scripts/author_info.sh) | 作者 H-index / 引用量(评估论文权威性) |
| [`scripts/doi2bibtex.sh`](scripts/doi2bibtex.sh) | DOI → BibTeX(CrossRef content negotiation) |
| [`scripts/check_material_gaps.sh`](scripts/check_material_gaps.sh) | 扫描 `[NEEDS-EVIDENCE]` 缺口 |
| [`scripts/collect_papers.sh`](scripts/collect_papers.sh) | Stage 3 一键收集(add → download → render) |
| [`scripts/manifest.py`](scripts/manifest.py) | manifest.jsonl 维护(add / download / render / scan / prune) |
| [`scripts/verify_config.sh`](scripts/verify_config.sh) | 凭据 + 配置完整性自检 |

---

## 必读规范(进入本 skill 前/中)

| 文件 | 说明 | 何时读 |
|---|---|---|
| [`reference/literature-research-protocol.md`](reference/literature-research-protocol.md) | 三段式工作流 + 状态语义 + 工作流陷阱 | 首次检索 / 综述前 |
| [`reference/anti-hallucination-protocol.md`](reference/anti-hallucination-protocol.md) | 三层验证 + 红线 + abstract-only 反模式 + parser bug | **每次入库 / 写作 / M7 前必读** |
| [`reference/venue-quality-protocol.md`](reference/venue-quality-protocol.md) | venue 三把尺 + 方法论 baseline 硬约束 | 筛选 Stage 2 / 选 baseline 时必读 |
| [`reference/manifest-schema.md`](reference/manifest-schema.md) | `relate-work/manifest.jsonl` 字段约定 | 维护 manifest 时查阅 |

---

## 输出契约

### `mode=standard / bulk / crossref` 输出

每条一行 JSON(jq-friendly):

```json
{
  "title": "Attention Is All You Need",
  "year": 2017,
  "venue": "Neural Information Processing Systems",
  "citations": 145000,
  "doi": "10.48550/arXiv.1706.03762",
  "arxiv_id": "1706.03762",
  "url": "https://...",
  "abstract": "...",
  "is_arxiv": false,
  "arxiv_status": "normal",
  "recommendation": "✅ 正式发表",
  "authors": [{"name": "Ashish Vaswani", "id": "..."}]
}
```

### `mode=multi` 额外字段

```json
{
  "...all above...",
  "source": "s2",           // 来自哪源
  "also_in": ["arxiv"],     // 其他源也命中
  "bm25_score": 12.34,      // BM25 重排得分
  "pdf_url": "https://...", // OA 直链
  "pdf_status": "OA",       // OA | closed | unknown
  "s2_paper_id": "...",
  "openalex_id": "..."
}
```

### `mode=verify` 输出(NDJSON verdict)

```json
{
  "input_title": "...",
  "verdict": "VERIFIED" | "DOI_MISMATCH" | "S2_NOT_FOUND" | "S2_UNAVAILABLE",
  "s2_id": "...",
  "match_score": 0.95,                    // Levenshtein 相似度
  "hallucination_class": null | "PAC",    // PAC = Plausibly Authored Citation
  "notes": "..."
}
```

---

## 错误处理矩阵

| 状况 | 表现 | 处置 |
|---|---|---|
| S2 限流 | HTTP 429 | 等 1-2 秒重试,或切 `--mode crossref` |
| S2 限流(bulk 中) | 429 after N pages | 脚本会保留已抓的 N 页结果,警告输出到 stderr |
| DOI 不存在于 S2 | HTTP 404 / `verdict=S2_NOT_FOUND` | 真不存在 → 提示用户;S2 数据库缺失 → 用 CrossRef 查 |
| S2 网络失败 | `verdict=S2_UNAVAILABLE` | 检查 `.env` 凭据 / 网络代理 |
| Levenshtein < 0.70 | `verdict=DOI_MISMATCH` + `hallucination_class=PAC` | 红线,需用户复核(可能是 BibTeX parser bug,见 [anti-hallucination §parser bug](reference/anti-hallucination-protocol.md)) |
| 无 Python 3 | `mode=multi` 失败 | 装 Python 3.9+ 并 `pip install -r requirements.txt` |
| 缺 `S2_API_KEY` | verify_config.sh 报警 | `cp .env.example .env` 并填入 |

---

## 与上下游 skill 的交接

### 输入(被谁调用)

M0-M9 任何模块在需要检索/验证/venue 评估时调用本 skill。调用方传入:
- query 字符串(自然语言或关键词)
- 可选 `--mode` / `--year` / `--limit`
- verify 模式额外传 NDJSON 输入文件

### 输出(写到哪)

| 产物 | 路径 | 写入者 |
|---|---|---|
| 搜索结果 | `<project>/relate-work/search-<slug>-<date>.jsonl` | 调用方重定向 stdout |
| manifest 主表 | `<project>/relate-work/manifest.jsonl` | `manifest.py add` |
| OA PDF 缓存 | `<project>/relate-work/pdf/<bibkey>.pdf` | `manifest.py download` |
| 渲染报表 | `<project>/relate-work/manifest.md` + `missing.md` | `manifest.py render` |
| 引用校验报告 | `<project>/relate-work/citation_verification_report_<date>.md` | `verify_citations.sh` |

**关键约定**:本 skill **从不**直接修改 `<project>/draft/*.tex` 或 `references.bib` —— 那是 M2 / M6 的职责。本 skill 只提供 manifest / 验证报告,由 M2 / M6 决定如何写入草稿。

### 路径变量

- `PAPER_SKILL_DIR` = 本 skill 根目录(`<plugin>/skills/citation-search/`),scripts 自动解析
- `PAPER_PROJECT_DIR` = 用户论文项目根(默认 `$PWD`),`relate-work/` 写入此处
- `S2_API_KEY` = 从 `<project>/.env` 或 `<skill>/.env` 加载

---

## 凭据要求(首次使用前)

```bash
# 1. 在项目根或 skill 根创建 .env
cp .env.example .env

# 2. 在 https://www.semanticscholar.org/product/api 申请 S2 API key
# 填入 .env: S2_API_KEY=Bearer xxxxx

# 3. multi mode 额外需要 Python deps
pip install -r requirements.txt  # 仅 mode=multi 用

# 4. 自检
bash skills/citation-search/scripts/verify_config.sh
```
