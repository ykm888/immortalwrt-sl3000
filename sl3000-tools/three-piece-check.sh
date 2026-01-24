#!/bin/sh
set -e

echo "=== 🔍 检查 SL3000 三件套（24.10） ==="

DTS="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
MK="target/linux/mediatek/image/filogic.mk"
CONF=".config"

[ -f "$DTS" ] || { echo "❌ DTS 缺失"; exit 1; }
[ -f "$MK" ]  || { echo "❌ MK 缺失"; exit 1; }
[ -f "$CONF" ] || { echo "❌ CONFIG 缺失"; exit 1; }

echo "✔ 三件套存在且路径正确"
