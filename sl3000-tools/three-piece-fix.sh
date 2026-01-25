#!/bin/bash
set -e

#########################################
# SL3000 三件套修复脚本（旗舰版）
# - 重新生成 DTS/MK/CONFIG
# - 立即跑 CHECK，确保三件套自洽
# - 不触发 make 构建
#########################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GEN_THREE="$SCRIPT_DIR/generate-three-piece.sh"
ALL_IN_ONE="$SCRIPT_DIR/all-in-one.sh"

if [ ! -x "$GEN_THREE" ]; then
    echo "ERROR: generate-three-piece.sh 不存在或不可执行：$GEN_THREE"
    exit 1
fi

if [ ! -x "$ALL_IN_ONE" ]; then
    echo "ERROR: all-in-one.sh 不存在或不可执行：$ALL_IN_ONE"
    exit 1
fi

echo "=== 🧬 重新生成三件套（DTS / MK / CONFIG） ==="
"$GEN_THREE"

echo "=== 🔍 运行三件套 CHECK（all-in-one.sh check） ==="
"$ALL_IN_ONE" check

echo "✔ 三件套修复完成（已重建 + 校验，通过）"
