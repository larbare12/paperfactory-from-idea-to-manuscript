#!/bin/bash
# 配置验证脚本 - 检查所有配置是否正确加载
# 用法: bash script/paper/verify_config.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PAPER_SKILL_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

echo "📋 配置验证检查"
echo "==============================================="
echo ""

# 检查 1: config/api.json 文件
echo "✓ 检查 1: config/api.json 文件"
if [[ -f "$PROJECT_ROOT/config/api.json" ]]; then
    echo "  ✅ 文件存在"
else
    echo "  ❌ 文件不存在: $PROJECT_ROOT/config/api.json"
    exit 1
fi
echo ""

# 检查 2: .env 文件
echo "✓ 检查 2: .env 文件"
if [[ -f "$PROJECT_ROOT/.env" ]]; then
    echo "  ✅ 文件存在"
else
    echo "  ⚠️  .env 文件不存在，请从 .env.example 复制"
    echo "     命令: cp .env.example .env"
fi
echo ""

# 检查 3: 加载配置
echo "✓ 检查 3: 加载配置"
if source "$SCRIPT_DIR/load_config.sh" 2>/dev/null; then
    echo "  ✅ 配置加载成功"
else
    echo "  ❌ 配置加载失败"
    exit 1
fi
echo ""

# 检查 4: API 端点变量
echo "✓ 检查 4: API 端点变量"
echo "  Semantic Scholar base URL: $S2_BASE_URL"
echo "  Semantic Scholar API Key Header: $S2_API_KEY_HEADER"
echo "  CrossRef base URL: $CROSSREF_BASE_URL"
echo "  DOI base URL: $DOI_BASE_URL"
echo ""

# 检查 5: 环境变量
echo "✓ 检查 5: 环境变量"
if [[ -n "$S2_API_KEY" ]]; then
    # 只显示前几个字符，保护密钥
    key_preview="${S2_API_KEY:0:4}****${S2_API_KEY: -4}"
    echo "  ✅ S2_API_KEY 已设置: $key_preview"
else
    echo "  ⚠️  S2_API_KEY 未设置"
    echo "     请在 .env 文件中设置: S2_API_KEY=your_key"
fi
echo ""

# 检查 6: JSON 有效性
echo "✓ 检查 6: JSON 格式有效性"
if jq empty "$PROJECT_ROOT/config/api.json" 2>/dev/null; then
    echo "  ✅ JSON 格式正确"
else
    echo "  ❌ JSON 格式错误，请检查 config/api.json"
    exit 1
fi
echo ""

# 检查 7: 必要的脚本
echo "✓ 检查 7: 脚本文件"
scripts=(
    "author_info.sh"
    "paper_search.sh"
    "doi2bibtex.sh"
    "venue_lookup.sh"
    "init.sh"
)

all_exist=true
for script in "${scripts[@]}"; do
    if [[ -f "$SCRIPT_DIR/$script" ]]; then
        echo "  ✅ $script"
    else
        echo "  ❌ $script 不存在"
        all_exist=false
    fi
done

if [[ "$all_exist" != true ]]; then
    exit 1
fi
echo ""

# 检查 8: jq 是否安装
echo "✓ 检查 8: jq 工具"
if command -v jq &> /dev/null; then
    jq_version=$(jq --version)
    echo "  ✅ jq 已安装: $jq_version"
else
    echo "  ❌ jq 未安装"
    echo "     请安装 jq (MacOS: brew install jq, Linux: apt-get install jq)"
    exit 1
fi
echo ""

echo "==============================================="
echo "✅ 所有检查通过！配置已准备就绪。"
echo ""
echo "可以运行以下命令测试："
echo "  bash script/paper/author_info.sh \"1699545\""
echo "  bash script/paper/paper_search.sh \"deep learning\""
echo ""
