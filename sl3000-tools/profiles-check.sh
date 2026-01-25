#!/bin/bash
set -e

#########################################
# SL3000 Profile 一致性检查（旗舰版）
# - 校验 filogic.mk 中的设备定义
# - 校验 .config 中的设备选择
# - 确保 profile 与三件套一致
#########################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

MK_FILE="$REPO_ROOT/target/linux/mediatek/image/filogic.mk"
CFG_FILE="$REPO_ROOT/.config"

DEVICE_ID="mt7981b-sl3000-emmc"
DEVICE_CFG="CONFIG_TARGET_mediatek_filogic_DEVICE_${DEVICE_ID}=y"

echo "=== 🔍 SL3000 Profile 一致性检查（旗舰版） ==="

if [ ! -f "$MK_FILE" ]; then
    echo "ERROR: 找不到 filogic.mk：$MK_FILE"
    exit 1
fi

if [ ! -f "$CFG_FILE" ]; then
    echo "ERROR: 找不到 .config：$CFG_FILE"
    exit 1
fi

echo "--- 检查 filogic.mk 中的设备定义 ---"
grep -q "Device/${DEVICE_ID}" "$MK_FILE"
grep -q "TARGET_DEVICES \+= ${DEVICE_ID}" "$MK_FILE"
echo "✔ filogic.mk 中已存在 Device/${DEVICE_ID} 且已加入 TARGET_DEVICES"

echo "--- 检查 .config 中的设备选择 ---"
grep -q "^${DEVICE_CFG}$" "$CFG_FILE"
echo "✔ .config 中已选择 ${DEVICE_CFG}"

echo "=== ✅ Profile 一致性检查通过（MK / .config / 三件套 对齐） ==="
