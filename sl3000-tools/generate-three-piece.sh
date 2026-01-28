#!/bin/bash
set -euo pipefail

# 关键：校验是否在源码根目录运行（必加）
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
echo "[SCRIPT_DIR] $SCRIPT_DIR"
echo

############################
# 1. DTS → target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts
############################
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
		device_type = "memory";
		reg = <0x0 0x40000000 0x0 0x40000000>;
	};
};
EOF

echo "[DTS] generated: $DTS"
echo

############################
# 2. MK → target/linux/mediatek/image/filogic.mk
############################
IMAGE_DIR="$ROOT/target/linux/mediatek/image"
MK="$IMAGE_DIR/filogic.mk"

if [ ! -f "$MK" ]; then
  echo "FATAL: $MK not found"
  exit 1
fi

# 删除旧设备段（匹配 sl_3000-emmc）
grep -q "Device/sl_3000-emmc" "$MK" && sed -i '/Device\/sl_3000-emmc/,/endef/d' "$MK"
grep -q "TARGET_DEVICES += sl3000-emmc" "$MK" && sed -i '/TARGET_DEVICES += sl3000-emmc/d' "$MK"

# 追加新设备段（延续别人成功案例格式）
cat >> "$MK" << 'EOF'

define Device/sl_3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 eMMC
  DEVICE_DTS := mt7981b-sl-3000-emmc
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware automount coremark blkid blockdev fdisk f2fsck mkf2fs kmod-mmc
  KERNEL := kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef

TARGET_DEVICES += sl3000-emmc
EOF

echo "[MK] updated: $MK"
echo

############################
# 3. CONFIG → 源码根目录 .config
############################
CFG="$ROOT/.config"

cat > "$CFG" << 'EOF'
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_mt7981=y
CONFIG_TARGET_MULTI_PROFILE=y

CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_sl_3000-emmc=y

CONFIG_TARGET_ROOTFS_SQUASHFS=y
CONFIG_TARGET_IMAGES_GZIP=y

CONFIG_PACKAGE_kmod-mt7915e=y
CONFIG_PACKAGE_kmod-mt7981-firmware=y
CONFIG_PACKAGE_mt7981-wo-firmware=y
CONFIG_PACKAGE_kmod-mmc=y

CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
EOF

echo "[CONFIG] written: $CFG"
echo

############################
# 4. 增强校验（精准路径+内容+唯一性）
############################
[ -s "$DTS" ] || { echo "FATAL: DTS文件为空或缺失"; exit 1; }
[ -s "$MK" ]  || { echo "FATAL: MK文件为空或缺失"; exit 1; }
[ -s "$CFG" ] || { echo "FATAL: .config文件为空或缺失"; exit 1; }

grep -q "define Device/sl_3000-emmc" "$MK" \
  || { echo "FATAL: MK中未成功添加设备段"; exit 1; }

grep -q "TARGET_DEVICES += sl3000-emmc" "$MK" \
  || { echo "FATAL: MK中未添加 TARGET_DEVICES"; exit 1; }

grep -q '^CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_sl_3000-emmc=y' "$CFG" \
  || { echo "FATAL: .config 中设备未启用"; exit 1; }

MKSEGCOUNT=$(grep -c "define Device/sl_3000-emmc" "$MK")
if [ "$MKSEGCOUNT" -ne 1 ]; then
  echo "FATAL: MK 有 $MKSEGCOUNT 个 sl_3000-emmc 设备段（预期 1 个）"
  exit 1
fi

echo "=== SL3000 three-piece generation complete ==="
echo "[OUT] DTS : $DTS"
echo "[OUT] MK  : $MK"
echo "[OUT] CFG : $CFG"
echo "[SUCCESS]"
