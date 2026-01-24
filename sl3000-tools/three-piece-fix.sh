#!/bin/sh
set -e

echo "=== 🔧 自动修复三件套 ==="

DEV="sl-3000-emmc"

# 修复 CONFIG
if ! grep -q "CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_${DEV}=y" .config; then
    echo "⚠️ 修复 CONFIG 设备启用"
    echo "CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_${DEV}=y" >> .config
fi

# 修复 MK
if ! grep -q "Device/${DEV}" target/linux/mediatek/image/filogic.mk; then
    echo "⚠️ MK 缺失设备段，重新生成"
    sh generate-three-piece.sh
fi

# 修复 DTS
if ! grep -q 'compatible = "sl,3000-emmc"' target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts; then
    echo "⚠️ 修复 DTS compatible"
    sed -i 's/compatible.*/compatible = "sl,3000-emmc", "mediatek,mt7981";/' \
        target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts
fi

echo "=== ✔ 自动修复完成 ==="
