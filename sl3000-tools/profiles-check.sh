#!/bin/sh
set -e

echo "=== 🔍 profiles.json 设备注册检查 ==="

# 查找 profiles.json 文件
profile=$(find openwrt/bin/targets -name profiles.json | head -n 1)

if [ -z "$profile" ]; then
    echo "❌ profiles.json 未找到"
    exit 1
fi

echo "✔ profiles.json 存在: $profile"

# 检查设备 ID 是否注册
if grep -q '"id": "sl-3000-emmc"' "$profile"; then
    echo "✔ 设备已注册 (sl-3000-emmc)"
else
    echo "❌ 设备未注册 (sl-3000-emmc)"
    exit 1
fi

echo "=== ✅ profiles.json 检查完成 ==="
