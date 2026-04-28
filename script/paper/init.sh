#!/bin/bash
# 初始化脚本 - 加载配置和设置路径变量
# 用法: source script/paper/init.sh
#
# 路径约定（已脱离 citation-assistant-main，整合进 paper.skill）：
#   <PROJECT_ROOT>/script/paper/   ← 本脚本位置
#   <PROJECT_ROOT>/reference/        ← sqlite 数据库 + 写作指南
#   <PROJECT_ROOT>/relate-work/    ← M1 写入、M3/M6 读取
#   <PROJECT_ROOT>/.env            ← S2_API_KEY 等

# 获取项目根目录
if [[ -n "${PAPER_SKILL_ROOT:-}" ]]; then
    PROJECT_ROOT="${PAPER_SKILL_ROOT}"
elif [[ -n "${CLAUDE_SKILL_ROOT:-}" ]]; then
    # 兼容旧变量
    PROJECT_ROOT="${CLAUDE_SKILL_ROOT}"
else
    # 从 script/paper/ 向上两级
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi

# 加载 .env 文件（如果存在）
if [[ -f "$PROJECT_ROOT/.env" ]]; then
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
fi

# 数据目录与工作目录
export SKILL_DATA_DIR="$PROJECT_ROOT/reference"
export RELATE_WORK_DIR="$PROJECT_ROOT/relate-work"

# Rate limit 配置
export S2_RATE_LIMIT_FILE="/tmp/.s2_rate_limit"
export S2_MIN_INTERVAL="${S2_MIN_INTERVAL:-1}"

# 颜色输出（可选）
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export NC='\033[0m'

error_msg()   { echo -e "${RED}Error:${NC} $1" >&2; }
warn_msg()    { echo -e "${YELLOW}Warning:${NC} $1" >&2; }
success_msg() { echo -e "${GREEN}✓${NC} $1"; }
