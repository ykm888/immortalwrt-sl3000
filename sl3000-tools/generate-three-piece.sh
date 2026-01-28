#!/bin/bash
set -euo pipefail

########################################
# SL3000 三件套（DTS / MK / CONFIG）
# 基于别人仓库成功案例（mt7981 平台 + FIT）
# 内存：1GB
# 设备名：sl_3000-emmc
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
# 1. DTS（别人仓库成功案例 + 内存修正为 1GB）
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

&eth {
	status = "okay";

	gmac0: mac@0 {
		compatible = "mediatek,eth-mac";
		reg = <0>;
		phy-mode = "2500base-x";

		fixed-link {
			speed = <2500>;
			full-duplex;
			pause;
		};
	};

	gmac1: mac@1 {
		compatible = "mediatek,eth-mac";
		reg = <1>;
		phy-mode = "2500base-x";

		fixed-link {
			speed = <2500>;
			full-duplex;
			pause;
		};
	};

	mdio: mdio-bus {
		#address-cells = <1>;
		#size-cells = <0>;

		switch@0 {
			compatible = "mediatek,mt7531";
			reg = <31>;
			reset-gpios = <&pio 39 0>;

			ports {
				#address-cells = <1>;
				#size-cells = <0>;

				port@0 { reg = <0>; label = "lan1"; };
				port@1 { reg = <1>; label = "lan2"; };
				port@2 { reg = <2>; label = "lan3"; };
				port@3 { reg = <3>; label = "wan"; };

				port@6 {
					reg = <6>;
					label = "cpu";
					ethernet = <&gmac0>;
					phy-mode = "2500base-x";

					fixed-link {
						speed = <2500>;
						full-duplex;
						pause;
					};
				};
			};
		};
	};
};

&mmc0 {
	bus-width = <8>;
	cap-mmc-highspeed;
	max-frequency = <52000000>;
	no-sd;
	no-sdio;
	non-removable;
	pinctrl-names = "default", "state_uhs";
	pinctrl-0 = <&mmc0_pins_default>;
	pinctrl-1 = <&mmc0_pins_uhs>;
	vmmc-supply = <&reg_3p3v>;
	status = "okay";

	card@0 {
		compatible = "mmc-card";
		reg = <0>;

		block {
			compatible = "block-device";

			partitions {
				block-partition-factory {
					partname = "factory";

					nvmem-layout {
						compatible = "fixed-layout";
						#address-cells = <1>;
						#size-cells = <1>;

						eeprom_factory_0: eeprom@0 {
							reg = <0x0 0x1000>;
						};

						macaddr_factory_4: macaddr@4 {
							compatible = "mac-base";
							reg = <0x4 0x6>;
							#nvmem-cell-cells = <1>;
						};
					};
				};
			};
		};
	};
};

&pio {
	mmc0_pins_default: mmc0-pins-default {
		mux { function = "flash"; groups = "emmc_45"; };
	};

	mmc0_pins_uhs: mmc0-pins-uhs {
		mux { function = "flash"; groups = "emmc_45"; };
	};
};

&uart0 { status = "okay"; };
&watchdog { status = "okay"; };

&wifi {
	nvmem-cells = <&eeprom_factory_0>;
	nvmem-cell-names = "eeprom";
	status = "okay";

	band@1 {
		reg = <1>;
		nvmem-cells = <&macaddr_factory_4 1>;
		nvmem-cell-names = "mac-address";
	};
};

&usb_phy { status = "okay"; };
&xhci { status = "okay"; };
EOF

echo "[DTS] generated: $DTS"
echo

########################################
# 2. MK（别人仓库成功案例完整版本）
########################################
echo "=== Stage 2: Generate MK ==="

IMAGE_DIR="$ROOT/target/linux/mediatek/image"
MK="$IMAGE_DIR/mt7981.mk"

if [ ! -f "$MK" ]; then
  echo "[FATAL] mt7981.mk not found: $MK"
  exit 1
fi

sed -i '/Device\/sl_3000-emmc/,/endef/d' "$MK"
sed -i '/sl_3000-emmc/d' "$MK"

cat >> "$MK" << EOF

define Device/sl_3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 eMMC
  DEVICE_DTS := mt7981b-sl-3000-emmc
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware automount coremark blkid blockdev fdisk f2fsck mkf2fs kmod-mmc
  KERNEL := kernel-bin | lzma | fit lzma \$\$(KDIR)/image-\$\$(firstword \$\$(DEVICE_DTS)).dtb
  KERNEL_INITRAMFS := kernel-bin | lzma | \\
	fit lzma \$\$(KDIR)/image-\$\$(firstword \$\$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef

TARGET_DEVICES += sl_3000-emmc
EOF

echo "[MK] updated: $MK"
echo

########################################
# 3. CONFIG（基于别人仓库结构的 SL3000 单设备配置）
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
