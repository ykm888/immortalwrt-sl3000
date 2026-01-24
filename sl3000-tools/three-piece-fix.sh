#!/bin/sh
set -e

echo "=== 🔧 自动修复 SL3000 三件套 ==="

DTS="target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts"
MK="target/linux/mediatek/image/filogic.mk"
CONF=".config"
DEV="sl-3000-emmc"

#########################################
# 1. 修复 CONFIG
#########################################

if ! grep -q "CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_${DEV}=y" "$CONF"; then
    echo "⚠ 修复 CONFIG：设备未启用，自动补齐"
    echo "CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_${DEV}=y" >> "$CONF"
fi

#########################################
# 2. 修复 MK
#########################################

if ! grep -q "define Device/${DEV}" "$MK"; then
    echo "⚠ 修复 MK：设备段缺失，自动重建三件套"
    sh sl3000-tools/generate-three-piece.sh
fi

#########################################
# 3. 修复 DTS
#########################################

if ! grep -q 'compatible = "sl-3000-emmc"' "$DTS"; then
    echo "⚠ 修复 DTS：compatible 字段不一致，自动修复"
    sed -i 's/compatible.*/compatible = "sl-3000-emmc", "mediatek,mt7981";/' "$DTS"
fi

#########################################
# 4. 隐藏字符修复（BOM / CRLF）
#########################################

for f in "$DTS" "$MK" "$CONF"; do
    # 删除 BOM
    sed -i '1s/^\xEF\xBB\xBF//' "$f"
    # 删除 CRLF
    sed -i 's/\r$//' "$f"
done

#########################################
# 5. 最终校验
#########################################

echo "=== 🔍 修复后再次校验 ==="
sh sl3000-tools/three-piece-check.sh

echo "=== 🎉 自动修复完成 ==="
