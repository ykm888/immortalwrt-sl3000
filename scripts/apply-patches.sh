#!/bin/bash
set -e

PATCH_DIR="$1"

if [ ! -d "$PATCH_DIR" ]; then
  echo "⚠️ 无 patches 目录，跳过补丁应用"
  exit 0
fi

echo "=== 应用补丁开始 ==="

for p in "$PATCH_DIR"/*; do
  if [[ "$p" == *"mediatek"* || "$p" == *"network"* ]]; then
    echo "应用补丁: $p"
    patch -p1 < "$p"
  else
    echo "跳过非路由器补丁: $p"
  fi
done

echo "=== 应用补丁结束 ==="
