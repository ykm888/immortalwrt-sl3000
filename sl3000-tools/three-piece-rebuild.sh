#!/bin/sh
set -e

echo "=== 🔄 重建三件套 ==="

rm -f target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts
rm -f target/linux/mediatek/image/filogic.mk
rm -f .config

sh sl3000-tools/generate-three-piece.sh

echo "=== ✔ 三件套已重建 ==="
