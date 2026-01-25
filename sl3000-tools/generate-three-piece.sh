#!/bin/bash
set -e

#########################################
# SL3000 三件套重建脚本（最终版）
# - 生成三件套
# - 三件套自检
# - all-in-one.sh check
#########################################

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== ♻ 重建 SL3000 三件套（24.10） ==="

# 1. 生成三件套
echo "=== 🧬 生成三件套 ==="
chmod +x "$ROOT_DIR/generate-three-piece.sh"
"$ROOT_DIR/generate-three-piece.sh"

# 2. 三件套自检
echo "=== 🔍 三件套自检 ==="
chmod +x "$ROOT_DIR/three-piece-check.sh"
"$ROOT_DIR/three-piece-check.sh"

# 3. all-in-one.sh 语法与环境检查
echo "=== 🔍 all-in-one.sh CHECK ==="
chmod +x "$ROOT_DIR/all-in-one.sh"
"$ROOT_DIR/all-in-one.sh" check

echo "=== ✅ 三件套重建完成（未构建固件） ==="
