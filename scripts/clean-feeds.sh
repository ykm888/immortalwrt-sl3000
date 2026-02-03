#!/bin/bash
# ============================================================
# SL3000 V16.5 旗舰全量修复版 (锁定版)
# ============================================================
set -e

[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(cd ..; pwd)
SRC_DIR="${GITHUB_WORKSPACE}/custom-config"
DTS_SRC=$(find "$SRC_DIR" -type f -name "*mt7981b-sl3000-emmc.dts" | head -n 1)

# --- 1. DTS 物理合并 (延续绝杀路径报错逻辑) ---
K_DIR=$(ls -d target/linux/mediatek/files-* 2>/dev/null | sort -V | tail -n 1)
[ -z "$K_DIR" ] && K_DIR="target/linux/mediatek/files-6.6"
DTS_DEST="$K_DIR/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
INC_DIR="$K_DIR/arch/arm64/boot/dts/mediatek"

mkdir -p "$(dirname "$DTS_DEST")"
cat <<EOT > "$DTS_DEST.tmp"
/dts-v1/;
#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/leds/common.h>
EOT
[ -f "$INC_DIR/mt7981.dtsi" ] && grep -v "/dts-v1/;" "$INC_DIR/mt7981.dtsi" | grep -v "#include" >> "$DTS_DEST.tmp"
[ -f "$INC_DIR/mt7981b.dtsi" ] && grep -v "/dts-v1/;" "$INC_DIR/mt7981b.dtsi" | grep -v "#include" >> "$DTS_DEST.tmp"
tr -d '\r' < "$DTS_SRC" | grep -v "/dts-v1/;" | grep -v "mt7981.dtsi" | grep -v "mt7981b.dtsi" >> "$DTS_DEST.tmp"
cp -f "$DTS_DEST.tmp" "$DTS_DEST"

# --- 2. Feeds 强制同步 (延续原文) ---
git config --global url."https://github.com/".insteadOf "git://github.com/" || true
sed -i '/passwall/d' feeds.conf.default
echo "src-git-full passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages.git;main" >> feeds.conf.default
echo "src-git-full passwall https://github.com/xiaorouji/openwrt-passwall.git;main" >> feeds.conf.default
for i in {1..3}; do ./scripts/feeds update -a && break || sleep 5; done
./scripts/feeds install -a

# --- 3. 配置与依赖补丁 (延续原文) ---
CONF_SRC=$(find "$SRC_DIR" -type f -name "*sl3000.config" | head -n 1)
[ -f "$CONF_SRC" ] && cat "$CONF_SRC" > .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" >> .config
[ -d "feeds/packages/admin/zabbix" ] && find feeds/packages/admin/zabbix -name Makefile -exec sed -i 's/select PACKAGE_php8/depends on PACKAGE_php8/g' {} +
make defconfig

echo "✅ [任务完成] V16.5 锁定修复成功！"
