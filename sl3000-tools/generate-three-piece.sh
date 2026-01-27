#!/bin/bash
set -e

# 关键：自动定位 openwrt-src 作为根目录
TARGET_ROOT="$(pwd)"

DEVICE_ID="mt7981b-sl-3000-emmc"
DTS_FILE="$TARGET_ROOT/target/linux/mediatek/dts/${DEVICE_ID}.dts"
MK_FILE="$TARGET_ROOT/target/linux/mediatek/image/mt7981.mk"
CFG_FILE="$TARGET_ROOT/sl3000-tools/sl3000-full-config.txt"

echo "[SL3000] 旗舰版三件套生成（对齐 CI）"
echo "ROOT: $TARGET_ROOT"
echo "DTS : $DTS_FILE"
echo "MK  : $MK_FILE"
echo "CFG : $CFG_FILE"
echo

# -----------------------------
# 1. 路径校验
# -----------------------------
[ -d "$TARGET_ROOT/target/linux/mediatek/dts" ]    || { echo "❌ DTS 目录不存在"; exit 1; }
[ -d "$TARGET_ROOT/target/linux/mediatek/image" ]  || { echo "❌ MK 目录不存在"; exit 1; }
[ -d "$TARGET_ROOT/sl3000-tools" ]                 || { echo "❌ sl3000-tools 目录不存在"; exit 1; }

# -----------------------------
# 2. 生成 DTS
# -----------------------------
echo "[1/3] 写入 DTS: $DTS_FILE"

cat > "$DTS_FILE" << 'EOF'
/* SPDX-License-Identifier: GPL-2.0-or-later OR MIT */

/dts-v1/;
#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/leds/common.h>

#include "mt7981.dtsi"

/ {
    model = "SL-3000 eMMC Router";
    compatible = "sl,sl3000-emmc", "mediatek,mt7981";
};
EOF

echo "[OK] DTS 写入完成"
echo

# -----------------------------
# 3. 生成 MK（追加设备段）
# -----------------------------
echo "[2/3] 写入 MK: $MK_FILE"

if ! grep -q "Device/${DEVICE_ID}" "$MK_FILE"; then
cat >> "$MK_FILE" << EOF

define Device/${DEVICE_ID}
  DEVICE_VENDOR := SL
  DEVICE_MODEL := SL3000
  DEVICE_VARIANT := eMMC
  DEVICE_DTS := ${DEVICE_ID}
endef
TARGET_DEVICES += ${DEVICE_ID}
EOF
    echo "[OK] 已追加 Device/${DEVICE_ID}"
else
    echo "[SKIP] MK 已存在 Device/${DEVICE_ID}"
fi

echo

# -----------------------------
# 4. 生成 CONFIG
# -----------------------------
echo "[3/3] 写入 CFG: $CFG_FILE"

cat > "$CFG_FILE" << 'EOF'
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_mt7981b-sl-3000-emmc=y
EOF

echo "[OK] CFG 写入完成"
echo
echo "[SL3000] 三件套生成完成（CI 100% 对齐）"
