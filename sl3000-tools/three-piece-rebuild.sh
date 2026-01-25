#!/bin/sh
set -e

echo "=== ♻ 重建 SL3000 三件套（24.10 / 最终版） ==="

#########################################
# 1. 删除旧三件套（路径全部对齐 6.6）
#########################################

rm -f target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts
rm -f target/linux/mediatek/image/filogic.mk
rm -f .config   # ← 已修复：删除最终标准 .config

#########################################
# 2. 重新生成三件套
#########################################

sh sl3000-tools/generate-three-piece.sh

#########################################
# 3. 完成提示
#########################################

echo "✔ 三件套重建完成（DTS / MK / .config 已全部重建）"
