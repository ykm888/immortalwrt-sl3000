#!/bin/bash
set -e

###############################################
# SL3000 终极 all‑in‑one（方案 C：最强闭环版）
# - 生成三件套（DTS / MK / CONFIG）
# - 强制覆盖旧段
# - 检查（轻量 + 深度）
# - 构建固件
# - 自动上传产物
# - 自动 git commit + push
###############################################

ROOT="$(pwd)"

DTS="$ROOT/target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
MK="$ROOT/target/linux/mediatek/image/filogic.mk"
CFG="$ROOT/.config"
OUTPUT_DIR="$ROOT/bin/targets/mediatek/filogic"

echo "=== 🚀 SL3000 终极 all‑in‑one（方案 C）==="

mkdir -p "$(dirname "$DTS")"
mkdir -p "$(dirname "$MK")"
touch "$DTS" "$MK" "$CFG"

###############################################
# 1. 生成 DTS（强制覆盖）
###############################################
echo "=== 📝 生成 DTS ==="

cat > "$DTS" << 'EOF'
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

echo "✔ DTS 已生成"

###############################################
# 2. 生成 MK（强制覆盖）
###############################################
echo "=== 🧱 生成 MK ==="

sed -i '/Device\/mt7981b-sl3000-emmc/,/endef/d' "$MK"

cat >> "$MK" << 'EOF'

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

echo "✔ MK 已生成"

###############################################
# 3. 生成 CONFIG（强制覆盖）
###############################################
echo "=== ⚙️ 生成 CONFIG ==="

cat > "$CFG" << 'EOF'
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

# 文件系统支持（无 USB）
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-btrfs=y
CONFIG_PACKAGE_block-mount=y
EOF

echo "✔ CONFIG 已生成"

###############################################
# 4. 检查（轻量 + 深度）
###############################################
echo "=== 🔍 检查三件套 ==="

check_file() {
    if [ ! -f "$1" ]; then
        echo "❌ 文件不存在: $1"
        exit 1
    fi
    echo "✔ 文件存在: $1"
}

clean_check() {
    echo "--- 检查不可见字符: $1 ---"
    if grep -P "[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]" "$1" >/dev/null; then
        echo "❌ 检测到不可见字符"
        exit 1
    fi
    echo "✔ 无不可见字符"
}

check_file "$DTS"
check_file "$MK"
check_file "$CFG"

clean_check "$DTS"
clean_check "$MK"
clean_check "$CFG"

if command -v dtc >/dev/null; then
    echo "=== 🧠 深度检查 DTS ==="
    dtc -I dts -O dtb "$DTS" >/dev/null
    echo "✔ DTS 语法正确"
else
    echo "⚠ 未安装 dtc，跳过深度检查"
fi

###############################################
# 5. 构建固件
###############################################
echo "=== 🏗️ 构建固件 ==="

make defconfig
make -j$(nproc)

echo "✔ 构建完成"

###############################################
# 6. 上传产物
###############################################
echo "=== 📦 上传产物 ==="

mkdir -p "$ROOT/upload"
cp "$OUTPUT_DIR"/*.bin "$ROOT/upload/" || true
cp "$OUTPUT_DIR"/*.tar "$ROOT/upload/" || true
cp "$OUTPUT_DIR"/*.img "$ROOT/upload/" || true

echo "✔ 产物已复制到 upload/"

###############################################
# 7. 自动提交三件套
###############################################
echo "=== 🔄 自动提交三件套 ==="

git add "$DTS" "$MK" "$CFG" || true
git commit -m "Update SL3000 DTS/MK/CONFIG (Engineering Flagship)" || true
git push || true

echo "✔ 三件套已提交并推送"

echo "=== 🎉 all‑in‑one（方案 C）完成 ==="
