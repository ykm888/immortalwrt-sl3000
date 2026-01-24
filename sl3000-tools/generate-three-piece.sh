#!/bin/bash
set -e

#########################################
# SL3000 三件套生成脚本（最终修复版）
# 解决：隐藏字符、零宽空格、NBSP、CR、BOM 污染
#########################################

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

DTS_OUT="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
MK_OUT="target/linux/mediatek/image/filogic.mk"
CFG_OUT="mt7981b-sl3000-emmc.config"

mkdir -p "$(dirname "$DTS_OUT")"
mkdir -p "$(dirname "$MK_OUT")"

#########################################
# 1. 生成 DTS（无 BOM / 无隐藏字符）
#########################################
echo "=== 🧬 生成 DTS ==="

cat <<'EOF' > "$DTS_OUT"
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
};
EOF

#########################################
# 2. 生成 MK（无隐藏字符）
#########################################
echo "=== 🧬 生成 MK ==="

cat <<'EOF' > "$MK_OUT"
define Device/mt7981b-sl3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := SL3000 eMMC Flagship
  DEVICE_PACKAGES := kmod-usb3 kmod-mt7981-firmware \
        luci-app-passwall2 docker dockerd luci-app-dockerman
  IMAGE/sysupgrade.bin := append-kernel | append-rootfs | pad-rootfs | append-metadata
endef
TARGET_DEVICES += mt7981b-sl3000-emmc
EOF

#########################################
# 3. 生成 CONFIG（无隐藏字符）
#########################################
echo "=== 🧬 生成 CONFIG ==="

cat <<'EOF' > "$CFG_OUT"
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_mt7981b-sl3000-emmc=y
CONFIG_LINUX_6_6=y

CONFIG_PACKAGE_luci-app-passwall2=y
CONFIG_PACKAGE_docker=y
CONFIG_PACKAGE_dockerd=y
CONFIG_PACKAGE_luci-app-dockerman=y
EOF

#########################################
# 4. 清理隐藏字符（核心修复）
#########################################
echo "=== 🧹 清理隐藏字符（最终修复） ==="

clean_file() {
    sed -i 's/\r$//' "$1"                     # CR
    sed -i '1s/^\xEF\xBB\xBF//' "$1"          # BOM
    sed -i 's/\xC2\xA0//g' "$1"               # NBSP
    sed -i 's/\xE2\x80\x8B//g' "$1"           # 零宽空格
    sed -i 's/[^[:print:]\t ]//g' "$1"        # 其他不可见字符
}

clean_file "$DTS_OUT"
clean_file "$MK_OUT"
clean_file "$CFG_OUT"

echo "✔ 三件套生成完成（无隐藏字符）"
