#!/bin/bash
# 初始化脚本 - 加载配置并设置 skill / project 两个根目录
# 用法: source script/paper/init.sh
#
# 路径约定（v0.6+ 起明确区分）：
#   $PAPER_SKILL_DIR/                   ← skill 安装目录（本仓库根）
#       script/paper/                   ← 本脚本位置
#       config/api.json                 ← API 端点配置（共享）
#       reference/                      ← sqlite + 写作指南（共享）
#       modules/                        ← M0-M9 文档（共享）
#
#   $PAPER_PROJECT_DIR/                 ← 论文项目工作目录（per-paper，默认 $PWD）
#       relate-work/                    ← M1/M2 写入；manifest.jsonl 等
#       relate-work/pdf/                ← OA PDF 缓存
#       draft/                          ← M4-M6 写入
#       references.bib                  ← M2 维护
#       .env                            ← 项目级覆盖（可选；通常用 SKILL_DIR/.env）
#
# 环境变量优先级（向后兼容旧 PAPER_SKILL_ROOT）：
#   PAPER_SKILL_DIR  > PAPER_SKILL_ROOT > 脚本上两级路径
#   PAPER_PROJECT_DIR > $PWD

# Skill 安装目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -n "${PAPER_SKILL_DIR:-}" ]]; then
    : # already set
elif [[ -n "${PAPER_SKILL_ROOT:-}" ]]; then
    PAPER_SKILL_DIR="${PAPER_SKILL_ROOT}"  # back-compat alias
elif [[ -n "${CLAUDE_SKILL_ROOT:-}" ]]; then
    PAPER_SKILL_DIR="${CLAUDE_SKILL_ROOT}"  # legacy
else
    PAPER_SKILL_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi

# 论文项目工作目录（默认 cwd）
PAPER_PROJECT_DIR="${PAPER_PROJECT_DIR:-$PWD}"

# Back-compat: PROJECT_ROOT used to mean SKILL_DIR in old scripts
PROJECT_ROOT="${PAPER_SKILL_DIR}"

# 加载 .env：优先项目目录，其次 skill 目录（API key 通常用户级，放 skill 一份复用）
if [[ -f "$PAPER_PROJECT_DIR/.env" ]]; then
    set -a; source "$PAPER_PROJECT_DIR/.env"; set +a
elif [[ -f "$PAPER_SKILL_DIR/.env" ]]; then
    set -a; source "$PAPER_SKILL_DIR/.env"; set +a
fi

# 加载 API 配置
if [[ -f "$PAPER_SKILL_DIR/script/paper/load_config.sh" ]]; then
    source "$PAPER_SKILL_DIR/script/paper/load_config.sh"
fi

# 数据目录与工作目录（导出供其他脚本使用）
export PAPER_SKILL_DIR PAPER_PROJECT_DIR PROJECT_ROOT
export SKILL_DATA_DIR="$PAPER_SKILL_DIR/reference"
export RELATE_WORK_DIR="$PAPER_PROJECT_DIR/relate-work"

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
