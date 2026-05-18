# relate-work/manifest.jsonl Schema

**Single source of truth** for the literature collected for this paper. One JSON object per line. Read/written by `script/paper/manifest.py`. Rendered into `manifest.md` (full table) and `missing.md` (gap list) by `manifest.py render`.

## Fields

| 字段 | 类型 | 是否必有 | 说明 |
|---|---|---|---|
| `bibkey` | string | ✅ | 唯一标识，格式 `<姓>-<年>-<标题前2词>`，如 `vaswani-2017-attention`。冲突时加后缀 `-2`/`-3`。 |
| `title` | string | ✅ | 论文标题（去换行）|
| `authors` | string[] | ✅ | 作者全名数组（取前 10 位）|
| `year` | int \| null | 通常有 | 发表年份 |
| `venue` | string | 通常有 | 发表会议/期刊 |
| `abstract` | string | 通常有 | 摘要全文 |
| `doi` | string \| null | 部分有 | DOI（无 `https://doi.org/` 前缀）|
| `arxiv_id` | string \| null | 部分有 | arXiv ID（无版本号），如 `1706.03762` |
| `s2_paper_id` | string | 部分有 | Semantic Scholar paperId |
| `openalex_id` | string | 部分有 | OpenAlex Work ID（如 `W2964121244`）|
| `pdf_url` | string | 部分有 | OA PDF 直链。优先级：arxiv → OpenAlex `best_oa_location` → S2 `openAccessPdf` |
| `pdf_source` | string | 部分有 | PDF 来源标签（`arxiv` / `openalex` / `s2`）|
| `status` | enum | ✅ | 见下方枚举 |
| `filename` | string \| null | 仅下载后 | 文件名（位于 `relate-work/pdf/`），通常 `<bibkey>.pdf` |
| `tags` | string[] | ✅ | 用户/Agent 加的标签（如 `foundational`/`method`/`baseline`/`related`）|
| `added_date` | string | ✅ | YYYY-MM-DD，加入 manifest 当天 |
| `downloaded_date` | string \| null | 仅下载后 | YYYY-MM-DD |
| `notes` | string | ✅ | 自由文本备注（下载失败原因、人工注释等）|

## status 枚举

| 值 | 含义 | 触发 |
|---|---|---|
| `pending` | 刚加入，未尝试下载 | `manifest.py add` |
| `downloaded` | 脚本自动 OA 下载成功 | `manifest.py download` 成功 |
| `user-supplied` | 用户手动放进 `relate-work/pdf/` 后被 scan 识别 | `manifest.py scan` |
| `missing` | 下载尝试失败，无 OA URL 或返回非 PDF | `manifest.py download` 失败 |
| `manual` | 用户显式标记不下载（保留元数据但不索取 PDF）| 手工编辑 manifest.jsonl |

## 状态流转

```
                     add
                      │
                      ▼
                  ┌──────┐  download (OA hit)    ┌────────────┐
                  │pending├──────────────────────▶│ downloaded │
                  └───┬──┘                       └────────────┘
                      │ download (no OA / fail)
                      ▼
                  ┌──────┐  scan (user dropped pdf)  ┌──────────────┐
                  │missing├───────────────────────────▶│user-supplied│
                  └───┬──┘                          └──────────────┘
                      │ prune
                      ▼
                  (deleted)
```

## 文件命名约定

- PDF 文件位于 `relate-work/pdf/<bibkey>.pdf`
- 用户手动放进来的 PDF 必须以 `<bibkey>.pdf` 命名才能被 `scan` 识别
- bibkey 复用 BibTeX key 习惯，方便 `\cite{vaswani-2017-attention}` 直接引用

## 编辑规则

- **不要直接手动编辑 `manifest.jsonl`**——用 `manifest.py` 子命令操作以保证幂等和 atomic 写入
- 例外：用户想把某条标 `manual`（不让脚本下载）时可手动改 status 字段
- 删除条目用 `manifest.py prune`，不要手动 sed 删行（容易删坏）

## 例

```json
{
  "bibkey": "vaswani-2017-attention",
  "title": "Attention Is All You Need",
  "authors": ["Ashish Vaswani", "Noam Shazeer", "Niki Parmar"],
  "year": 2017,
  "venue": "NeurIPS",
  "abstract": "The dominant sequence transduction models are based on...",
  "doi": "10.5555/3295222.3295349",
  "arxiv_id": "1706.03762",
  "s2_paper_id": "204e3073870fae3d05bcbc2f6a8e263d9b72e776",
  "openalex_id": "W2964121244",
  "pdf_url": "https://arxiv.org/pdf/1706.03762",
  "pdf_source": "arxiv",
  "status": "downloaded",
  "filename": "vaswani-2017-attention.pdf",
  "tags": ["foundational", "attention"],
  "added_date": "2026-05-06",
  "downloaded_date": "2026-05-06",
  "notes": ""
}
```
