#!/bin/bash
set -euo pipefail

##################################
# SL3000 三件套（DTS / MK / CONFIG）
# 基于别人仓库成功案例（mt7981 平台 + FIT）
# 内存：1GB
# 设备名：sl_3000-emmc
##################################

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

##################################
# 1. DTS（别人仓库成功案例）
##################################
echo "=== Stage 1: Generate DTS ==="

DTS_DIR="$ROOT/target/linux/mediatek/dts"
DTS="$DTS_DIR/mt7981b-sl-3000-emmc.dts"

mkdir -p "$DTS_DIR"

cat > "$DTS" << 'EOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT

/dts-v1/;

#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/leds/common.h>

#include "mt7981.dtsi"

/ {
	model = "SL-3000 eMMC bootstrap versions";
	compatible = "sl,3000-emmc", "mediatek,mt7981";

	aliases {
		serial0 = &uart0;
		led-boot = &statusredled;
		led-failsafe = &statusredled;
		led-running = &statusgreenled;
		led-upgrade = &statusblueled;
	};

	chosen {
		bootargs = "root=PARTLABEL=rootfs rootwait";
		stdout-path = "serial0:115200n8";
	};

	/* 1GB RAM */
	memory@40000000 {
		reg = <0 0x40000000 0 0x40000000>;
	};
};
EOF

echo "[DTS] generated: $DTS"
echo

##################################
# 2. MK（别人仓库成功案例）
##################################
echo "=== Stage 2: Generate MK ==="

IMAGE_DIR="$ROOT/target/linux/mediatek/image"
MK="$IMAGE_DIR/filogic.mk"   # 24.10 必须使用 filogic.mk

if [ ! -f "$MK" ]; then
  echo "[FATAL] filogic.mk not found: $MK"
  exit 1
fi

# 删除旧段
sed -i '/Device\/sl_3000-emmc/,/endef/d' "$MK"
sed -i '/sl_3000-emmc/d' "$MK"

cat >> "$MK" << 'EOF'

define Device/sl_3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 eMMC
  DEVICE_DTS := mt7981b-sl-3000-emmc
  DEVICEDTSDIR := ../dts
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware automount coremark blkid blockdev fdisk f2fsck mkf2fs kmod-mmc
  KERNEL := kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef

TARGETDEVICES += sl3000-emmc
EOF

echo "[MK] updated: $MK"
echo

##################################
# 3. CONFIG（别人仓库成功案例）
##################################
echo "=== Stage 3: Generate .config ==="

CFG="$ROOT/.config"

cat > "$CFG" << 'EOF'
CONFIGTARGETmediatek=y
CONFIGTARGETmediatek_mt7981=y
CONFIGTARGETMULTI_PROFILE=y

CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_sl_3000-emmc=y
CONFIGTARGETDEVICEPACKAGESmediatekmt7981DEVICEsl3000-emmc=""

CONFIGTARGETROOTFS_SQUASHFS=y
CONFIGTARGETIMAGES_GZIP=y

CONFIGPACKAGEkmod-mt7915e=y
CONFIGPACKAGEkmod-mt7981-firmware=y
CONFIGPACKAGEmt7981-wo-firmware=y
CONFIGPACKAGEkmod-mmc=y

CONFIGPACKAGEluci=y
CONFIGPACKAGEluci-base=y
CONFIGPACKAGEluci-i18n-base-zh-cn=y
EOF

echo "[CONFIG] written: $CFG"
echo

##################################
# 4. Validation
##################################
echo "=== Stage 4: Validation ==="

[ -s "$DTS" ] || { echo "[FATAL] DTS missing: $DTS"; exit 1; }
[ -s "$MK" ]  || { echo "[FATAL] MK missing: $MK"; exit 1; }
[ -s "$CFG" ] || { echo "[FATAL] .config missing: $CFG"; exit 1; }

grep -q "sl_3000-emmc" "$MK" || { echo "[FATAL] MK missing device"; exit 1; }
grep -q "CONFIGTARGETmediatek_mt7981" "$CFG" || { echo "[FATAL] CONFIG missing mt7981"; exit 1; }

echo
echo "=== SL3000 three-piece generation complete ==="
echo "[OUT] DTS : $DTS"
echo "[OUT] MK  : $MK"
echo "[OUT] CFG : $CFG"
