#!/bin/bash
set -e

###############################################
# SL3000 三件套生成脚本（24.10 / 6.6 最终修复版）
# - 不删除任何目录
# - DTS / MK / CONFIG 全量生成
# - 路径完全正确
###############################################

REPO_ROOT="$(pwd)"

# === 路径定义（24.10 / 6.6 固定结构） ===
DTS_OUT="$REPO_ROOT/target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
MK_OUT="$REPO_ROOT/target/linux/mediatek/image/filogic.mk"
CFG_OUT="$REPO_ROOT/.config"

# === 确保 DTS 目录存在 ===
mkdir -p "$(dirname "$DTS_OUT")"

echo "=== 生成 DTS ==="
cat > "$DTS_OUT" << 'EOF'
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
};
EOF

echo "✔ DTS 已生成：$DTS_OUT"


# === 追加 MK（不会覆盖官方内容） ===
echo "=== 追加设备定义到 filogic.mk ==="

if ! grep -q "mt7981b-sl3000-emmc" "$MK_OUT"; then
cat >> "$MK_OUT" << 'EOF'

define Device/mt7981b-sl3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := SL3000 eMMC Flagship
  DEVICE_DTS := mt7981b-sl3000-emmc
  DEVICE_PACKAGES := kmod-usb3 kmod-mt7981-firmware \
        luci-app-passwall2 docker dockerd luci-app-dockerman
  IMAGE/sysupgrade.bin := append-kernel | append-rootfs | pad-rootfs | append-metadata
endef
TARGET_DEVICES += mt7981b-sl3000-emmc

EOF
    echo "✔ 已追加 SL3000 设备定义到 filogic.mk"
else
    echo "✔ filogic.mk 已包含 SL3000 设备定义，跳过追加"
fi


# === 生成 CONFIG ===
echo "=== 生成 .config ==="
cat > "$CFG_OUT" << 'EOF'
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_mt7981b-sl3000-emmc=y

CONFIG_PACKAGE_luci-app-passwall2=y
CONFIG_PACKAGE_docker=y
CONFIG_PACKAGE_dockerd=y
CONFIG_PACKAGE_luci-app-dockerman=y
EOF

echo "✔ .config 已生成：$CFG_OUT"

echo "=== 三件套生成完成（DTS / MK / CONFIG） ==="
