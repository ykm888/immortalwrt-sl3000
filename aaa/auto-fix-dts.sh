#!/bin/sh
set -e

file="target/linux/mediatek/dts/mt7981b-sl3000-emmc.dts"

echo "=== 🔧 自动修复 DTS ==="

ensure() {
    key="$1"
    if ! grep -q "$key" "$file"; then
        echo "    $key" >> "$file"
        echo "补齐: $key"
    fi
}

ensure 'compatible = "sl3000-emmc";'
ensure 'model = "SL3000 EMMC Router";'

echo "✔ DTS 自动修复完成"
