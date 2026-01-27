#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  SL3000 官方工程级三件套生成脚本
#  - DTS:    target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts
#  - MK:     target/linux/mediatek/image/mt7981.mk
#  - CONFIG: .config（自动生成完整工程级配置段）
# ============================================================

BOARD_ID="sl-3000-emmc"
BOARD_DTS="mt7981b-sl-3000-emmc.dts"

DTS_DIR="target/linux/mediatek/dts"
IMAGE_MK="target/linux/mediatek/image/mt7981.mk"
CONFIG_OUT="sl3000-tools/sl3000-full-config.txt"

ensure_root() {
    if [ ! -d target/linux/mediatek ] || [ ! -f target/Makefile ]; then
        echo "错误：请在 OpenWrt/ImmortalWrt 源码根目录运行此脚本"
        exit 1
    fi
}

# ============================================================
# 1. 生成 DTS（对齐成功案例结构）
# ============================================================
gen_dts() {
    local dst="${DTS_DIR}/${BOARD_DTS}"

    if [ -f "${dst}" ]; then
        echo "[DTS] 已存在：${dst}"
        return
    fi

    echo "[DTS] 生成 ${dst}"
    mkdir -p "${DTS_DIR}"

    cat > "${dst}" << 'EOF'
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

&pio {
    mmc0pinsdefault: mmc0-pins-default {
        mux { function = "flash"; groups = "emmc_45"; };
    };

    mmc0pinsuhs: mmc0-pins-uhs {
        mux { function = "flash"; groups = "emmc_45"; };
    };
};

&uart0 { status = "okay"; };
&watchdog { status = "okay"; };

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

&usb_phy { status = "okay"; };
&xhci { status = "okay"; };
EOF
}

# ============================================================
# 2. 生成 MK（对齐成功案例格式）
# ============================================================
gen_mk() {
    if grep -q "^define Device/${BOARD_ID}" "${IMAGE_MK}"; then
        echo "[MK] ${BOARD_ID} 已存在"
        return
    fi

    echo "[MK] 追加 ${BOARD_ID} 到 ${IMAGE_MK}"

    cat >> "${IMAGE_MK}" << 'EOF'

define Device/sl-3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := SL-3000
  DEVICE_VARIANT := eMMC
  DEVICE_DTS := mt7981b-sl-3000-emmc
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-mt7981-firmware kmod-usb3 kmod-mmc

  BLOCKSIZE := 128k
  PAGESIZE := 2048

  IMAGES := sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata

  ARTIFACTS := emmc-gpt.bin
  ARTIFACT/emmc-gpt.bin := mt798x-gpt emmc
endef
TARGET_DEVICES += sl-3000-emmc
EOF
}

# ============================================================
# 3. 生成完整 CONFIG（对齐你贴出来的官方工程级配置）
# ============================================================
gen_config() {
    echo "[CONFIG] 生成完整 SL3000 工程级配置：${CONFIG_OUT}"

    mkdir -p sl3000-tools

    cat > "${CONFIG_OUT}" << 'EOF'
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_mt7981=y
CONFIG_TARGET_MULTI_PROFILE=y

CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_sl-3000-emmc=y
CONFIG_TARGET_DEVICE_PACKAGES_mediatek_mt7981_DEVICE_sl-3000-emmc=""

CONFIG_MMC=y
CONFIG_MMC_MTK=y
CONFIG_MMC_BLOCK=y

CONFIG_USB_XHCI_HCD=y
CONFIG_USB_XHCI_MTK=y

CONFIG_NET_DSA_MT7530=y
CONFIG_NET_DSA_MT7530_MDIO=y

CONFIG_MTK_CHIP_MT7981=y
CONFIG_MTK_MT_WIFI=m
CONFIG_MTK_WIFI_DRIVER=y
CONFIG_MTK_WIFI_BASIC_FUNC=y
CONFIG_MTK_WIFI_FW_BIN_LOAD=y
CONFIG_MTK_MT_MAC=y
CONFIG_MTK_MT7981_NEW_FW=y
CONFIG_MTK_DOT11_HE_AX=y
CONFIG_MTK_DOT11_N_SUPPORT=y
CONFIG_MTK_DOT11_VHT_AC=y
CONFIG_MTK_DOT11W_PMF_SUPPORT=y
CONFIG_MTK_WPA3_SUPPORT=y
CONFIG_MTK_WSC_INCLUDED=y
CONFIG_MTK_WSC_V2_SUPPORT=y
CONFIG_MTK_UAPSD=y
CONFIG_MTK_TPC_SUPPORT=y
CONFIG_MTK_TXBF_SUPPORT=y
CONFIG_MTK_MU_RA_SUPPORT=y
CONFIG_MTK_MUMIMO_SUPPORT=y
CONFIG_MTK_DBDC_MODE=y
CONFIG_MTK_WHNAT_SUPPORT=m
CONFIG_MTK_WARP_V2=y
CONFIG_WED_HW_RRO_SUPPORT=y

CONFIG_CONNINFRA_AUTO_UP=y
CONFIG_CONNINFRA_EMI_SUPPORT=y
CONFIG_MTK_CONNINFRA_APSOC=y
CONFIG_MTK_CONNINFRA_APSOC_MT7981=y

CONFIG_DEVEL=y
CONFIG_TOOLCHAINOPTS=y
CONFIG_BUSYBOX_CUSTOM=y
CONFIG_TARGET_PER_DEVICE_ROOTFS=y
CONFIG_INCLUDE_CONFIG=y
CONFIG_JSON_OVERVIEW_IMAGE_INFO=y

CONFIG_PACKAGE_kmod-mediatek_hnat=y
CONFIG_PACKAGE_kmod-nf-flow=y
CONFIG_PACKAGE_kmod-ipt-offload=y
CONFIG_PACKAGE_kmod-warp=y

CONFIG_PACKAGE_kmod-usb3=y
CONFIG_PACKAGE_kmod-fs-vfat=y
CONFIG_PACKAGE_kmod-fs-autofs4=y
CONFIG_PACKAGE_kmod-scsi-core=y

CONFIG_PACKAGE_ethtool=y
CONFIG_PACKAGE_htop=y
CONFIG_PACKAGE_tcpdump=y
CONFIG_PACKAGE_switch=y
CONFIG_PACKAGE_wireless-regdb=y
CONFIG_PACKAGE_wireless-tools=y
CONFIG_PACKAGE_zram-swap=y
EOF
}

# ============================================================
# 主流程
# ============================================================
main() {
    ensure_root
    gen_dts
    gen_mk
    gen_config
    echo "[OK] SL3000 三件套（DTS + MK + CONFIG）已全部生成完成"
    echo "请查看：git diff"
}

main "$@"
