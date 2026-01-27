#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DTS_DIR="$ROOT/target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
MK="$ROOT/target/linux/mediatek/image/filogic.mk"
CFG="$ROOT/.config"

mkdir -p "$DTS_DIR"

# === DTS 文件 ===
cat > "$DTS_DIR/mt7981b-sl3000-emmc.dts" << 'EOF'
// SPDX-License-Identifier: GPL-2.0-only OR MIT
/dts-v1/;

/include/ "mt7981-rfb.dts"
/include/ <dt-bindings/gpio/gpio.h>
/include/ <dt-bindings/input/input.h>
/include/ <dt-bindings/leds/common.h>

/ {
    model = "SL SL3000 eMMC Engineering Flagship Edition";
    compatible = "sl,sl3000-emmc", "mediatek,mt7981b";
};

/* LED 覆盖 */
&leds {
    led_status: led-status {
        label = "sl:blue:status";
        gpios = <&pio 12 GPIO_ACTIVE_LOW>;
        linux,default-trigger = "heartbeat";
        default-state = "on";
    };
};

/* 按键覆盖 */
&keys {
    reset {
        label = "reset";
        gpios = <&pio 18 GPIO_ACTIVE_LOW>;
        linux,code = <KEY_RESTART>;
        debounce-interval = <60>;
    };
};

/* eMMC 控制器 */
&mmc0 {
    status = "okay";
    bus-width = <8>;
    mmc-hs200-1_8v;
    non-removable;
    cap-mmc-hw-reset;
    mediatek,mmc-wp-disable;
};

/* MAC 地址绑定 */
&gmac0 {
    nvmem-cells = <&macaddr_factory_4>;
    nvmem-cell-names = "mac-address";
};

&factory {
    macaddr_factory_4: macaddr@4 {
        reg = <0x4 0x6>;
    };
};
EOF

# === MK 文件 ===
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

# === CONFIG 文件 ===
cat > "$CFG" << 'EOF'
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_mt7981b-sl3000-emmc=y

CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y

CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_block-mount=y
CONFIG_PACKAGE_f2fs-tools=y
CONFIG_PACKAGE_blkid=y
CONFIG_PACKAGE_fdisk=y

CONFIG_DEVEL=y
CONFIG_CCACHE=y
CONFIG_DISABLE_WERROR=y

CONFIG_VERSION_CUSTOM=y
CONFIG_VERSION_PREFIX="SL3000-ImmortalWrt"
CONFIG_VERSION_SUFFIX="24.10-Engineering"
CONFIG_VERSION_NUMBER="20260127"

CONFIG_TARGET_ROOTFS_SQUASHFS=y
CONFIG_TARGET_ROOTFS_SQUASHFS_COMPRESSION_ZSTD=y
CONFIG_TARGET_ROOTFS_SQUASHFS_BLOCK_SIZE=256
CONFIG_TARGET_ROOTFS_PARTSIZE=1024
EOF

echo "三件套已生成："
echo " - DTS: $DTS_DIR/mt7981b-sl3000-emmc.dts"
echo " - MK : $MK"
echo " - CFG: $CFG"
