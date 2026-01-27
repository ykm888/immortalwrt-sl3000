#!/bin/bash
set -euo pipefail

ROOT="$(pwd)"
SCRIPT_DIR="$ROOT/sl3000-tools"
LOG="$SCRIPT_DIR/sl3000-three-piece.log"
mkdir -p "$SCRIPT_DIR"
: > "$LOG"
exec > >(tee -a "$LOG") 2>&1

TAB=$'\t'

DTS_DIR="$ROOT/target/linux/mediatek/dts"
DTS="$DTS_DIR/mt7981b-sl-3000-emmc.dts"
MK="$ROOT/target/linux/mediatek/image/mt7981.mk"
CFG="$SCRIPT_DIR/sl3000-full-config.txt"

mkdir -p "$DTS_DIR"

###############################################
# Stage 1：生成 DTS
###############################################
echo "=== Stage 1: Generate DTS ==="

cat > "$DTS" << 'EOF'
/* SPDX-License-Identifier: GPL-2.0-or-later OR MIT */
/dts-v1/;

#include "mt7981.dtsi"
#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/leds/common.h>

/ {
    model = "SL SL3000 eMMC Engineering Flagship Edition";
    compatible = "sl,sl3000-emmc", "mediatek,mt7981b";
};
EOF

###############################################
# Stage 2：生成 / 追加 MK（对齐 CI）
###############################################
echo "=== Stage 2: Ensure MK device ==="

if ! grep -q "Device/sl-3000-emmc" "$MK"; then
  cat >> "$MK" << EOF

define Device/sl-3000-emmc
${TAB}DEVICE_VENDOR := SL
${TAB}DEVICE_MODEL := SL3000 eMMC Engineering Flagship Edition
${TAB}DEVICE_DTS := mt7981b-sl-3000-emmc
${TAB}DEVICE_PACKAGES := kmod-fs-ext4 block-mount
${TAB}IMAGES := sysupgrade.bin
${TAB}IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += sl-3000-emmc
EOF
fi

###############################################
# Stage 3：生成 CONFIG
###############################################
echo "=== Stage 3: Generate CONFIG ==="

cat > "$CFG" << 'EOF'
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_mt7981b-sl-3000-emmc=y

CONFIG_TARGET_ROOTFS_SQUASHFS=y
CONFIG_TARGET_IMAGES_GZIP=y

CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y

CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_block-mount=y
EOF

###############################################
# Stage 4：校验
###############################################
echo "=== Stage 4: Validation ==="

[ -s "$DTS" ] || { echo "[FATAL] DTS missing"; exit 1; }
[ -s "$MK" ]  || { echo "[FATAL] MK missing"; exit 1; }
[ -s "$CFG" ] || { echo "[FATAL] CONFIG missing"; exit 1; }

echo "=== Three-piece generation complete ==="
echo "[OUT] DTS: $DTS"
echo "[OUT] MK : $MK"
echo "[OUT] CFG: $CFG"
