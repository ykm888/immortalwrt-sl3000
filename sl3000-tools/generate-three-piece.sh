#!/bin/bash
set -e

DEVICE="mt7981b-sl3000-emmc"
TARGET_DTS="target/linux/mediatek/dts/${DEVICE}.dts"
TARGET_MK="target/linux/mediatek/image/filogic.mk"
TARGET_CONFIG=".config"

echo "[SL3000] 旗舰版三件套生成开始"
echo "设备: ${DEVICE}"
echo

# -----------------------------
# 1. 路径校验
# -----------------------------
if [ ! -d target/linux/mediatek/dts ]; then
    echo "错误: 未找到 target/linux/mediatek/dts"
    exit 1
fi

if [ ! -d target/linux/mediatek/image ]; then
    echo "错误: 未找到 target/linux/mediatek/image"
    exit 1
fi

# -----------------------------
# 2. 生成 DTS
# -----------------------------
echo "[1/3] 生成 DTS: ${TARGET_DTS}"

cat > "${TARGET_DTS}" << 'EOF'
/* SPDX-License-Identifier: GPL-2.0-or-later OR MIT */

/dts-v1/;
#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/leds/common.h>

#include "mt7981.dtsi"

/ {
    model = "SL-3000 eMMC Router";
    compatible = "sl,sl3000-emmc", "mediatek,mt7981";

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
};

gpio-keys {
    compatible = "gpio-keys";

    button-mesh {
        label = "mesh";
        linux,code = <KEY_WPS_BUTTON>;
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

        partitions {
            factory: partition@0 {
                label = "factory";
                reg = <0x0 0x1000>;

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
        nvmem-cells = <&macaddr_factory_4>;
        nvmem-cell-names = "mac-address";
    };
};

&usb_phy { status = "okay"; };
&xhci { status = "okay"; };
EOF

echo "[OK] DTS 生成完成"
echo

# -----------------------------
# 3. 生成 MK 设备段
# -----------------------------
echo "[2/3] 生成 MK 设备段"

cat > "${TARGET_MK}" << 'EOF'
define Device/mt7981b-sl3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := SL3000
  DEVICE_VARIANT := eMMC
  DEVICE_DTS := mt7981b-sl-3000-emmc
  DEVICE_PACKAGES := kmod-usb3 kmod-usb2 kmod-mt7981-firmware \
                     kmod-mt7981-wifi kmod-mt7531 \
                     block-mount e2fsprogs fdisk \
                     docker dockerd luci-app-dockerman \
                     luci-app-passwall2
endef
TARGET_DEVICES += mt7981b-sl3000-emmc
EOF

echo "[OK] MK 生成完成"
echo

# -----------------------------
# 4. 生成 CONFIG
# -----------------------------
echo "[3/3] 生成 .config"

cat > "${TARGET_CONFIG}" << 'EOF'
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_mt7981b-sl3000-emmc=y
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-app-passwall2=y
CONFIG_PACKAGE_docker=y
CONFIG_PACKAGE_dockerd=y
CONFIG_PACKAGE_luci-app-dockerman=y
EOF

echo "[OK] CONFIG 生成完成"
echo

echo "[SL3000] 旗舰版三件套生成完成"
echo "----------------------------------------"
echo "DTS:    ${TARGET_DTS}"
echo "MK:     ${TARGET_MK}"
echo "CONFIG: ${TARGET_CONFIG}"
echo "----------------------------------------"
