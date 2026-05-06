#!/bin/bash
# 配置加载函数 - 被其他脚本 source 调用
# 用法: source script/paper/load_config.sh

# 解析 SKILL_DIR（v0.6+：与 PROJECT_DIR 区分）
if [[ -n "${PAPER_SKILL_DIR:-}" ]]; then
    : # already set
elif [[ -n "${PAPER_SKILL_ROOT:-}" ]]; then
    PAPER_SKILL_DIR="${PAPER_SKILL_ROOT}"  # back-compat
elif [[ -n "${CLAUDE_SKILL_ROOT:-}" ]]; then
    PAPER_SKILL_DIR="${CLAUDE_SKILL_ROOT}"
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PAPER_SKILL_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi
PAPER_PROJECT_DIR="${PAPER_PROJECT_DIR:-$PWD}"

# Back-compat: PROJECT_ROOT used to mean SKILL_DIR
PROJECT_ROOT="${PAPER_SKILL_DIR}"

# 加载 .env：优先项目目录，其次 skill 目录
if [[ -f "$PAPER_PROJECT_DIR/.env" ]]; then
    set -a; source "$PAPER_PROJECT_DIR/.env"; set +a
elif [[ -f "$PAPER_SKILL_DIR/.env" ]]; then
    set -a; source "$PAPER_SKILL_DIR/.env"; set +a
fi

# 加载 API 配置（始终从 SKILL_DIR）
CONFIG_FILE="$PAPER_SKILL_DIR/config/api.json"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config file not found at $CONFIG_FILE" >&2
    exit 1
fi

# 从 JSON 配置中提取 API 端点和 Header 名称
get_api_config() {
    local api_name="$1"
    local key="$2"
    jq -r ".api.${api_name}.${key} // empty" "$CONFIG_FILE" 2>/dev/null
}

# Semantic Scholar API 配置
export S2_BASE_URL=$(get_api_config "semantic_scholar" "base_url")
export S2_API_KEY_HEADER=$(get_api_config "semantic_scholar" "api_key_header")
export S2_API_KEY_ENV_VAR=$(get_api_config "semantic_scholar" "api_key_env_var")
export S2_RATE_LIMIT_MIN_INTERVAL=$(get_api_config "semantic_scholar" "rate_limit_min_interval")

# CrossRef API 配置
export CROSSREF_BASE_URL=$(get_api_config "crossref" "base_url")

# DOI API 配置
export DOI_BASE_URL=$(get_api_config "doi" "base_url")
