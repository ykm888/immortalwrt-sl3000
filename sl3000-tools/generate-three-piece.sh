#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG="$SCRIPT_DIR/sl3000-three-piece.log"
> "$LOG"
exec > >(tee -a "$LOG") 2>&1

DTS_DIR="$ROOT/target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
DTS="$DTS_DIR/mt7981b-sl3000-emmc.dts"
MK="$ROOT/target/linux/mediatek/image/filogic.mk"
CFG="$ROOT/.config"

mkdir -p "$DTS_DIR"

clean() {
    [ ! -f "$1" ] && return 0
    sed -i 's/\r$//' "$1"
    sed -i 's/[[:cntrl:]]//g' "$1"
}

echo "=== Stage 1: Pre-clean MK ==="

if grep -q "^define Device/mt7981b-sl3000-emmc$" "$MK"; then
    sed -i '/^define Device\/mt7981b-sl3000-emmc$/,/^endef$/d' "$MK"
fi

echo "=== Stage 2: Generate DTS ==="

cat > "$DTS" << 'EOF'
// SPDX-License-Identifier: GPL-2.0-only OR MIT
/dts-v1/;

#include "mt7981.dtsi"
#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/leds/common.h>

/ {
    model = "SL3000 eMMC Engineering Flagship";
    compatible = "sl,sl3000-emmc", "mediatek,mt7981b";

    aliases {
        serial0 = &uart0;
        led-boot = &led_status;
        led-failsafe = &led_status;
        led-running = &led_status;
        led-upgrade = &led_status;
    };

    chosen { stdout-path = "serial0:115200n8"; };

    leds {
        compatible = "gpio-leds";
        status: led-0 {
            label = "sl:blue:status";
            gpios = <&pio 12 GPIO_ACTIVE_LOW>;
            linux,default-trigger = "heartbeat";
            default-state = "on";
        };
    };

    keys {
        compatible = "gpio-keys";
        reset {
            label = "reset";
            gpios = <&pio 18 GPIO_ACTIVE_LOW>;
            linux,code = <KEY_RESTART>;
            debounce-interval = <60>;
        };
    };
};

&uart0 { status = "okay"; };

&mmc {
    status = "okay";
    bus-width = <8>;
    mmc-hs200-1_8v;
    non-removable;
    cap-mmc-hw-reset;
};

&gmac0 {
    status = "okay";
    phy-mode = "2500base-x";
    phy-handle = <&phy0>;
};

&switch { status = "okay"; };

&pcie { status = "okay"; };
EOF

clean "$DTS"

echo "=== Stage 3: Generate MK (TAB correct) ==="

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

clean "$MK"

echo "=== Stage 4: Generate CONFIG ==="

cat > "$CFG" << 'EOF'
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_mt7981b-sl3000-emmc=y

CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y

CONFIG_PACKAGE_luci-app-passwall2=y
CONFIG_PACKAGE_luci-app-ssr-plus=y
CONFIG_PACKAGE_xray-core=y
CONFIG_PACKAGE_v2ray-core=y
CONFIG_PACKAGE_hysteria2=y
CONFIG_PACKAGE_ipset=y
CONFIG_PACKAGE_iptables-mod-tproxy=y
CONFIG_PACKAGE_iptables-mod-nat-extra=y
CONFIG_PACKAGE_ip6tables-mod-nat=y
CONFIG_PACKAGE_iproute2=y

CONFIG_PACKAGE_docker=y
CONFIG_PACKAGE_dockerd=y
CONFIG_PACKAGE_luci-app-dockerman=y
CONFIG_PACKAGE_docker-compose=y
CONFIG_PACKAGE_containerd=y
CONFIG_PACKAGE_runc=y

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
CONFIG_VERSION_NUMBER="20251201"

CONFIG_TARGET_ROOTFS_SQUASHFS=y
CONFIG_TARGET_ROOTFS_SQUASHFS_COMPRESSION_ZSTD=y
CONFIG_TARGET_ROOTFS_SQUASHFS_BLOCK_SIZE=256k
CONFIG_TARGET_ROOTFS_PARTSIZE=1024

CONFIG_PACKAGE_ip-full=y
CONFIG_PACKAGE_sshd=y
CONFIG_PACKAGE_wget=y
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_htop=y
CONFIG_PACKAGE_dnsmasq_full_remove_resolvconf=y
CONFIG_PACKAGE_wpad-basic-wolfssl=y
CONFIG_PACKAGE_openssh-sftp-server=y
CONFIG_PACKAGE_coreutils=y

CONFIG_SL3000_CUSTOM_CONFIG=y
EOF

clean "$CFG"

echo "=== Stage 5: Pre-check Stage 1 (before toolchain) ==="

if [ ! -f "$DTS" ]; then echo "DTS missing"; exit 1; fi
dtc -I dts -O dtb "$DTS" -o /dev/null || { echo "DTS syntax error"; exit 1; }

if ! grep -q "^define Device/mt7981b-sl3000-emmc$" "$MK"; then echo "MK invalid"; exit 1; fi
if ! grep -q "CONFIG_TARGET_mediatek_filogic_DEVICE_mt7981b-sl3000-emmc=y" "$CFG"; then echo "CONFIG invalid"; exit 1; fi

echo "=== Stage 6: Pre-check Stage 2 (after toolchain) ==="

make -j1 V=s target/linux/compile >/dev/null 2>&1 || true

if ! grep -R "mt7981b-sl3000-emmc" -n build_dir/target-*/linux-*/profiles.json >/dev/null 2>&1; then
    echo "Device not registered"; exit 1
fi

echo "=== Three-piece generation complete ==="
echo "$DTS"
echo "$MK"
echo "$CFG"
