---
name: literature-research-protocol
description: |
  文献检索与反幻觉协议。涵盖三段式检索工作流、manifest 维护、引用真实性
  三层验证机制、红线清单、常见陷阱。任何涉及学术检索 / BibTeX 维护 /
  引用核验的模块（M1 选题、M2 文献、M6 写作、M7 总检）在执行前必须读完本文。
applies_to: [m1, m2, m6, m7]
---

# 文献检索与反幻觉协议（Literature Research Protocol）

> 本文档是 paper.skill 三段式文献工作流（v0.6+）与反幻觉硬约束的合订本。
> SKILL.md 不再重复其内容；任何涉及学术检索的模块直接引用本文。

---

## ⚠️ Part 1：反幻觉硬约束（Anti-Hallucination）

**论文检索（M1/M2）完成后，所有引用必须经过真实性验证才能进入 M6 写作。这是最严重的红线，违反将导致论文撤稿风险。**

### 三层验证机制

#### Layer 1：来源验证（每篇文献入库时）
- 任何文献从外部进入 `relate-work/` 之前，必须有可验证的来源标识：DOI / arXiv ID / Semantic Scholar paperId 至少一个
- 没有标识符的"凭印象引用" → 直接丢弃，不允许"先写上再说"
- 检索结果必须通过 `script/paper/paper_search.sh` 或同等脚本获得，禁止 Agent 自行"回忆"论文标题、作者、年份

#### Layer 2：引用验证（写作阶段，每次新增 \cite 时）
- 草稿中每个 `\cite{key}` 或 `[@key]` 必须在 `references.bib` 中有完整条目
- 进入 M7 前必须运行：
  ```bash
  bash script/paper/verify_citations.sh relate-work/draft.tex --bib relate-work/references.bib
  ```
- 报告会按"五类幻觉分类"（虚构标题、错配作者、年份偏差、虚假 venue、不存在 DOI）输出
- **任何 Tier 0（高风险）幻觉未消除 → 禁止进入 M7**

#### Layer 3：内容一致性（论证阶段）
- 引用论文的核心论点、数值、结论，Agent 不得复述记忆，必须从 `relate-work/manifest.jsonl` 中 status=`downloaded`/`user-supplied` 的论文全文里摘录（v0.6+：以 manifest 为唯一权威清单）
- 若 manifest 中该 bibkey 的 status=`missing` 或 `pending`（PDF 尚未到位）→ 标记 `[NEEDS-EVIDENCE]` 并在 M6 检查中回填
- 见 [M6 写作辅助](../modules/m6-writing.md) 的 "MATERIAL GAP IRON RULE"

### 红线清单（任何一条触发立即 STOP）

- 🚫 用模型记忆引用 2024 年之后的论文（知识截止前后的论文都不可信）
- 🚫 凭"似乎读过"补全 BibTeX 字段（作者、期刊、卷号、页码）
- 🚫 把 arXiv 预印本当作正式期刊版本引用
- 🚫 跳过 `verify_citations.sh` 直接进入 M7

> Agent 在 M2 结束、M6 进入前、M7 进入前 **三个时点**，必须主动运行 `verify_citations.sh` 并把报告路径告诉用户。

---

## 📚 Part 2：文献检索三段式工作流（v0.6+）

**首次检索 / 写作中补充检索 / 综述章节扩展，统一走这三段。** 不再有"Agent 拿到 search 结果后人工逐篇下载 PDF"的乱流——所有重复操作脚本化以省 token。

### Stage 1：广搜

```bash
bash script/paper/paper_search.sh "<query>" --mode multi --year 2020- --limit 30 \
     > relate-work/search-<slug>-$(date +%Y%m%d).jsonl
```

三源（arXiv + S2 + OpenAlex）并发 + BM25 重排。每条记录含字段 `pdf_url` / `pdf_status` / `s2_paper_id` / `openalex_id`，供 Stage 3 使用。

### Stage 2：筛选

Agent 阅读 search-*.jsonl，**用判断力**决定哪些与本工作真正相关（基础/方法/对比/相关四类，对应 manifest 的 `tags` 字段）。**Agent 不亲手写 JSONL**，调 helper 批量入表：

```bash
bash script/paper/collect_papers.sh \
     --search relate-work/search-<slug>-<date>.jsonl \
     --bibkeys vaswani-2017-attention,kipf-2017-semi,...
```

bibkey 算法：`<第一作者姓 ascii lower>-<年>-<标题前2个非停用词>`，例 `vaswani-2017-attention`。冲突自动加 `-2`/`-3` 后缀。Agent 选 bibkey 时可以先 dry-run 看候选：

```bash
py -3 -c "
import sys, json
sys.path.insert(0, 'script/paper')
from manifest import make_bibkey
with open('relate-work/search-X.jsonl') as f:
    taken = set()
    for line in f:
        e = json.loads(line)
        bk = make_bibkey(e, taken); taken.add(bk)
        print(bk, '|', e['title'][:60])
"
```

### Stage 3：收集（脚本自动）

`collect_papers.sh` 内部按顺序跑：

1. `manifest.py add` —— 把选定的 bibkeys 入 `relate-work/manifest.jsonl`，status=`pending`
2. `manifest.py download` —— 优先 arxiv 直链 > OpenAlex `best_oa_location` > S2 `openAccessPdf`，成功的 PDF 落 `relate-work/pdf/<bibkey>.pdf` 并设 status=`downloaded`，失败的设 status=`missing`
3. `manifest.py render` —— 生成 `manifest.md`（全表）+ `missing.md`（待人工补全清单 + 建议来源链接）

### Stage 4：用户人工补全闭源

闭源期刊（IEEE Trans / Elsevier / 部分 Springer）拿不到 OA PDF。Agent 把 `relate-work/missing.md` 显示给用户，用户从机构订阅手动下载，重命名为 `<bibkey>.pdf` 放进 `relate-work/pdf/`，再跑：

```bash
py -3 script/paper/manifest.py scan      # 检测新 PDF，状态变 user-supplied
```

### Stage 5：删除找不到的

对仍 missing 的，用户也无法找到时，向用户确认后从 manifest 移除：

```bash
py -3 script/paper/manifest.py prune          # 交互式 y/n
py -3 script/paper/manifest.py prune --yes    # 批量
```

### 状态语义（manifest.jsonl 的 `status` 字段）

| status | 含义 |
|---|---|
| `pending` | 刚 add，尚未尝试下载 |
| `downloaded` | 脚本自动 OA 下载成功 |
| `user-supplied` | 用户手动放进来后被 scan 识别 |
| `missing` | 下载失败，无 OA URL，等用户补 |
| `manual` | 用户标记不下载（保留元数据，不索取 PDF） |

详细字段约定见 [`../docs/MANIFEST_SCHEMA.md`](../docs/MANIFEST_SCHEMA.md)。

> Agent 在 M1 末尾必须执行 Stage 1+2+3 一轮，把候选论文落到 manifest。M6 写作时检索补充文献，同样走这三段。**绝对禁止跳过 manifest 直接 cite 论文**——Layer 3 验证以 manifest.jsonl 为权威清单。

---

## 🪤 Part 3：常见陷阱（实战反思）

以下是 Agent 默认行为容易过度执行/省略的几点，使用三段式工作流前先确认：

- **不要默认多轮检索。** 当用户的引用目标是聚焦的（≤ 5 篇、主题明确，例如"几篇能证明 X 的论文"、"补一篇 baseline"），单次 `paper_search.sh --mode multi --limit 25` 通常已经覆盖所有 strong matches。多跑 2-3 轮（不同关键词）会让 `search-*.jsonl` 在 relate-work/ 冗余堆积，最终选定的 bibkey 多半都来自第 1 轮。**默认 1 轮起步**，仅当第 1 轮命中显著不足或用户明示要做综述级广搜时再扩展。

- **临时调试产物不要落到 relate-work/。** relate-work/ 是用户的论文产物目录，不是 Agent 的 scratch space。以下中间文件应写到系统临时路径（`$TMPDIR` / `mktemp -d`），用完即删：人工预览搜索结果的标题列表、Windows GBK 终端编码 workaround 的 UTF-8 dump、dry-run 输出。落到 relate-work/ 的产物应仅限脚本规定的正式输出（`manifest.*` / `search-<slug>-<date>.jsonl` / `citation_verification_report_*.md` / `pdf/`）。

- 🚫 **Abstract-only cite 反模式（最严重的隐性幻觉源）。** 检索结果中的 abstract 通常只够支撑**框架性提及**（"... such as \cite{X}"），**绝不够**支撑 paraphrase 类陈述（"X 论文做了 Y / 复现了 Z / 验证了 W"）。abstract 会让你**无法分辨**：
  - 论文用的是 LLM agent 还是 transformer foundation model（例：MarS 不是 LLM agent，是 order-level generative foundation model）
  - 论文是否真的复现了你想引用的现象（例：SimFin abstract 说 "consistent with preliminary findings" 而不是 "reproduce price bubbles"）
  - 论文研究的对象是什么（例：InvestAlign 研究 SFT 数据生成，不研究 willingness 系数）

  **硬约束**：只要你打算 paraphrase "论文 X 做了什么/发现了什么/复现了什么"，**必须**：(1) `relate-work/pdf/<bibkey>.pdf` 已存在；(2) `manifest.jsonl` 中该 bibkey `status ∈ {downloaded, user-supplied}`；(3) 你**亲自**精读了相关章节（method/experiments/results），不是只看 abstract。如果以上任何一条不满足，必须先用 `[NEEDS-EVIDENCE]` 占位，**严禁直接 cite**。

  **OA 优先策略**：Stage 3 的 `collect_papers.sh` 会自动尝试 arXiv → OpenAlex → S2 OA 下载，OA 命中率通常 60–90%。**对 OA 论文（status=downloaded），Agent 必须立即精读再 cite**——能下载没读、然后只看 abstract 写引用是双重失误。对闭源论文（status=missing），按 Stage 4 流程引导用户从机构订阅手动补全，**未补全前严禁 paraphrase**。

- ⚠️ **`verify_citations.sh` 的 BibTeX parser 已知缺陷：嵌套 `{...}` 大写保护会截断 title。** 例如 `title = {{OASIS}: Open Agent Social ...}` 会被解析为 `{OASIS`，与 S2 真实 title 的 fuzzy match 失败，归类为 `DOI_MISMATCH / PAC`，但 DOI 实际能 resolve（"DOI resolves but title mismatch"）——这是**假阳性**，不是反幻觉失败。**判读规则**：报告显示 `DOI resolves` + `match_score < 0.7` + 该条目 .bib title 含嵌套 `{...}` 时，按照 known issue 处理；可临时建一份去掉大括号保护的 minimal .bib 重跑一次确认。修复 parser 是 paper.skill 的待办（issue 待提）。
