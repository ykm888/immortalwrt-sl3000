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

echo "=== Stage 1: Generate DTS ==="

cat > "$DTS" << 'EOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT

/dts-v1/;

#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/leds/common.h>

#include "mt7981.dtsi"

/ {
	model = "SL3000 eMMC";
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
		device_type = "memory";
		reg = <0 0x40000000 0 0x40000000>;
	};

	gpio-keys {
		compatible = "gpio-keys";

		button-mesh {
			label = "mesh";
			linux,code = <BTN_9>;
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

		statusredled: led-0 {
			label = "red:status";
			gpios = <&pio 10 GPIO_ACTIVE_LOW>;
		};

		statusgreenled: led-1 {
			label = "green:status";
			gpios = <&pio 11 GPIO_ACTIVE_LOW>;
		};

		statusblueled: led-2 {
			label = "blue:status";
			gpios = <&pio 12 GPIO_ACTIVE_LOW>;
		};
	};
};

&eth {
	status = "okay";

	gmac0: mac@0 {
		reg = <0>;
		phy-mode = "2500base-x";

		fixed-link {
			speed = <2500>;
			full-duplex;
		};
	};

	gmac1: mac@1 {
		reg = <1>;
		phy-mode = "2500base-x";

		fixed-link {
			speed = <2500>;
			full-duplex;
		};
	};

	mdio: mdio-bus {
		#address-cells = <1>;
		#size-cells = <0>;

		switch@0 {
			compatible = "mediatek,mt7531";
			reg = <31>;
			reset-gpios = <&pio 39 GPIO_ACTIVE_LOW>;

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
	pinctrl-0 = <&mmc0pinsdefault>;
	pinctrl-1 = <&mmc0pinsuhs>;
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

						eepromfactory0: eeprom@0 {
							reg = <0x0 0x1000>;
						};

						macaddrfactory4: macaddr@4 {
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

&uart0 { status = "okay"; };
&watchdog { status = "okay"; };
&usb_phy { status = "okay"; };
&xhci { status = "okay"; };

&wifi {
	nvmem-cells = <&eepromfactory0>;
	nvmem-cell-names = "eeprom";
	status = "okay";

	band@1 {
		reg = <1>;
		nvmem-cells = <&macaddrfactory4 1>;
		nvmem-cell-names = "mac-address";
	};
};
EOF

echo "=== Stage 2: Ensure MK device ==="

if ! grep -q "Device/sl-3000-emmc" "$MK"; then
  cat >> "$MK" << EOF

define Device/sl-3000-emmc
${TAB}DEVICE_VENDOR := SL
${TAB}DEVICE_MODEL := SL3000
${TAB}DEVICE_VARIANT := eMMC
${TAB}DEVICE_DTS := mt7981b-sl-3000-emmc
${TAB}DEVICE_DTS_DIR := ../dts
${TAB}DEVICE_PACKAGES := kmod-usb3 kmod-fs-ext4 block-mount f2fs-tools \\
${TAB}${TAB}luci luci-base luci-i18n-base-zh-cn \\
${TAB}${TAB}luci-app-eqos-mtk luci-app-mtwifi-cfg luci-app-turboacc-mtk luci-app-wrtbwmon
${TAB}IMAGES := sysupgrade.bin
${TAB}IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
${TAB}IMAGE/initramfs.bin := append-dtb | uImage | append-metadata
endef
TARGET_DEVICES += sl-3000-emmc
EOF
fi

echo "=== Stage 3: Generate CONFIG ==="

cat > "$CFG" << 'EOF'
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_mt7981=y
CONFIG_TARGET_MULTI_PROFILE=y
CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_sl-3000-emmc=y

CONFIG_TARGET_ROOTFS_INITRAMFS=y
CONFIG_TARGET_ROOTFS_SQUASHFS=y
CONFIG_TARGET_IMAGES_GZIP=y

CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y

CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_block-mount=y
CONFIG_PACKAGE_f2fs-tools=y

CONFIG_PACKAGE_luci-app-eqos-mtk=y
CONFIG_PACKAGE_luci-app-mtwifi-cfg=y
CONFIG_PACKAGE_luci-app-turboacc-mtk=y
CONFIG_PACKAGE_luci-app-wrtbwmon=y

# Fix OpenWrt 24.10 SSL breakage
CONFIG_PACKAGE_libustream-mbedtls=n
CONFIG_PACKAGE_libustream-wolfssl=y
CONFIG_PACKAGE_libwolfssl=y
CONFIG_PACKAGE_libmbedtls=n
EOF

echo "=== Stage 4: Validation ==="

[ -s "$DTS" ] || { echo "[FATAL] DTS missing"; exit 1; }
[ -s "$MK" ]  || { echo "[FATAL] MK missing"; exit 1; }
[ -s "$CFG" ] || { echo "[FATAL] CONFIG missing"; exit 1; }

echo "=== Three-piece generation complete (SL3000 eMMC) ==="
echo "[OUT] DTS: $DTS"
echo "[OUT] MK : $MK"
echo "[OUT] CFG: $CFG"
