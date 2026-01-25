#!/bin/bash
set -e

#########################################
# SL3000 profiles.json 校验脚本（最终版）
#########################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 自动查找 profiles.json（最稳妥，不依赖固定路径）
PROFILES="$(find "$REPO_ROOT/bin/targets" -name profiles.json | head -n 1)"

echo "=== 🔍 检查 profiles.json ==="

if [ -z "$PROFILES" ]; then
    echo "❌ 未找到 profiles.json（构建可能失败或未生成固件）"
    exit 1
fi

echo "✔ 找到 profiles.json：$PROFILES"

# 校验设备 ID（与 DTS/MK/.config 完全一致）
if grep -q '"id": "mt7981b-sl3000-emmc"' "$PROFILES"; then
    echo "✔ 找到 SL3000 设备条目 (mt7981b-sl3000-emmc)"
else
    echo "❌ profiles.json 中缺少 SL3000 设备条目 (mt7981b-sl3000-emmc)"
    exit 1
fi

echo "=== 🎉 profiles.json 校验通过 ==="
