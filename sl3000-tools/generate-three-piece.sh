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
# Stage 1：生成 DTS（延续成功案例）
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
    model = "SL-3000 eMMC bootstrap versions";
    compatible = "sl,3000-emmc", "mediatek,mt7981";
};
EOF

###############################################
# Stage 2：生成 / 追加 MK（严格对齐成功案例）
###############################################
echo "=== Stage 2: Ensure MK device ==="

if ! grep -q "Device/sl-3000-emmc" "$MK"; then
  cat >> "$MK" << EOF

define Device/sl-3000-emmc
${TAB}DEVICE_VENDOR := SL
${TAB}DEVICE_MODEL := SL3000
${TAB}DEVICE_VARIANT := eMMC
${TAB}DEVICE_DTS := mt7981b-sl-3000-emmc
${TAB}DEVICE_DTS_DIR := ../dts
${TAB}DEVICE_PACKAGES := kmod-usb3 kmod-fs-ext4 block-mount f2fs-tools \
        luci luci-base luci-i18n-base-zh-cn \
        luci-app-eqos-mtk luci-app-mtwifi-cfg luci-app-turboacc-mtk luci-app-wrtbwmon
${TAB}IMAGES := sysupgrade.bin
${TAB}IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
${TAB}IMAGE/initramfs.bin := append-dtb | uImage | append-metadata
endef
TARGET_DEVICES += sl-3000-emmc
EOF
fi

###############################################
# Stage 3：生成 CONFIG（参考 ax3000 defconfig）
###############################################
echo "=== Stage 3: Generate CONFIG ==="

cat > "$CFG" << 'EOF'
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_mt7981=y
CONFIG_TARGET_MULTI_PROFILE=y
CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_sl-3000-emmc=y

# 镜像格式
CONFIG_TARGET_ROOTFS_INITRAMFS=y
CONFIG_TARGET_ROOTFS_SQUASHFS=y
CONFIG_TARGET_IMAGES_GZIP=y

# LuCI 基础
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y

# 存储支持
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_block-mount=y
CONFIG_PACKAGE_f2fs-tools=y

# MTK 扩展应用
CONFIG_PACKAGE_luci-app-eqos-mtk=y
CONFIG_PACKAGE_luci-app-mtwifi-cfg=y
CONFIG_PACKAGE_luci-app-turboacc-mtk=y
CONFIG_PACKAGE_luci-app-wrtbwmon=y
EOF

###############################################
# Stage 4：校验
###############################################
echo "=== Stage 4: Validation ==="

[ -s "$DTS" ] || { echo "[FATAL] DTS missing"; exit 1; }
[ -s "$MK" ]  || { echo "[FATAL] MK missing"; exit 1; }
[ -s "$CFG" ] || { echo "[FATAL] CONFIG missing"; exit 1; }

echo "=== Three-piece generation complete (24.10 / 6.6) ==="
echo "[OUT] DTS: $DTS"
echo "[OUT] MK : $MK"
echo "[OUT] CFG: $CFG"
