#!/bin/bash
set -e

DEVICE_ID="mt7981b-sl-3000-emmc"
DTS_FILE="target/linux/mediatek/dts/${DEVICE_ID}.dts"
MK_FILE="target/linux/mediatek/image/mt7981.mk"
CFG_FILE="sl3000-tools/sl3000-full-config.txt"

echo "[SL3000] 三件套生成（旗舰版，对齐 ${DEVICE_ID}）"
echo "DTS: ${DTS_FILE}"
echo "MK : ${MK_FILE}"
echo "CFG: ${CFG_FILE}"
echo

# -----------------------------
# 1. 路径校验
# -----------------------------
[ -d "target/linux/mediatek/dts" ]    || { echo "❌ 缺少目录: target/linux/mediatek/dts"; exit 1; }
[ -d "target/linux/mediatek/image" ]  || { echo "❌ 缺少目录: target/linux/mediatek/image"; exit 1; }
[ -d "sl3000-tools" ]                 || { echo "❌ 缺少目录: sl3000-tools"; exit 1; }

# -----------------------------
# 2. 生成 DTS（完全覆盖）
# -----------------------------
echo "[1/3] 写入 DTS: ${DTS_FILE}"

cat > "${DTS_FILE}" << 'EOF'
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

echo "[OK] DTS 写入完成"
echo

# -----------------------------
# 3. 生成 / 追加 MK 设备段（对齐 mt7981.mk）
# -----------------------------
echo "[2/3] 对齐 MK: ${MK_FILE}"

if ! grep -q "Device/${DEVICE_ID}" "${MK_FILE}" 2>/dev/null; then
    cat >> "${MK_FILE}" << EOF

define Device/${DEVICE_ID}
  DEVICE_VENDOR := SL
  DEVICE_MODEL := SL3000
  DEVICE_VARIANT := eMMC
  DEVICE_DTS := ${DEVICE_ID}
  DEVICE_PACKAGES := kmod-usb3 kmod-usb2 kmod-mt7981-firmware \\
\tkmod-mt7981-wifi kmod-mt7531 \\
\tblock-mount e2fsprogs fdisk \\
\tdocker dockerd luci-app-dockerman \\
\tluci-app-passwall2
endef
TARGET_DEVICES += ${DEVICE_ID}
EOF
    echo "[OK] 已追加 Device/${DEVICE_ID} 到 ${MK_FILE}"
else
    echo "[SKIP] ${MK_FILE} 中已存在 Device/${DEVICE_ID}"
fi
echo

# -----------------------------
# 4. 生成完整配置文件（对齐 CI: sl3000-full-config.txt）
# -----------------------------
echo "[3/3] 写入 CFG: ${CFG_FILE}"

cat > "${CFG_FILE}" << 'EOF'
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_mt7981b-sl-3000-emmc=y

CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-ssl=y
CONFIG_PACKAGE_luci-app-passwall2=y

CONFIG_PACKAGE_docker=y
CONFIG_PACKAGE_dockerd=y
CONFIG_PACKAGE_luci-app-dockerman=y

CONFIG_PACKAGE_block-mount=y
CONFIG_PACKAGE_e2fsprogs=y
CONFIG_PACKAGE_fdisk=y
EOF

echo "[OK] CFG 写入完成"
echo
echo "[SL3000] 三件套生成完成（已对齐 mt7981b-sl-3000-emmc）"
