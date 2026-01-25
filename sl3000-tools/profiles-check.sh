#!/bin/bash
set -e

#########################################
# SL3000 profiles.json 校验脚本（最终版）
#########################################

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$ROOT_DIR/.."

PROFILES="$REPO_ROOT/bin/targets/mediatek/filogic/profiles.json"

echo "=== 🔍 检查 profiles.json ==="

if [ ! -f "$PROFILES" ]; then
    echo "❌ 未找到 profiles.json：$PROFILES"
    exit 1
fi

grep -q "mt7981b-sl3000-emmc" "$PROFILES" \
    && echo "✔ 找到 SL3000 设备条目" \
    || { echo "❌ profiles.json 中缺少 SL3000"; exit 1; }

echo "=== 🎉 profiles.json 校验通过 ==="
