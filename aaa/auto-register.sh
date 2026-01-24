#!/bin/sh
set -e

echo "=== 📝 自动注册设备信息（sl‑3000‑emmc） ==="

# 查找 profiles.json
profile=$(find openwrt/bin/targets -name profiles.json | head -n 1)

if [ -z "$profile" ]; then
    echo "❌ profiles.json 未找到（构建可能失败）"
    exit 1
fi

echo "✔ profiles.json 存在: $profile"

# 正确设备 ID
DEV_ID="sl-3000-emmc"

# 检查设备是否注册
if grep -q "\"id\": \"$DEV_ID\"" "$profile"; then
    echo "✔ 设备已注册: $DEV_ID"
else
    echo "❌ 设备未注册: $DEV_ID"
    echo "❌ 请检查 DTS / MK / CONFIG 是否正确生成"
    exit 1
fi

echo "=== ✔ 自动注册完成 ==="
