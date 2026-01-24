#!/bin/sh
set -e

echo "=== 🔍 检查 profiles.json 是否包含 SL3000 ==="

PROFILE="../openwrt/bin/targets/mediatek/filogic/profiles.json"

if [ ! -f "$PROFILE" ]; then
    echo "❌ profiles.json 不存在（构建失败或未生成固件）"
    exit 1
fi

if grep -q "mt7981b-sl3000-emmc" "$PROFILE"; then
    echo "✔ 设备已注册，固件会生成"
else
    echo "❌ 设备未注册（固件不会生成）"
    exit 1
fi
