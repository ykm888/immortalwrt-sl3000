#!/bin/bash
set -euo pipefail

# ⭐ 关键修复：在 CI 中，工作目录是 openwrt-src
# 所以优先使用当前目录作为 ROOT
if [ -d "./target/linux/mediatek" ]; then
  ROOT="$(pwd)"
else
  ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fi
cd "$ROOT"

SCRIPT_DIR="$ROOT/sl3000-tools"
LOG="$SCRIPT_DIR/sl3000-three-piece-master.log"
mkdir -p "$SCRIPT_DIR"
: > "$LOG"
exec > >(tee -a "$LOG") 2>&1

echo "[INFO] ROOT = $ROOT"

TAB=$'\t'

###############################################
# ⭐ 24.10 / 6.6 使用固定 DTS 路径（不再 files-*）
###############################################
DTS_DIR="$ROOT/target/linux/mediatek/dts"
DTS="$DTS_DIR/mt7981b-sl-3000-emmc.dts"   # ⭐ CI 要的名字
MK="$ROOT/target/linux/mediatek/image/mt7981.mk"
CFG_DIR="$ROOT/sl3000-tools"
CFG="$CFG_DIR/sl3000-full-config.txt"

mkdir -p "$DTS_DIR" "$CFG_DIR"

clean_crlf() { sed -i 's/\r$//' "$1" 2>/dev/null || true; }

###############################################
# Stage 1：生成 DTS（保持你原结构 + 修复路径）
###############################################
echo "=== Stage 1: Generate DTS (24.10 / 6.6) ==="

cat > "$DTS" << 'EOF'
/* SPDX-License-Identifier: GPL-2.0-only OR MIT */
/dts-v1/;

#include "mt7981.dtsi"
#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/leds/common.h>

/ {
    model = "SL SL3000 eMMC Engineering Flagship Edition";
    compatible = "sl,sl3000-emmc", "mediatek,mt7981b";

    aliases {
        serial0 = &uart0;
        led-boot = &led_status;
        led-failsafe = &led_status;
        led-running = &led_status;
        led-upgrade = &led_status;
        label-mac-device = &gmac0;
    };

    chosen {
        stdout-path = "serial0:115200n8";
    };

    leds {
        compatible = "gpio-leds";

        led_status: led-status {
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

&mmc0 {
    status = "okay";
    bus-width = <8>;
    mmc-hs200-1_8v;
    non-removable;
    cap-mmc-hw-reset;
    mediatek,mmc-wp-disable;
};

&gmac0 {
    status = "okay";
    phy-mode = "rgmii";
    phy-handle = <&phy0>;
    nvmem-cells = <&macaddr_factory_4>;
    nvmem-cell-names = "mac-address";
};

&mdio_bus {
    status = "okay";
    phy0: ethernet-phy@0 { reg = <0>; };
    phy1: ethernet-phy@1 { reg = <1>; };
    phy2: ethernet-phy@2 { reg = <2>; };
    phy3: ethernet-phy@3 { reg = <3>; };
    phy4: ethernet-phy@4 { reg = <4>; };
};

&switch {
    status = "okay";
    ports {
        #address-cells = <1>;
        #size-cells = <0>;
        port@0 { reg = <0>; label = "wan"; phy-handle = <&phy0>; };
        port@1 { reg = <1>; label = "lan1"; phy-handle = <&phy1>; };
        port@2 { reg = <2>; label = "lan2"; phy-handle = <&phy2>; };
        port@3 { reg = <3>; label = "lan3"; phy-handle = <&phy3>; };
    };
};

/* WiFi 节点 */
&pcie {
    status = "okay";
    wifi@0,0 {
        compatible = "mediatek,mt7996e";
        reg = <0x0000 0 0 0 0>;
        mediatek,mtd-eeprom = <&factory 0x0>;
        interrupt-parent = <&pcie_intc>;
        interrupts = <0 IRQ_TYPE_LEVEL_HIGH>;
    };
};

&pcie1 {
    status = "okay";
    wifi2g@0,0 {
        compatible = "mediatek,mt7991e";
        reg = <0x0000 0 0 0 0>;
        mediatek,mtd-eeprom = <&factory 0x8000>;
        interrupt-parent = <&pcie_intc>;
        interrupts = <1 IRQ_TYPE_LEVEL_HIGH>;
    };
};

&factory {
    macaddr_factory_4: macaddr@4 { reg = <0x4 0x6>; };
};
EOF

clean_crlf "$DTS"

###############################################
# Stage 2：生成 MK（保持你原结构 + 修复路径）
###############################################
echo "=== Stage 2: Ensure MK device (24.10 / 6.6) ==="

if ! grep -q "Device/mt7981b-sl-3000-emmc" "$MK"; then
  cat >> "$MK" << EOF

define Device/mt7981b-sl-3000-emmc
${TAB}DEVICE_VENDOR := SL
${TAB}DEVICE_MODEL := SL3000 eMMC Engineering Flagship Edition
${TAB}DEVICE_DTS := mt7981b-sl-3000-emmc
${TAB}DEVICE_PACKAGES := kmod-fs-ext4 block-mount
${TAB}IMAGES := sysupgrade.bin
${TAB}IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += mt7981b-sl-3000-emmc
EOF
fi

clean_crlf "$MK"

###############################################
# Stage 3：生成 CONFIG（对齐 CI）
###############################################
echo "=== Stage 3: Generate CONFIG (24.10 / 6.6) ==="

cat > "$CFG" << 'EOF'
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_mt7981b-sl-3000-emmc=y

CONFIG_TARGET_ROOTFS_SQUASHFS=y
CONFIG_TARGET_IMAGES_GZIP=y

CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y

CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_block-mount=y
EOF

clean_crlf "$CFG"

###############################################
# Stage 4：校验
###############################################
echo "=== Stage 4: Validation ==="

[ -s "$DTS" ] || { echo "[FATAL] DTS missing"; exit 1; }
[ -s "$MK" ]  || { echo "[FATAL] MK missing"; exit 1; }
[ -s "$CFG" ] || { echo "[FATAL] CONFIG missing"; exit 1; }

echo "=== Three-piece generation complete (24.10 / 6.6) ==="
echo "[OUT] DTS: $DTS"
echo "[OUT] MK : $MK"
echo "[OUT] CFG: $CFG"
