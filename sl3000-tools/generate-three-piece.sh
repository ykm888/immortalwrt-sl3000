#!/bin/bash
set -euo pipefail

########################################
# SL3000 三件套（DTS / MK / CONFIG）
# 平台：mt7981 + FIT
# 内存：1GB
# 设备名：sl_3000-emmc
########################################

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

########################################
# 1. DTS
########################################
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
		led-boot = &status_red_led;
		led-failsafe = &status_red_led;
		led-running = &status_green_led;
		led-upgrade = &status_blue_led;
	};

	chosen {
		bootargs = "root=PARTLABEL=rootfs rootwait";
		stdout-path = "serial0:115200n8";
	};

	/* 1GB RAM */
	memory@40000000 {
		reg = <0 0x40000000 0 0x40000000>;
	};

	gpio-keys {
		compatible = "gpio-keys";

		button-mesh {
			label = "mesh";
			linux,code = <BTN_9>;
			linux,input-type = <EV_SW>;
			gpios = <&pio 0 GPIO_ACTIVE_LOW>;
		};

		button-reset {
			label = "reset";
			linux,code = <KEY_RESTART>;
			gpios = <&pio 1 GPIO_ACTIVE_LOW>;
		};
	};

	gpio-leds {
		compatible = "gpio-leds";

		status_red_led: led-0 {
			label = "red:status";
			gpios = <&pio 10 GPIO_ACTIVE_LOW>;
		};

		status_green_led: led-1 {
			label = "green:status";
			gpios = <&pio 11 GPIO_ACTIVE_LOW>;
		};

		status_blue_led: led-2 {
			label = "blue:status";
			gpios = <&pio 12 GPIO_ACTIVE_LOW>;
		};
	};
};
EOF

echo "[DTS] generated: $DTS"
echo

########################################
# 2. MK（写入 filogic.mk）
########################################
echo "=== Stage 2: Generate MK ==="

IMAGE_DIR="$ROOT/target/linux/mediatek/image"
MK="$IMAGE_DIR/filogic.mk"

if [ ! -f "$MK" ]; then
  echo "[FATAL] filogic.mk not found: $MK"
  exit 1
fi

# 清理旧段
sed -i '/Device\/sl_3000-emmc/,/endef/d' "$MK"
sed -i '/sl_3000-emmc/d' "$MK"

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

TARGET_DEVICES += sl_3000-emmc
EOF

echo "[MK] updated: $MK"
echo

########################################
# 3. CONFIG
########################################
echo "=== Stage 3: Generate .config ==="

CFG="$ROOT/.config"

cat > "$CFG" << 'EOF'
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_mt7981=y
CONFIG_TARGET_MULTI_PROFILE=y

CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_sl_3000-emmc=y
CONFIG_TARGET_DEVICE_PACKAGES_mediatek_mt7981_DEVICE_sl_3000-emmc=""

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

########################################
# 4. Validation
########################################
echo "=== Stage 4: Validation ==="

[ -s "$DTS" ] || { echo "[FATAL] DTS missing: $DTS"; exit 1; }
[ -s "$MK" ]  || { echo "[FATAL] MK missing: $MK"; exit 1; }
[ -s "$CFG" ] || { echo "[FATAL] .config missing: $CFG"; exit 1; }

grep -q "sl_3000-emmc" "$MK" || { echo "[FATAL] MK missing device"; exit 1; }
grep -q "CONFIG_TARGET_mediatek_mt7981" "$CFG" || { echo "[FATAL] CONFIG missing mt7981"; exit 1; }

echo
echo "=== SL3000 three-piece generation complete ==="
echo "[OUT] DTS : $DTS"
echo "[OUT] MK  : $MK"
echo "[OUT] CFG : $CFG"
