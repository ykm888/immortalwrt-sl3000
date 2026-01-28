#!/bin/bash
set -euo pipefail

关键：校验是否在源码根目录运行（必加）
if [ ! -d "target/linux/mediatek" ]; then
    echo "FATAL: 请在ImmortalWrt/OpenWrt源码根目录执行此脚本！"
    exit 1
fi

ROOT="$(pwd)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

LOG="$SCRIPT_DIR/sl3000-three-piece.log"
: > "$LOG"
exec > >(tee -a "$LOG") 2>&1

echo "=== SL3000 three-piece generation start ==="
echo "[ROOT]       $ROOT"
echo "[SCRIPTDIR] $SCRIPTDIR"
echo

############################

1. DTS → target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts

############################
DTS_DIR="$ROOT/target/linux/mediatek/dts"
DTS="$DTS_DIR/mt7981b-sl-3000-emmc.dts"
mkdir -p "$DTS_DIR"

cat > "$DTS" << 'EOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT
/dts-v1/;

include <dt-bindings/gpio/gpio.h>

include <dt-bindings/input/input.h>

include <dt-bindings/leds/common.h>

include "mt7981.dtsi"
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

############################

2. MK → target/linux/mediatek/image/filogic.mk

############################
IMAGE_DIR="$ROOT/target/linux/mediatek/image"
MK="$IMAGE_DIR/filogic.mk"

if [ ! -f "$MK" ]; then
  echo "FATAL: $MK not found"
  exit 1
fi

健壮删除：匹配块存在才删除，避免set -e中断
grep -q "Device/sl3000-emmc" "$MK" && sed -i '/Device\/sl3000-emmc/,/endef/d' "$MK"
grep -q "TARGETDEVICES += sl3000-emmc" "$MK" && sed -i '/TARGETDEVICES += sl3000-emmc/d' "$MK"

设备间空行+官方TARGET_DEVICES+精准路径追加
cat >> "$MK" << 'EOF'

define Device/sl_3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 eMMC
  DEVICE_DTS := mt7981b-sl-3000-emmc
  DEVICEDTSDIR := ../dts
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware automount coremark blkid blockdev fdisk f2fsck mkf2fs kmod-mmc
  KERNEL := kernel-bin | lzma | fit lzma $(KDIR)/image-$(firstword $(DEVICE_DTS)).dtb
  KERNELINITRAMFS := kernel-bin | lzma | fit lzma $(KDIR)/image-$(firstword $(DEVICEDTS)).dtb with-initrd | pad-to 64k
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGETDEVICES += sl3000-emmc
EOF

echo "[MK] updated: $MK"
echo

############################

3. CONFIG → 源码根目录 .config

############################
CFG="$ROOT/.config"

cat > "$CFG" << 'EOF'
CONFIGTARGETmediatek=y
CONFIGTARGETmediatek_mt7981=y
CONFIGTARGETMULTI_PROFILE=y
CONFIGTARGETDEVICEmediatekmt7981DEVICEsl_3000-emmc=y
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

############################

4. 增强校验（精准路径+内容+唯一性）

############################
[ -s "$DTS" ] || { echo "FATAL: DTS文件为空或缺失"; exit 1; }
[ -s "$MK" ]  || { echo "FATAL: MK文件为空或缺失"; exit 1; }
[ -s "$CFG" ] || { echo "FATAL: .config文件为空或缺失"; exit 1; }
grep -q "define Device/sl_3000-emmc" "$MK" || { echo "FATAL: MK中未成功添加设备段"; exit 1; }
grep -q "TARGETDEVICES += sl3000-emmc" "$MK" || { echo "FATAL: MK中未添加TARGET_DEVICES"; exit 1; }
grep -q "CONFIGTARGETDEVICEmediatekmt7981DEVICEsl_3000-emmc=y" "$CFG" || { echo "FATAL: .config中设备未启用"; exit 1; }

校验MK设备段唯一
MKSEGCOUNT=$(grep -c "define Device/sl_3000-emmc" "$MK")
if [ $MKSEGCOUNT -ne 1 ]; then
  echo "FATAL: MK有$MKSEGCOUNT个sl_3000-emmc设备段（预期1个）"
  exit 1
fi

echo "=== SL3000 three-piece generation complete ==="
echo "[OUT] DTS : $DTS"
echo "[OUT] MK  : $MK"
echo "[OUT] CFG : $CFG"
echo "[SUCCESS]
