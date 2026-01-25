#!/bin/bash
set -e

#########################################
# SL3000 三件套一致性检查脚本（最终版）
#########################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DTS="$REPO_ROOT/target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
MK="$REPO_ROOT/target/linux/mediatek/image/filogic.mk"
CFG="$REPO_ROOT/.config"

check_exist() {
    [ -f "$1" ] || { echo "❌ 缺少文件：$1"; exit 1; }
}

echo "=== 🔍 检查三件套是否存在 ==="
check_exist "$DTS"
check_exist "$MK"
check_exist "$CFG"
echo "✔ 三件套文件存在"

echo "=== 🔍 DTS 检查 ==="
grep -q "mt7981.dtsi" "$DTS" \
    || { echo "❌ DTS 未包含 mt7981.dtsi"; exit 1; }
grep -q "compatible" "$DTS" \
    || { echo "❌ DTS 未包含 compatible 字段"; exit 1; }
grep -q "sl3000-emmc" "$DTS" \
    || { echo "❌ DTS 未包含 sl3000-emmc 设备名"; exit 1; }
echo "✔ DTS 正常"

echo "=== 🔍 MK 检查 ==="
grep -q "Device/mt7981b-sl3000-emmc" "$MK" \
    || { echo "❌ MK 未定义 Device/mt7981b-sl3000-emmc"; exit 1; }
grep -q "TARGET_DEVICES" "$MK" \
    || { echo "❌ MK 未包含 TARGET_DEVICES"; exit 1; }
echo "✔ MK 正常"

echo "=== 🔍 CONFIG 检查 ==="
grep -q "CONFIG_TARGET_mediatek_filogic=y" "$CFG" \
    || { echo "❌ CONFIG 未启用 mediatek_filogic"; exit 1; }
grep -q "CONFIG_TARGET_mediatek_filogic_DEVICE_mt7981b-sl3000-emmc=y" "$CFG" \
    || { echo "❌ CONFIG 未启用 SL3000 设备"; exit 1; }
grep -q "CONFIG_LINUX_6_6=y" "$CFG" \
    || { echo "❌ CONFIG 未启用 Linux 6.6"; exit 1; }
echo "✔ CONFIG 正常"

echo "=== 🎉 三件套检查通过 ==="
