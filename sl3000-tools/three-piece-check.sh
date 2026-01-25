#!/bin/bash
set -e

#########################################
# SL3000 三件套健康检查（旗舰版）
# - 不生成、不修改，只检查
# - 依赖 all-in-one.sh 的 CHECK 逻辑
#########################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ALL_IN_ONE="$SCRIPT_DIR/all-in-one.sh"

if [ ! -x "$ALL_IN_ONE" ]; then
    echo "ERROR: all-in-one.sh 不存在或不可执行：$ALL_IN_ONE"
    exit 1
fi

echo "=== 🔍 三件套健康检查（调用 all-in-one.sh check） ==="
"$ALL_IN_ONE" check
echo "✔ 三件套健康检查完成（无修改）"
