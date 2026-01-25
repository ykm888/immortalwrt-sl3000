#!/bin/bash
set -e

###############################################
# SL3000 三件套生成脚本（最终稳定版）
###############################################

# === 仓库根目录（绝不会为空） ===
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# === 三件套路径（绝不会为空） ===
DTS_OUT="$REPO_ROOT/target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
MK_OUT="$REPO_ROOT/target/linux/mediatek/image/filogic.mk"
CFG_OUT="$REPO_ROOT/.config"

echo "=== 路径检查 ==="
echo "DTS_OUT = $DTS_OUT"
echo "MK_OUT  = $MK_OUT"
echo "CFG_OUT = $CFG_OUT"

###############################################
# 1. 自动创建三件套（不存在 → 创建；存在 → 保留）
###############################################

# DTS
if [ ! -f "$DTS_OUT" ]; then
    echo "⚠ DTS 不存在，自动创建"
    mkdir -p "$(dirname "$DTS_OUT")"
    touch "$DTS_OUT"
fi

# MK
if [ ! -f "$MK_OUT" ]; then
    echo "⚠ MK 不存在，自动创建"
    mkdir -p "$(dirname "$MK_OUT")"
    touch "$MK_OUT"
fi

# CONFIG
if [ ! -f "$CFG_OUT" ]; then
    echo "⚠ CONFIG 不存在，自动创建"
    touch "$CFG_OUT"
fi

###############################################
# 2. 生成 DTS（覆盖写入）
###############################################
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

echo "✔ DTS 已生成"

###############################################
# 3. 追加 MK（不会覆盖官方）
###############################################
echo "=== 追加 MK ==="

if ! grep -q "Device/mt7981b-sl3000-emmc" "$MK_OUT"; then
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
    echo "✔ 已追加 SL3000 设备定义"
else
    echo "✔ MK 已包含 SL3000，跳过追加"
fi

###############################################
# 4. 生成 CONFIG（覆盖写入）
###############################################
echo "=== 生成 CONFIG ==="

cat > "$CFG_OUT" << 'EOF'
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_mt7981b-sl3000-emmc=y

CONFIG_PACKAGE_luci-app-passwall2=y
CONFIG_PACKAGE_docker=y
CONFIG_PACKAGE_dockerd=y
CONFIG_PACKAGE_luci-app-dockerman=y
EOF

echo "✔ CONFIG 已生成"

echo "=== 三件套生成完成（全部成功） ==="
