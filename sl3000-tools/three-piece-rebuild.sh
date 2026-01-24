#!/bin/sh
set -e

echo "=== ♻ 重建 SL3000 三件套（24.10） ==="

rm -f target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts
rm -f target/linux/mediatek/image/filogic.mk
rm -f .config

sh sl3000-tools/generate-three-piece.sh

echo "✔ 三件套重建完成"
