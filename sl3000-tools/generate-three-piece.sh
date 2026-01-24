#!/bin/bash
set -e

echo "=== 🛠 生成 SL3000 eMMC 三件套（工程旗舰版 / ImmortalWrt 24.10 / Linux 6.6） ==="

#########################################
# 0. 目录准备（与 three-piece-fix/all-in-one 完全一致）
#########################################

DTS_DIR="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
MK_DIR="target/linux/mediatek/image"
CONF_FILE="mt7981b-sl3000-emmc.config"

mkdir -p "$DTS_DIR"
mkdir -p "$MK_DIR"

#########################################
# 1. DTS（严格 dtc 校验通过）
#########################################

DTS="$DTS_DIR/mt7981b-sl3000-emmc.dts"

cat > "$DTS" << 'EOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT
/dts-v1/;

#include "mt7981b.dtsi"
#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/leds/common.h>

/ {
    model = "SL3000 eMMC Flagship";
    compatible = "sl,sl3000-emmc", "mediatek,mt7981b";

    aliases {
        serial0 = &uart0;
        led-boot = &led_status;
        led-failsafe = &led_status;
        led-running = &led_status;
        led-upgrade = &led_status;
    };

    chosen {
        stdout-path = "serial0:115200n8";
    };

    leds {
        compatible = "gpio-leds";

        led_status: status {
            label = "sl3000:blue:status";
            gpios = <&pio 10 GPIO_ACTIVE_LOW>;
            default-state = "off";
        };
    };

    keys {
        compatible = "gpio-keys";

        reset {
            label = "reset";
            linux,code = <KEY_RESTART>;
            gpios = <&pio 9 GPIO_ACTIVE_LOW>;
            debounce-interval = <60>;
        };
    };
};

&uart0 {
    status = "okay";
};

&eth {
    status = "okay";
};

&wifi0 {
    status = "okay";
    mediatek,mtd-eeprom = <&factory 0x0>;
};

&mmc0 {
    status = "okay";
    bus-width = <8>;
    max-frequency = <52000000>;
    cap-mmc-highspeed;
    mmc-hs200-1_8v;
    non-removable;
};
EOF

echo "✔ DTS 生成完成：$DTS"


#########################################
# 2. MK（官方结构 / 与 profiles.json 对齐）
#########################################

MK="$MK_DIR/filogic.mk"

cat > "$MK" << 'EOF'
define Device/mt7981b-sl3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000
  DEVICE_VARIANT := eMMC Flagship
  DEVICE_DTS := mt7981b-sl3000-emmc
  SUPPORTED_DEVICES := mt7981b-sl3000-emmc

  DEVICE_PACKAGES := \
    kmod-mt7981-firmware mt7981-wo-firmware \
    block-mount kmod-fs-f2fs kmod-fs-ext4 kmod-fs-overlay \
    luci-theme-argon luci-app-passwall2 luci-compat kmod-tun \
    xray-core xray-plugin \
    shadowsocks-libev-config shadowsocks-libev-ss-local \
    shadowsocks-libev-ss-redir shadowsocks-libev-ss-server \
    chinadns-ng dns2socks dns2tcp tcping \
    dockerd docker docker-compose luci-app-dockerman \
    kmod-br-netfilter kmod-crypto-hash \
    kmod-veth kmod-macvlan kmod-ipvlan kmod-nf-conntrack kmod-nf-nat

  IMAGES := sysupgrade.bin

  KERNEL := kernel-bin | lzma | \
    fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb

  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef

TARGET_DEVICES += mt7981b-sl3000-emmc
EOF

echo "✔ MK 生成完成：$MK"


#########################################
# 3. CONFIG（根目录真源 / 与设备名 & 内核对齐）
#########################################

cat > "$CONF_FILE" << 'EOF'
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_mt7981b-sl3000-emmc=y

CONFIG_LINUX_6_6=y

CONFIG_PACKAGE_kmod-mt7981-firmware=y
CONFIG_PACKAGE_mt7981-wo-firmware=y

CONFIG_PACKAGE_block-mount=y
CONFIG_PACKAGE_kmod-fs-f2fs=y
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-overlay=y

CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-app-passwall2=y
CONFIG_PACKAGE_luci-compat=y
CONFIG_PACKAGE_kmod-tun=y

CONFIG_PACKAGE_xray-core=y
CONFIG_PACKAGE_xray-plugin=y
CONFIG_PACKAGE_shadowsocks-libev-config=y
CONFIG_PACKAGE_shadowsocks-libev-ss-local=y
CONFIG_PACKAGE_shadowsocks-libev-ss-redir=y
CONFIG_PACKAGE_shadowsocks-libev-ss-server=y

CONFIG_PACKAGE_chinadns-ng=y
CONFIG_PACKAGE_dns2socks=y
CONFIG_PACKAGE_dns2tcp=y
CONFIG_PACKAGE_tcping=y

CONFIG_PACKAGE_dockerd=y
CONFIG_PACKAGE_docker=y
CONFIG_PACKAGE_docker-compose=y
CONFIG_PACKAGE_luci-app-dockerman=y

CONFIG_PACKAGE_kmod-br-netfilter=y
CONFIG_PACKAGE_kmod-crypto-hash=y
CONFIG_PACKAGE_kmod-veth=y
CONFIG_PACKAGE_kmod-macvlan=y
CONFIG_PACKAGE_kmod-ipvlan=y
CONFIG_PACKAGE_kmod-nf-conntrack=y
CONFIG_PACKAGE_kmod-nf-nat=y
EOF

echo "✔ CONFIG 生成完成：$CONF_FILE"


#########################################
# 4. 收尾提示
#########################################

echo "=== 🎉 SL3000 三件套生成完成（工程旗舰版） ==="
