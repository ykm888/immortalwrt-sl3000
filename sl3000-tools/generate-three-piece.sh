#!/bin/sh
set -e

echo "=== 🛠 生成 SL3000 eMMC 三件套（24.10 / Linux 6.6 / 最终修复版） ==="

#########################################
# 1. DTS（完全修复版，适配 24.10 / 6.6）
#########################################

DTS="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
mkdir -p target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek

cat > "$DTS" << 'EOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT
/dts-v1/;

#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/leds/common.h>
#include "mt7981b.dtsi"

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
    mediatek,eth-mac = "00:11:22:33:44:55";
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

echo "✔ DTS 生成完成（已通过 6.6 语法修复）"


#########################################
# 2. MK（最终修复版）
#########################################

MK="target/linux/mediatek/image/filogic.mk"
mkdir -p target/linux/mediatek/image

cat > "$MK" << 'EOF'
# SPDX-License-Identifier: GPL-2.0-or-later OR MIT

define Device/mt7981b-sl3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000
  DEVICE_VARIANT := eMMC Flagship
  DEVICE_DTS := mt7981b-sl3000-emmc
  DEVICE_DTS_DIR := ../files-6.6/arch/arm64/boot/dts/mediatek

  SUPPORTED_DEVICES := mt7981b-sl3000-emmc

  DEVICE_PACKAGES := \
    kmod-mt7981-firmware mt7981-wo-firmware \
    f2fsck mkf2fs automount block-mount kmod-fs-f2fs kmod-fs-ext4 kmod-fs-overlay \
    luci-app-passwall2 luci-compat kmod-tun \
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

echo "✔ MK 生成完成（SUPPORTED_DEVICES 已修复）"


#########################################
# 3. CONFIG（完整工程级版本）
#########################################

CONF=".config"

cat > "$CONF" << 'EOF'
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_mt7981b-sl3000-emmc=y
CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_mt7981b-sl3000-emmc=y

CONFIG_LINUX_6_6=y

CONFIG_PACKAGE_kmod-mt7981-firmware=y
CONFIG_PACKAGE_mt7981-wo-firmware=y

CONFIG_PACKAGE_block-mount=y
CONFIG_PACKAGE_kmod-fs-f2fs=y
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-overlay=y

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

echo "✔ CONFIG 生成完成"
echo "=== 🎉 三件套生成完成（24.10 / Linux 6.6 / 最终修复版） ==="
