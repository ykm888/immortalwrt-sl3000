#!/bin/bash
set -euo pipefail

ROOT="$(pwd)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

LOG="$SCRIPT_DIR/sl3000-three-piece.log"
mkdir -p "$SCRIPT_DIR"
: > "$LOG"
exec > >(tee -a "$LOG") 2>&1

echo "=== SL3000 three-piece generation start ==="
echo "[ROOT]       $ROOT"
echo "[SCRIPT_DIR] $SCRIPT_DIR"
echo

##################################
# 1. DTS
##################################
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

	memory@40000000 {
		reg = <0 0x40000000 0 0x40000000>;
	};
};
EOF

echo "[DTS] generated: $DTS"
echo

##################################
# 2. MK
##################################
IMAGE_DIR="$ROOT/target/linux/mediatek/image"
MK="$IMAGE_DIR/filogic.mk"

if [ ! -f "$MK" ]; then
  echo "FATAL: $MK not found"
  exit 1
fi

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
# 3. CONFIG
##################################
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
[ -s "$DTS" ] || { echo "FATAL: DTS missing"; exit 1; }
[ -s "$MK" ]  || { echo "FATAL: MK missing"; exit 1; }
[ -s "$CFG" ] || { echo "FATAL: .config missing"; exit 1; }

echo "=== SL3000 three-piece generation complete ==="
echo "[OUT] DTS : $DTS"
echo "[OUT] MK  : $MK"
echo "[OUT] CFG : $CFG"
