#!/bin/sh
set -e

echo "=== 📝 自动注册设备信息 ==="

profile=$(find openwrt/bin/targets -name profiles.json | head -n 1)

if [ -z "$profile" ]; then
    echo "❌ profiles.json 未找到"
    exit 1
fi

echo "✔ profiles.json 存在"

if grep -q "sl3000-emmc" "$profile"; then
    echo "✔ 设备已注册"
else
    echo "❌ 设备未注册"
    exit 1
fi

echo "=== ✔ 自动注册完成 ==="
