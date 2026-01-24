#!/bin/sh
set -e

file="target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts"

echo "=== 🔧 自动修复 DTS（sl‑3000‑emmc） ==="

ensure() {
    key="$1"
    if ! grep -q "$key" "$file"; then
        echo "    $key" >> "$file"
        echo "补齐: $key"
    fi
}

# -----------------------------
# 基础信息
# -----------------------------
ensure 'compatible = "sl,3000-emmc";'
ensure 'model = "SL 3000 eMMC Router";'

# -----------------------------
# chosen 节点（bootargs）
# -----------------------------
ensure 'chosen {'
ensure '    bootargs = "console=ttyS0,115200n8";'
ensure '};'

# -----------------------------
# memory 节点
# -----------------------------
ensure 'memory@40000000 {'
ensure '    device_type = "memory";'
ensure '    reg = <0x40000000 0x40000000>;'
ensure '};'

# -----------------------------
# LED 节点
# -----------------------------
ensure 'leds {'
ensure '    compatible = "gpio-leds";'
ensure '};'

# -----------------------------
# 按键节点
# -----------------------------
ensure 'keys {'
ensure '    compatible = "gpio-keys";'
ensure '};'

# -----------------------------
# WiFi 节点（7981）
# -----------------------------
ensure '&wifi {'
ensure '    status = "okay";'
ensure '};'

# -----------------------------
# Ethernet 节点
# -----------------------------
ensure '&eth {'
ensure '    status = "okay";'
ensure '};'

# -----------------------------
# eMMC 分区（最关键）
# -----------------------------
ensure '&mmc0 {'
ensure '    status = "okay";'
ensure '};'

echo "✔ DTS 自动修复完成（已补齐 sl‑3000‑emmc 必要节点）"
