#!/usr/bin/env bash
set -e

# paperfactory install script
# Usage: curl -fsSL https://raw.githubusercontent.com/larbare12/paperfactory/master/install.sh | bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

REPO="https://github.com/larbare12/paperfactory.git"
INSTALL_DIR="${HOME}/.claude/plugins/paperfactory"

echo ""
echo -e "${CYAN}paperfactory: from idea to manuscript${NC}"
echo "全自动论文生产线 —— Claude Code Plugin"
echo ""

# --- Check git ---
if ! command -v git &>/dev/null; then
    echo -e "${RED}[FAIL]${NC} git 未安装。请先安装 git: https://git-scm.com"
    exit 1
fi

# --- Install ---
if [[ -d "$INSTALL_DIR" ]]; then
    echo -e "${YELLOW}[INFO]${NC} ${INSTALL_DIR} 已存在，执行 git pull 更新..."
    git -C "$INSTALL_DIR" pull --ff-only
else
    echo -e "${GREEN}[INSTALL]${NC} 克隆 paperfactory 到 ${INSTALL_DIR} ..."
    mkdir -p "$(dirname "$INSTALL_DIR")"
    git clone "$REPO" "$INSTALL_DIR"
fi

echo ""
echo -e "${GREEN}[OK]${NC} paperfactory 已安装到:"
echo "  ${INSTALL_DIR}"
echo ""
echo -e "${CYAN}下一步:${NC}"
echo "  1. cd 到你的论文项目目录"
echo "  2. 启动 claude"
echo "  3. 运行 /paperfactory:init"
echo ""
echo -e "${YELLOW}需要 S2 API key:${NC} https://www.semanticscholar.org/product/api"
echo ""

# --- Check Claude Code ---
if ! command -v claude &>/dev/null; then
    echo -e "${RED}[WARN]${NC} 未检测到 claude 命令。请先安装 Claude Code:"
    echo "  https://docs.anthropic.com/en/docs/claude-code/overview"
    echo ""
fi
