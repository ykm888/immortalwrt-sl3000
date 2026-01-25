#!/bin/bash
set -e

#########################################
# SL3000 三件套生成脚本（最终修复版）
#########################################

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 关键：统一在仓库根目录下工作
cd "$ROOT_DIR/.."

# 下面所有路径都相对于“仓库根”
DTS_OUT="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
MK_OUT="target/linux/mediatek/image/filogic.mk"
CFG_OUT="mt7981b-sl3000-emmc.config"

if [ -d "openwrt" ]; then
    OPENWRT_DIR="openwrt"
else
    OPENWRT_DIR="."
fi

mkdir -p "$(dirname "$DTS_OUT")"
mkdir -p "$(dirname "$MK_OUT")"

clean_file() {
    local f="$1"
    [ -f "$f" ] || return 0

    sed -i 's/\r$//' "$f"
    sed -i '1s/^\xEF\xBB\xBF//' "$f"
    sed -i 's/\xC2\xA0//g' "$f"
    sed -i 's/\xE2\x80\x8B//g' "$f"
    tr -d '\000-\011\013\014\016-\037\177' < "$f" > "$f.clean"
    mv "$f.clean" "$f"
}

echo "=== 🧬 生成DTS ==="
cat <<'EOF' > "$DTS_OUT"
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT
/dts-v1/;

#include "mt7981.dtsi"
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

echo "=== 🧬 生成MK ==="
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

echo "=== 🧬 生成配置 ==="
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

echo "=== 🧹清理隐藏字符（最终修复）==="
clean_file "$DTS_OUT"
clean_file "$MK_OUT"
clean_file "$CFG_OUT"

echo "=== 🔄 同步三件套到openwrt 源码 ==="

sync_file() {
    local SRC="$1"
    local DST="$OPENWRT_DIR/$1"
    mkdir -p "$(dirname "$DST")"
    if [ "$(realpath "$SRC")" = "$(realpath "$DST")" ]; then
        echo "⚠ 跳过同步（源文件与目标文件相同）：$SRC"
    else
        cp "$SRC" "$DST"
    fi
}

sync_file "$DTS_OUT"
sync_file "$MK_OUT"
sync_file "$CFG_OUT"

echo "✔ 三件套生成 + 清理 + 同步完成（最终修复版）"
