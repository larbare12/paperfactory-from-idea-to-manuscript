---
name: literature-research-protocol
description: |
  文献检索三段式工作流(广搜 → 筛选 → 收集 → 人工补全 → 删除)。
  manifest.jsonl 状态语义 + 工作流陷阱(多轮检索 / 临时产物清理)。
  M1 选题、M2 文献、M6 写作、M7 总检、M8 评审、M9 合规检索时必读。
applies_to: [m1, m2, m6, m7, m8, m9]
related:
  - anti-hallucination-protocol.md
  - venue-quality-protocol.md
  - manifest-schema.md
---

# 文献检索三段式工作流

> 本文档只管"如何检索"。真实性验证规范见 [anti-hallucination-protocol.md](anti-hallucination-protocol.md)。
> venue 质量过滤规范见 [venue-quality-protocol.md](venue-quality-protocol.md)。

**首次检索 / 写作中补充检索 / 综述章节扩展,统一走这三段。** 不再有"Agent 拿到 search 结果后人工逐篇下载 PDF"的乱流——所有重复操作脚本化以省 token。

---

## Stage 1:广搜

```bash
bash skills/citation-search/scripts/paper_search.sh "<query>" --mode multi --year 2020- --limit 30 \
     > relate-work/search-<slug>-$(date +%Y%m%d).jsonl
```

三源(arXiv + S2 + OpenAlex)并发 + BM25 重排。每条记录含字段 `pdf_url` / `pdf_status` / `s2_paper_id` / `openalex_id`,供 Stage 3 使用。

## Stage 2:筛选

Agent 阅读 search-*.jsonl,**用判断力**决定哪些与本工作真正相关(基础/方法/对比/相关四类,对应 manifest 的 `tags` 字段)。**Agent 不亲手写 JSONL**,调 helper 批量入表:

```bash
bash skills/citation-search/scripts/collect_papers.sh \
     --search relate-work/search-<slug>-<date>.jsonl \
     --bibkeys vaswani-2017-attention,kipf-2017-semi,...
```

bibkey 算法:`<第一作者姓 ascii lower>-<年>-<标题前2个非停用词>`,例 `vaswani-2017-attention`。冲突自动加 `-2`/`-3` 后缀。Agent 选 bibkey 时可以先 dry-run 看候选:

```bash
py -3 -c "
import sys, json
sys.path.insert(0, 'skills/citation-search/scripts')
from manifest import make_bibkey
with open('relate-work/search-X.jsonl') as f:
    taken = set()
    for line in f:
        e = json.loads(line)
        bk = make_bibkey(e, taken); taken.add(bk)
        print(bk, '|', e['title'][:60])
"
```

## Stage 3:收集(脚本自动)

`collect_papers.sh` 内部按顺序跑:

1. `manifest.py add` —— 把选定的 bibkeys 入 `relate-work/manifest.jsonl`,status=`pending`
2. `manifest.py download` —— 优先 arxiv 直链 > OpenAlex `best_oa_location` > S2 `openAccessPdf`,成功的 PDF 落 `relate-work/pdf/<bibkey>.pdf` 并设 status=`downloaded`,失败的设 status=`missing`
3. `manifest.py render` —— 生成 `manifest.md`(全表)+ `missing.md`(待人工补全清单 + 建议来源链接)

## Stage 4:用户人工补全闭源

闭源期刊(IEEE Trans / Elsevier / 部分 Springer)拿不到 OA PDF。Agent 把 `relate-work/missing.md` 显示给用户,用户从机构订阅手动下载,重命名为 `<bibkey>.pdf` 放进 `relate-work/pdf/`,再跑:

```bash
py -3 skills/citation-search/scripts/manifest.py scan      # 检测新 PDF,状态变 user-supplied
```

## Stage 5:删除找不到的

对仍 missing 的,用户也无法找到时,向用户确认后从 manifest 移除:

```bash
py -3 skills/citation-search/scripts/manifest.py prune          # 交互式 y/n
py -3 skills/citation-search/scripts/manifest.py prune --yes    # 批量
```

---

## 状态语义(manifest.jsonl 的 `status` 字段)

| status | 含义 |
|---|---|
| `pending` | 刚 add,尚未尝试下载 |
| `downloaded` | 脚本自动 OA 下载成功 |
| `user-supplied` | 用户手动放进来后被 scan 识别 |
| `missing` | 下载失败,无 OA URL,等用户补 |
| `manual` | 用户标记不下载(保留元数据,不索取 PDF) |

详细字段约定见 [`manifest-schema.md`](manifest-schema.md)。

> Agent 在 M1 末尾必须执行 Stage 1+2+3 一轮,把候选论文落到 manifest。M6 写作时检索补充文献,同样走这三段。**绝对禁止跳过 manifest 直接 cite 论文**——[反幻觉协议](anti-hallucination-protocol.md) Layer 3 验证以 manifest.jsonl 为权威清单。

---

## 工作流陷阱(实战反思)

以下是 Agent 默认行为容易过度执行/省略的几点,使用三段式工作流前先确认。**不涉及反幻觉/venue 的陷阱见对应专题协议。**

### ⚠️ 不要默认多轮检索

当用户的引用目标是聚焦的(≤ 5 篇、主题明确,例如"几篇能证明 X 的论文"、"补一篇 baseline"),单次 `paper_search.sh --mode multi --limit 25` 通常已经覆盖所有 strong matches。

多跑 2-3 轮(不同关键词)会让 `search-*.jsonl` 在 relate-work/ 冗余堆积,最终选定的 bibkey 多半都来自第 1 轮。

**默认 1 轮起步**,仅当第 1 轮命中显著不足或用户明示要做综述级广搜时再扩展。

### 🗑️ 临时调试产物不要落到 relate-work/

relate-work/ 是用户的论文产物目录,不是 Agent 的 scratch space。以下中间文件应写到系统临时路径(`$TMPDIR` / `mktemp -d`),用完即删:

- 人工预览搜索结果的标题列表
- Windows GBK 终端编码 workaround 的 UTF-8 dump
- dry-run 输出

落到 relate-work/ 的产物应仅限脚本规定的正式输出:`manifest.*` / `search-<slug>-<date>.jsonl` / `citation_verification_report_*.md` / `pdf/`。
