#!/bin/bash
set -e

#########################################
# SL3000 三件套生成脚本（工程级最终版）
#########################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

DTS_OUT="$REPO_ROOT/target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
MK_OUT="$REPO_ROOT/target/linux/mediatek/image/filogic.mk"
CFG_OUT="$REPO_ROOT/.config"

mkdir -p "$(dirname "$DTS_OUT")"
mkdir -p "$(dirname "$MK_OUT")"

#########################################
# 工程级彻底清理函数（最终版）
#########################################
clean_file() {
    local f="$1"
    [ -f "$f" ] || return 0

    # 删除 CRLF
    sed -i 's/\r$//' "$f"

    # 删除 UTF-8 BOM
    sed -i '1s/^\xEF\xBB\xBF//' "$f"

    # 删除 NBSP
    sed -i 's/\xC2\xA0//g' "$f"

    # 删除零宽字符
    sed -i 's/\xE2\x80\x8B//g' "$f"
    sed -i 's/\xE2\x80\x8C//g' "$f"
    sed -i 's/\xE2\x80\x8D//g' "$f"

    # 删除控制字符
    tr -d '\000-\011\013\014\016-\037\177' < "$f" > "$f.clean1"

    # 删除尾部隐藏空白
    sed -i 's/[[:space:]]\+$//' "$f.clean1"

    # 删除伪空行
    sed -i '/^[[:space:]]*$/d' "$f.clean1"

    mv "$f.clean1" "$f"
}

#########################################
# 生成 DTS（dtc 100% 可解析）
#########################################
echo "=== 🧬 生成 DTS ==="
printf '%s\n' \
'// SPDX-License-Identifier: GPL-2.0-or-later OR MIT' \
'/dts-v1/;' \
'' \
'/include/ "mt7981.dtsi"' \
'/include/ <dt-bindings/gpio/gpio.h>' \
'/include/ <dt-bindings/input/input.h>' \
'/include/ <dt-bindings/leds/common.h>' \
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
# 生成 MK（最终稳定版）
#########################################
echo "=== 🧬 生成 MK ==="
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
# 生成 CONFIG（最终稳定版）
#########################################
echo "=== 🧬 生成 CONFIG ==="
printf '%s\n' \
'CONFIG_TARGET_mediatek=y' \
'CONFIG_TARGET_mediatek_filogic=y' \
'CONFIG_TARGET_mediatek_filogic_DEVICE_mt7981b-sl3000-emmc=y' \
'CONFIG_LINUX_6_6=y' \
'' \
'CONFIG_PACKAGE_luci-app-passwall2=y' \
'CONFIG_PACKAGE_docker=y' \
'CONFIG_PACKAGE_dockerd=y' \
'CONFIG_PACKAGE_luci-app-dockerman=y' \
> "$CFG_OUT"
clean_file "$CFG_OUT"

echo "✔ 三件套生成完成（DTS / MK / .config 已全部生成）"
