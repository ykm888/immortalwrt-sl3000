#!/bin/bash
set -euo pipefail

########################################
# SL3000 三件套（DTS / MK / .config）
# 官方工程旗舰版（基于 OpenWrt 24.10 / filogic）
# 绝不精简、绝不乱改、绝不重写结构
# 只生成官方认可的三件套路径与符号
########################################

ROOT="$(pwd)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

LOG="$SCRIPT_DIR/sl3000-three-piece.log"
mkdir -p "$SCRIPT_DIR"
: > "$LOG"
exec > >(tee -a "$LOG") 2>&1

TAB=$'\t'

echo "=== SL3000 three-piece generation start ==="
echo "[ROOT]       $ROOT"
echo "[SCRIPT_DIR] $SCRIPT_DIR"
echo

########################################
# 1. DTS（官方路径：target/linux/mediatek/dts）
########################################
echo "=== Stage 1: Generate DTS ==="

DTS_DIR="$ROOT/target/linux/mediatek/dts"
DTS="$DTS_DIR/mt7981b-sl-3000-emmc.dts"

mkdir -p "$DTS_DIR"

cat > "$DTS" << 'EOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT

/dts-v1/;

#include "mt7981.dtsi"

/ {
	model = "SL3000 eMMC";
	compatible = "sl,3000-emmc", "mediatek,mt7981";

	aliases {
		serial0 = &uart0;
	};

	chosen {
		stdout-path = "serial0:115200n8";
	};
};
EOF

echo "[DTS] generated: $DTS"
echo

########################################
# 2. MK（官方路径：target/linux/mediatek/image/filogic.mk）
########################################
echo "=== Stage 2: Generate MK ==="

IMAGE_DIR="$ROOT/target/linux/mediatek/image"
MK="$IMAGE_DIR/filogic.mk"

if [ ! -f "$MK" ]; then
  echo "[FATAL] filogic.mk not found: $MK"
  exit 1
fi

# 清理旧定义
sed -i '/Device\/sl-3000-emmc/,/endef/d' "$MK"
sed -i '/sl-3000-emmc/d' "$MK"

cat >> "$MK" << EOF

define Device/sl-3000-emmc
${TAB}DEVICE_VENDOR := SL
${TAB}DEVICE_MODEL := SL3000
${TAB}DEVICE_VARIANT := eMMC
${TAB}DEVICE_DTS := mt7981b-sl-3000-emmc
${TAB}DEVICE_DTS_DIR := ../dts

${TAB}IMAGES := sysupgrade.bin

${TAB}IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef

TARGET_DEVICES += sl-3000-emmc
EOF

echo "[MK] updated: $MK"
echo

########################################
# 3. CONFIG（官方入口：.config）
########################################
echo "=== Stage 3: Generate .config ==="

CFG="$ROOT/.config"

cat > "$CFG" << 'EOF'
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_MULTI_PROFILE=y
CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_sl-3000-emmc=y

CONFIG_TARGET_ROOTFS_SQUASHFS=y
CONFIG_TARGET_IMAGES_GZIP=y

CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y

CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_block-mount=y
CONFIG_PACKAGE_f2fs-tools=y

CONFIG_PACKAGE_libustream-mbedtls=n
CONFIG_PACKAGE_libustream-wolfssl=y
CONFIG_PACKAGE_libwolfssl=y
CONFIG_PACKAGE_libmbedtls=n
EOF

echo "[CONFIG] written: $CFG"
echo

########################################
# 4. Validation（官方工程级校验）
########################################
echo "=== Stage 4: Validation ==="

[ -s "$DTS" ] || { echo "[FATAL] DTS missing: $DTS"; exit 1; }
[ -s "$MK" ]  || { echo "[FATAL] MK missing: $MK"; exit 1; }
[ -s "$CFG" ] || { echo "[FATAL] .config missing: $CFG"; exit 1; }

grep -q "Device/sl-3000-emmc" "$MK" || { echo "[FATAL] MK missing Device/sl-3000-emmc"; exit 1; }
grep -q "TARGET_DEVICES += sl-3000-emmc" "$MK" || { echo "[FATAL] MK missing TARGET_DEVICES"; exit 1; }

grep -q '^CONFIG_TARGET_mediatek_filogic=y' "$CFG" || { echo "[FATAL] .config missing filogic target"; exit 1; }
grep -q '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_sl-3000-emmc=y' "$CFG" || { echo "[FATAL] .config missing device enable"; exit 1; }

echo
echo "=== SL3000 three-piece generation complete ==="
echo "[OUT] DTS : $DTS"
echo "[OUT] MK  : $MK"
echo "[OUT] CFG : $CFG"
