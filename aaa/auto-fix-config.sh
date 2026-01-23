#!/bin/sh
set -e

echo "=== 🔧 自动修复 config ==="

fix() {
    key="$1"
    val="$2"
    if ! grep -q "^$key=" .config; then
        echo "$key=$val" >> .config
        echo "补齐: $key"
    fi
}

fix CONFIG_TARGET_mediatek y
fix CONFIG_TARGET_mediatek_filogic y
fix CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc y
fix CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_sl3000-emmc y
fix CONFIG_LINUX_6_6 y

echo "✔ config 自动修复完成"
