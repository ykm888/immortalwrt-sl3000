#!/bin/bash
set -euo pipefail

# 基础校验：是否在OpenWrt/ImmortalWrt根目录
if [ ! -d "target/linux/mediatek/filogic" ] || [ ! -f "Makefile" ]; then
    echo "FATAL: not in ImmortalWrt 24.10 root (missing filogic platform)"
    exit 1
fi

ROOT="$(pwd)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 日志初始化：保留原日志路径，终端+日志双输出
LOG="$SCRIPT_DIR/sl3000-three-piece.log"
: > "$LOG"
exec > >(tee -a "$LOG") 2>&1

echo "=== SL3000 three-piece generation start ==="
echo "[ROOT] $ROOT"
echo "[SCRIPT_DIR] $SCRIPT_DIR"
echo

# 1. 生成DTS文件：修正为ImmortalWrt24.10 filogic官方路径
DTS_DIR="$ROOT/target/linux/mediatek/filogic/dts"
DTS="$DTS_DIR/mt7981b-sl-3000-emmc.dts"
mkdir -p "$DTS_DIR"

# 保留你原脚本的DTS内容，无多余修改
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

# 2. 写入MK配置：修正为ImmortalWrt24.10 filogic官方Makefile路径
IMAGE_DIR="$ROOT/target/linux/mediatek/filogic/image"
MK="$IMAGE_DIR/Makefile"

if [ ! -f "$MK" ]; then
  echo "FATAL: filogic Makefile not found at $MK"
  exit 1
fi

# 兼容修改：sed无匹配时不报错，避免脚本终止
DEVICE_NAME="sl_3000-emmc"
sed -i '/Device\/'${DEVICE_NAME}'/,/endef/d' "$MK" 2>/dev/null || true
sed -i '/TARGET_DEVICES += '${DEVICE_NAME}'/d' "$MK" 2>/dev/null || true

# 保留你原脚本的设备配置，仅修正变量兼容（$->\$）
cat >> "$MK" << 'EOF'

define Device/sl_3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 eMMC
  DEVICE_DTS := mt7981b-sl-3000-emmc
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware automount coremark blkid blockdev fdisk f2fsck mkf2fs kmod-mmc
  KERNEL := kernel-bin | lzma | fit lzma $(KDIR)/image-$(firstword $(DEVICE_DTS)).dtb
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $(KDIR)/image-$(firstword $(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef

TARGET_DEVICES += sl3000-emmc
EOF

echo "[MK] updated: $MK"
echo

# 3. 生成.config：修正为ImmortalWrt24.10 filogic平台配置项
CFG="$ROOT/.config"

cat > "$CFG" << 'EOF'
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_MULTI_PROFILE=y

CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_sl_3000-emmc=y

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

# 4. 保留原脚本的校验逻辑，仅修正路径和配置项
[ -s "$DTS" ] || { echo "FATAL: DTS missing"; exit 1; }
[ -s "$MK" ]  || { echo "FATAL: MK missing"; exit 1; }
[ -s "$CFG" ] || { echo "FATAL: CONFIG missing"; exit 1; }

grep -q "define Device/sl_3000-emmc" "$MK" || { echo "FATAL: MK device block missing"; exit 1; }
grep -q "TARGET_DEVICES += sl3000-emmc" "$MK" || { echo "FATAL: MK TARGET_DEVICES missing"; exit 1; }
# 修正CONFIG校验项，对齐filogic平台
grep -q '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_sl_3000-emmc=y' "$CFG" || { echo "FATAL: CONFIG device enable missing"; exit 1; }

echo "=== SL3000 three-piece generation complete ==="
echo "[OUT] DTS : $DTS"
echo "[OUT] MK  : $MK"
echo "[OUT] CFG : $CFG"
echo "[SUCCESS]"
