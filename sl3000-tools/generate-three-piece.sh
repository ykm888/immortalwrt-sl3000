#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SCRIPT_DIR="$ROOT/sl3000-tools"
LOG="$SCRIPT_DIR/sl3000-three-piece.log"
mkdir -p "$SCRIPT_DIR"
: > "$LOG"
exec > >(tee -a "$LOG") 2>&1

DTS_DIR="$ROOT/target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
DTS="$DTS_DIR/mt7981b-sl3000-emmc.dts"
MK="$ROOT/target/linux/mediatek/image/filogic.mk"
CFG="$ROOT/.config"

mkdir -p "$DTS_DIR"

clean_crlf() {
    [ ! -f "$1" ] && return 0
    sed -i 's/\r$//' "$1"
}

echo "=== DTS ==="

cat > "$DTS" << 'EOF'
// SPDX-License-Identifier: GPL-2.0-only OR MIT
/dts-v1/;

/*
 * 24.10 + 6.6：板级符号在 mt7981-rfb.dts 里，
 * 直接继承参考板，下面只做差异覆盖。
 */
#include "mt7981-rfb.dts"
#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/leds/common.h>

/ {
    model = "SL SL3000 eMMC Engineering Flagship Edition";
    compatible = "sl,sl3000-emmc", "mediatek,mt7981b";
};

/* 覆盖 LED 定义 */
&leds {
    led_status: led-status {
        label = "sl:blue:status";
        gpios = <&pio 12 GPIO_ACTIVE_LOW>;
        linux,default-trigger = "heartbeat";
        default-state = "on";
    };
};

/* 覆盖按键定义 */
&keys {
    reset {
        label = "reset";
        gpios = <&pio 18 GPIO_ACTIVE_LOW>;
        linux,code = <KEY_RESTART>;
        debounce-interval = <60>;
    };
};

/* 覆盖存储控制器 */
&mmc0 {
    status = "okay";
    bus-width = <8>;
    mmc-hs200-1_8v;
    non-removable;
    cap-mmc-hw-reset;
    mediatek,mmc-wp-disable;
};

/* 覆盖网口 */
&gmac0 {
    status = "okay";
    phy-mode = "rgmii";
    phy-handle = <&phy0>;
    nvmem-cells = <&macaddr_factory_4>;
    nvmem-cell-names = "mac-address";
};

/* 工厂分区 MAC 地址 */
&factory {
    macaddr_factory_4: macaddr@4 {
        reg = <0x4 0x6>;
    };
};
EOF

clean_crlf "$DTS"

echo "=== MK ==="

if ! grep -q "mt7981b-sl3000-emmc" "$MK"; then
cat >> "$MK" << 'EOF'

define Device/mt7981b-sl3000-emmc
    DEVICE_VENDOR := SL
    DEVICE_MODEL := SL3000 eMMC Engineering Flagship
    DEVICE_DTS := mt7981b-sl3000-emmc
    DEVICE_PACKAGES := kmod-mt7981-firmware kmod-fs-ext4 block-mount
    IMAGE/sysupgrade.bin := append-kernel | append-rootfs | pad-rootfs | append-metadata
endef
TARGET_DEVICES += mt7981b-sl3000-emmc
EOF
fi

clean_crlf "$MK"

echo "=== CONFIG ==="

cat > "$CFG" << 'EOF'
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_mt7981b-sl3000-emmc=y

CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y

CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-btrfs=y
CONFIG_PACKAGE_block-mount=y
CONFIG_PACKAGE_f2fs-tools=y
CONFIG_PACKAGE_blkid=y
CONFIG_PACKAGE_losetup=y
CONFIG_PACKAGE_parted=y
CONFIG_PACKAGE_fdisk=y

CONFIG_DEVEL=y
CONFIG_CCACHE=y
CONFIG_CCACHE_SIZE="10G"
CONFIG_DISABLE_WERROR=y
CONFIG_USE_MKLIBS=y
CONFIG_STRIP_UPX=y

CONFIG_VERSION_CUSTOM=y
CONFIG_VERSION_PREFIX="SL3000-ImmortalWrt"
CONFIG_VERSION_SUFFIX="24.10-Engineering"
CONFIG_VERSION_NUMBER="20260126"

CONFIG_TARGET_ROOTFS_SQUASHFS=y
CONFIG_TARGET_ROOTFS_SQUASHFS_COMPRESSION_ZSTD=y
CONFIG_TARGET_ROOTFS_SQUASHFS_BLOCK_SIZE=256
CONFIG_TARGET_ROOTFS_PARTSIZE=1024

CONFIG_PACKAGE_ip-full=y
CONFIG_PACKAGE_sshd=y
CONFIG_PACKAGE_wget=y
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_htop=y
CONFIG_PACKAGE_dnsmasq-full=y
CONFIG_PACKAGE_wpad-basic-wolfssl=y
CONFIG_PACKAGE_openssh-sftp-server=y
CONFIG_PACKAGE_coreutils=y

CONFIG_SL3000_CUSTOM_CONFIG=y
EOF

clean_crlf "$CFG"

echo "=== DONE ==="
echo "$DTS"
echo "$MK"
echo "$CFG"
