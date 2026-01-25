#!/bin/bash
set -e

###############################################
# SL3000 三件套生成脚本（24.10 工程级最强旗舰版 · 最终修复版）
# - DTS：官方结构 + 工程旗舰版
# - MK：强制覆盖旧段（无 USB + Docker + Passwall2 + SSR Plus+）
# - CONFIG：覆盖生成（Docker + Passwall2 + SSR Plus+）
# - 三件套自动创建 / 覆盖
# - 24.10 / Linux 6.6 固定结构
###############################################

# === 仓库根目录（绝不会为空） ===
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# === 三件套路径（固定） ===
DTS_OUT="$REPO_ROOT/target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
MK_OUT="$REPO_ROOT/target/linux/mediatek/image/filogic.mk"
CFG_OUT="$REPO_ROOT/.config"

echo "=== 路径检查 ==="
echo "DTS_OUT = $DTS_OUT"
echo "MK_OUT  = $MK_OUT"
echo "CFG_OUT = $CFG_OUT"

###############################################
# 1. 自动创建三件套（不存在 → 创建）
###############################################

mkdir -p "$(dirname "$DTS_OUT")"
mkdir -p "$(dirname "$MK_OUT")"

touch "$DTS_OUT"
touch "$MK_OUT"
touch "$CFG_OUT"

###############################################
# 2. 生成 DTS（官方结构 + 工程旗舰版）
###############################################
echo "=== 生成 DTS（官方工程旗舰版） ==="

cat > "$DTS_OUT" << 'EOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT
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
};
EOF

echo "✔ DTS 已生成（官方工程旗舰版）"

###############################################
# 3. 生成 MK（强制覆盖旧段）
###############################################
echo "=== 生成 MK（工程级最强旗舰版） ==="

# 删除旧的 SL3000 设备段
sed -i '/Device\/mt7981b-sl3000-emmc/,/endef/d' "$MK_OUT"

# 追加新的旗舰版设备段
cat >> "$MK_OUT" << 'EOF'

define Device/mt7981b-sl3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := SL3000 eMMC Engineering Flagship
  DEVICE_DTS := mt7981b-sl3000-emmc
  DEVICE_PACKAGES := kmod-mt7981-firmware \
        luci-app-passwall2 docker dockerd luci-app-dockerman \
        luci-app-ssr-plus xray-core \
        shadowsocksr-libev-ssr-local shadowsocksr-libev-ssr-redir \
        kmod-fs-ext4 kmod-fs-btrfs block-mount
  IMAGE/sysupgrade.bin := append-kernel | append-rootfs | pad-rootfs | append-metadata
endef
TARGET_DEVICES += mt7981b-sl3000-emmc

EOF

echo "✔ MK 已生成（工程级最强旗舰版）"

###############################################
# 4. 生成 CONFIG（Docker + Passwall2 + SSR Plus+）
###############################################
echo "=== 生成 CONFIG（Docker + Passwall2 + SSR Plus+） ==="

cat > "$CFG_OUT" << 'EOF'
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_mt7981b-sl3000-emmc=y

# Passwall2
CONFIG_PACKAGE_luci-app-passwall2=y

# Docker
CONFIG_PACKAGE_docker=y
CONFIG_PACKAGE_dockerd=y
CONFIG_PACKAGE_luci-app-dockerman=y

# SSR Plus+
CONFIG_PACKAGE_luci-app-ssr-plus=y
CONFIG_PACKAGE_shadowsocksr-libev-ssr-local=y
CONFIG_PACKAGE_shadowsocksr-libev-ssr-redir=y
CONFIG_PACKAGE_xray-core=y

# 文件系统支持（旗舰版，无 USB）
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-btrfs=y
CONFIG_PACKAGE_block-mount=y
EOF

echo "✔ CONFIG 已生成（Docker + Passwall2 + SSR Plus+）"

echo "=== 三件套生成完成（24.10 工程级最强旗舰版 · 最终修复版） ==="
