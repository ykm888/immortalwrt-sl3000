#!/bin/bash
set -euo pipefail

# 关键：校验是否在源码根目录运行（必加）
if [ ! -d "target/linux/mediatek" ]; then
    echo "FATAL: 请在ImmortalWrt源码根目录执行此脚本！"
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

##################################
# 1. DTS（严格对齐设备名，无语法错误）
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
# 2. MK（修复设备名拼写+健壮sed删除）
##################################
IMAGE_DIR="$ROOT/target/linux/mediatek/image"
MK="$IMAGE_DIR/filogic.mk"

if [ ! -f "$MK" ]; then
  echo "FATAL: $MK not found"
  exit 1
fi

# 健壮删除：匹配块存在才删除，避免set -e中断
grep -q "Device/sl_3000-emmc" "$MK" && sed -i '/Device\/sl_3000-emmc/,/endef/d' "$MK"
grep -q "sl_3000-emmc" "$MK" && sed -i '/sl_3000-emmc/d' "$MK"

# 设备名严格对齐：sl_3000-emmc（全程下划线）
cat >> "$MK" << 'EOF'
define Device/sl_3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 eMMC
  DEVICE_DTS := mt7981b-sl-3000-emmc
  DEVICEDTSDIR := ../dts
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware automount coremark blkid blockdev fdisk f2fsck mkf2fs kmod-mmc
  KERNEL := kernel-bin | lzma | fit lzma $(KDIR)/image-$(firstword $(DEVICE_DTS)).dtb
  KERNEL_INITRAMFS := kernel-bin | lzma | fit lzma $(KDIR)/image-$(firstword $(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGETDEVICES += sl_3000-emmc
EOF

echo "[MK] updated: $MK"
echo

##################################
# 3. CONFIG（修复所有下划线，强对齐设备名）
##################################
CFG="$ROOT/.config"

cat > "$CFG" << 'EOF'
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_mt7981=y
CONFIG_TARGET_MULTI_PROFILE=y
# 设备名严格对齐MK/DTS
CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_sl_3000-emmc=y
# 根文件系统+镜像格式
CONFIG_TARGET_ROOTFS_SQUASHFS=y
CONFIG_TARGET_IMAGES_GZIP=y
# 核心驱动（与MK的DEVICE_PACKAGES对齐，避免重复）
CONFIG_PACKAGE_kmod-mt7915e=y
CONFIG_PACKAGE_kmod-mt7981-firmware=y
CONFIG_PACKAGE_mt7981-wo-firmware=y
CONFIG_PACKAGE_kmod-mmc=y
# LuCI基础+中文
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
EOF

echo "[CONFIG] written: $CFG"
echo

##################################
# 4. 增强校验（检查文件内容+设备名一致性）
##################################
[ -s "$DTS" ] || { echo "FATAL: DTS文件为空或缺失"; exit 1; }
[ -s "$MK" ]  || { echo "FATAL: MK文件为空或缺失"; exit 1; }
[ -s "$CFG" ] || { echo "FATAL: .config文件为空或缺失"; exit 1; }
grep -q "sl_3000-emmc" "$MK" || { echo "FATAL: MK中未成功添加设备"; exit 1; }
grep -q "sl_3000-emmc" "$CFG" || { echo "FATAL: .config中设备名未对齐"; exit 1; }

echo "=== SL3000 three-piece generation complete ==="
echo "[OUT] DTS : $DTS"
echo "[OUT] MK  : $MK"
echo "[OUT] CFG : $CFG"
echo "[SUCCESS] 三件套已生成并强对齐，可直接执行make defconfig构建！"
