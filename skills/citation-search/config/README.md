# 配置文件说明

## 目录结构

```
config/
├── api.json          # API 端点和 Header 配置
└── README.md         # 本文件
```

## api.json 配置文件

存储所有外部 API 的端点地址和认证信息配置。

### 结构说明

```json
{
  "api": {
    "semantic_scholar": {
      "base_url": "https://api.semanticscholar.org",        // 基础 URL
      "api_key_header": "x-api-key",                        // API 密钥 Header 名
      "api_key_env_var": "S2_API_KEY",                      // API 密钥环境变量名
      "rate_limit_min_interval": 1                          // 请求间隔（秒）
    },
    "crossref": {
      "base_url": "https://api.crossref.org"                // CrossRef API 基础 URL
    },
    "doi": {
      "base_url": "https://doi.org"                         // DOI 解析服务 URL
    },
    "arxiv": {                                              // v0.5+ multi 模式使用
      "base_url": "http://export.arxiv.org/api/query",      // 仅供参考；Python `arxiv` 库内置端点
      "_note": "无 API key；限流见下方表格"
    },
    "openalex": {                                           // v0.5+ multi 模式使用
      "base_url": "https://api.openalex.org",
      "mailto": null,                                       // 设为你的邮箱进 polite pool
      "_note": "免费层 100,000 req/day，限流见下方表格"
    }
  }
}
```

## 外部 API 参考与限流

各检索源的官方文档与限流策略汇总。修改 `base_url` 或诊断 429 错误时查这里。

| 源 | 用途 | 官方文档 | 限流 | 是否需要 key |
|---|---|---|---|---|
| **Semantic Scholar (S2)** | `--mode standard / bulk / verify`，引用核验 | [API 文档](https://api.semanticscholar.org/api-docs/) · [Graph API](https://api.semanticscholar.org/api-docs/graph) | 无 key：~1 req / 3-5s（限流较激进，触发 429 即等待）；有 key：100 req/s | 推荐有 key（[申请](https://www.semanticscholar.org/product/api)） |
| **arXiv** | `--mode multi` 中 arXiv 预印本检索 | [API 用户手册](https://info.arxiv.org/help/api/user-manual.html) · [API Basics](https://info.arxiv.org/help/api/basics.html) · [Terms of Use](https://info.arxiv.org/help/api/tou.html) | 推荐 1 req / 3s（在 `arxiv.Client(delay_seconds=3)` 中已设置）；触发限流后冷却约 5–30 分钟，**search_query 通道触发后会牵连 id_list 通道**（库强制带 `sortBy=relevance`） | 无 key 体系（纯 IP 限流） |
| **OpenAlex** | `--mode multi` 中跨学科检索（覆盖 2 亿+ 论文） | [API 文档](https://docs.openalex.org/) · [限流与认证](https://docs.openalex.org/how-to-use-the-api/rate-limits-and-authentication) · [Works 端点](https://docs.openalex.org/api-entities/works) | 默认 100,000 req/day + 10 req/s；提供 `mailto` 进 polite pool（响应更稳定） | ⚠️ **2026-02-13 起调用需要 API key**（[公告](https://groups.google.com/g/openalex-users/c/rI1GIAySpVQ)），credit 制：list=10 credits/req，约 10,000 次搜索/天 |
| **CrossRef** | `--mode crossref` fallback | [REST API 文档](https://api.crossref.org/swagger-ui/index.html) · [API tips](https://api.crossref.org/) | 无严格速率限制；建议带 `User-Agent: <name>; mailto:<email>` 进 polite pool | 无 key |
| **DOI Resolver** | DOI → 元数据 / URL 跳转 | [doi.org 文档](https://www.doi.org/the-identifier/resources/factsheets/doi-resolution-documentation/) | 不限流（HTTP 重定向服务） | 无 key |

### 限流诊断速查

- **HTTP 429 from arxiv.org** → 触发 IP 冷却。等 5–30 分钟，**不要**短时间内重试（会延长冷却）。代码已设 `delay_seconds=3` + `num_retries=3`，正常使用应不会触发；批量检索时建议按 `arxiv > sleep 4 > 下一条` 的节奏。
- **HTTP 429 from S2** → 立刻 fallback 到 `--mode crossref` 或 `--mode multi`（multi 模式即使 S2 失败，arXiv + OpenAlex 仍可返回）。
- **HTTP 401/403 from openalex.org**（未来可能） → 2026-02-13 后需 API key，[申请 OpenAlex Premium](https://help.openalex.org/hc/en-us/articles/24397762024087-Pricing) 后填入 `config/api.json` 的 `openalex.api_key`（字段尚未启用，留待后续 PR）。
- **HTTP 5xx** → 上游服务故障，重试或换源。multi 模式天然容错（任一源失败不阻塞其他源）。

### 数据缺失说明

| 字段 | S2 | arXiv | OpenAlex | CrossRef |
|---|---|---|---|---|
| `citationCount` | ✅ | ❌ **API 不返回**（预印本库非引用索引） | ✅ (`cited_by_count`) | ✅ (`is-referenced-by-count`) |
| `abstract` | ✅（部分） | ✅（`<summary>`） | ✅（`abstract_inverted_index` 需重组） | ❌ |
| `authors[].id` | ✅ (`authorId`) | ❌ | ✅ (OpenAlex ID) | ❌ |
| `references` | ✅（需 fields=references） | ❌ | ✅ (`referenced_works`) | ✅ (`reference`) |

⚠️ **arxiv-only 论文 `arxiv_status` 字段**：因 arXiv API 不返回 citation，`multi_source_search.py` 对仅在 arxiv 命中、未被 S2/OpenAlex 交叉验证的论文输出 `arxiv_status: "unknown"` 而非 caution/recommended——这是设计如此，避免把高影响力预印本误标为低引用。要拿到引用数请等 S2 或 OpenAlex 也命中（multi 模式默认会自动尝试）。

## 使用方式

### 在脚本中加载配置

```bash
#!/bin/bash
# 初始化
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PAPER_SKILL_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# 加载配置
source "$SCRIPT_DIR/load_config.sh"

# 现在可以使用配置中的变量
echo "$S2_BASE_URL"              # Semantic Scholar 基础 URL
echo "$S2_API_KEY_HEADER"        # API 密钥 Header 名
echo "$S2_API_KEY"               # API 密钥（从 .env 或环境变量）
echo "$CROSSREF_BASE_URL"        # CrossRef 基础 URL
echo "$DOI_BASE_URL"             # DOI 基础 URL
```

## 配置修改流程

### 修改 API 端点

1. 编辑 `config/api.json`
2. 修改对应 API 的 `base_url` 字段
3. 脚本会自动读取新配置，无需修改脚本代码

**示例**：如果 Semantic Scholar 迁移到新域名
```json
{
  "api": {
    "semantic_scholar": {
      "base_url": "https://api-new.semanticscholar.org",  // 修改此处
      ...
    },
    ...
  }
}
```

### 修改 API 密钥 Header

1. 编辑 `config/api.json`
2. 修改 `api_key_header` 字段
3. 所有使用该 Header 的脚本自动生效

**示例**：
```json
{
  "api": {
    "semantic_Scholar": {
      "api_key_header": "Authorization",  // 从 x-api-key 改为 Authorization
      ...
    },
    ...
  }
}
```

### 添加新的 API 端点

1. 在 `config/api.json` 中添加新的 API 配置
2. 在 `script/paper/load_config.sh` 中添加对应的配置加载代码
3. 在脚本中使用新的环境变量

**示例**：添加一个新的论文库 API
```json
{
  "api": {
    ...,
    "arxiv": {
      "base_url": "https://api.arxiv.org",
      "api_key_header": "X-Custom-Key"
    }
  }
}
```

然后在 `load_config.sh` 中添加：
```bash
export ARXIV_BASE_URL=$(get_api_config "arxiv" "base_url")
export ARXIV_API_KEY_HEADER=$(get_api_config "arxiv" "api_key_header")
```

## API 密钥管理

- **S2_API_KEY**：存储在项目根目录的 `.env` 文件中（不提交到版本控制）
- **其他 API**：如果需要密钥，也添加到 `.env` 文件中
- **配置中的字段**：只存储 Header 名称和环境变量名称，不存储实际的密钥

## 脚本列表

使用配置的脚本：

| 脚本 | API 端点 | 用途 |
|------|---------|------|
| `author_info.sh` | Semantic Scholar | 查询作者信息 |
| `paper_search.sh` (standard/bulk/verify) | Semantic Scholar | 搜索论文 + Tier 0 引用核验 |
| `paper_search.sh` (crossref) | CrossRef | S2 限流时的 fallback |
| `paper_search.sh` (multi, v0.5+) | arXiv + Semantic Scholar + OpenAlex | 三源并发 + BM25 重排 |
| `multi_source_search.py` (v0.5+) | arXiv + Semantic Scholar + OpenAlex | multi 模式实现（被 paper_search.sh 调用） |
| `doi2bibtex.sh` | DOI | DOI 转 BibTeX |
| `venue_lookup.sh` | 无（本地数据库） | 查询会议/期刊信息 |
| `find_evidence.sh` | 无（未实现） | 自动检索论据 |

## 故障排除

### 配置文件未找到

```
Error: Config file not found at /path/to/config/api.json
```

**解决**：
- 确保 `config/api.json` 文件存在于项目根目录下
- 确保 `PROJECT_ROOT` 设置正确

### API 端点变量为空

检查 `load_config.sh` 是否正确设置了 `jq` 查询，或者 `api.json` 的 JSON 格式是否正确。

### API 密钥 Header 不正确

检查 `config/api.json` 中 `api_key_header` 字段的值是否与 API 文档一致。
