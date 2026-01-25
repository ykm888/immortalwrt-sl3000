#!/bin/bash
set -e

#########################################
# SL3000 三件套生成脚本（工程级旗舰版）
#########################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

DTS_OUT="$REPO_ROOT/target/linux/mediatek/files-6.12/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
MK_OUT="$REPO_ROOT/target/linux/mediatek/image/filogic.mk"
CFG_OUT="$REPO_ROOT/.config"

mkdir -p "$(dirname "$DTS_OUT")"
mkdir -p "$(dirname "$MK_OUT")"

#########################################
# 工程级彻底清理函数（旗舰版）
#########################################
clean_file() {
    local f="$1"
    [ -f "$f" ] || return 0

    sed -i 's/\r$//' "$f"
    sed -i '1s/^\xEF\xBB\xBF//' "$f"
    sed -i 's/\xC2\xA0//g' "$f"
    sed -i 's/\xE2\x80\x8B//g' "$f"
    sed -i 's/\xE2\x80\x8C//g' "$f"
    sed -i 's/\xE2\x80\x8D//g' "$f"

    tr -d '\000-\011\013\014\016-\037\177' < "$f" > "$f.clean1"
    sed -i 's/[[:space:]]\+$//' "$f.clean1"
    sed -i '/^[[:space:]]*$/d' "$f.clean1"

    mv "$f.clean1" "$f"
}

#########################################
# 生成 DTS（cpp 可预处理）
#########################################
printf '%s\n' \
'// SPDX-License-Identifier: GPL-2.0-or-later OR MIT' \
'/dts-v1/;' \
'' \
'#include "mt7981.dtsi"' \
'#include <dt-bindings/gpio/gpio.h>' \
'#include <dt-bindings/input/input.h>' \
'#include <dt-bindings/leds/common.h>' \
'' \
'/ {' \
'    model = "SL3000 eMMC Flagship";' \
'    compatible = "sl,sl3000-emmc", "mediatek,mt7981b";' \
'' \
'    aliases {' \
'        serial0 = &uart0;' \
'        led-boot = &led_status;' \
'        led-failsafe = &led_status;' \
'        led-running = &led_status;' \
'        led-upgrade = &led_status;' \
'    };' \
'' \
'    chosen {' \
'        stdout-path = "serial0:115200n8";' \
'    };' \
'};' \
> "$DTS_OUT"
clean_file "$DTS_OUT"

#########################################
# 生成 MK（旗舰版）
#########################################
printf '%s\n' \
'define Device/mt7981b-sl3000-emmc' \
'  DEVICE_VENDOR := SL' \
'  DEVICE_MODEL := SL3000 eMMC Flagship' \
'  DEVICE_PACKAGES := kmod-usb3 kmod-mt7981-firmware \' \
'        luci-app-passwall2 docker dockerd luci-app-dockerman' \
'  IMAGE/sysupgrade.bin := append-kernel | append-rootfs | pad-rootfs | append-metadata' \
'endef' \
'' \
'TARGET_DEVICES += mt7981b-sl3000-emmc' \
> "$MK_OUT"
clean_file "$MK_OUT"

#########################################
# 生成 CONFIG（旗舰版）
#########################################
printf '%s\n' \
'CONFIG_TARGET_mediatek=y' \
'CONFIG_TARGET_mediatek_filogic=y' \
'CONFIG_TARGET_mediatek_filogic_DEVICE_mt7981b-sl3000-emmc=y' \
'CONFIG_LINUX_6_12=y' \
'' \
'CONFIG_PACKAGE_luci-app-passwall2=y' \
'CONFIG_PACKAGE_docker=y' \
'CONFIG_PACKAGE_dockerd=y' \
'CONFIG_PACKAGE_luci-app-dockerman=y' \
> "$CFG_OUT"
clean_file "$CFG_OUT"

echo "✔ 三件套生成完成（旗舰版）"
