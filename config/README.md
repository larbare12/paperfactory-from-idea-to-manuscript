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
    }
  }
}
```

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
| `paper_search.sh` | Semantic Scholar, CrossRef | 搜索论文 |
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
