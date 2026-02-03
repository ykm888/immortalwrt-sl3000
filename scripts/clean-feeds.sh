#!/bin/bash
# ============================================================
# SL3000 V16.6 旗舰延续修复版 - 全量逻辑合一
# ============================================================
set -e

echo ">>> [SL3000 V16.6] 正在延续历史修复逻辑..."

[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(cd ..; pwd)
SRC_DIR="${GITHUB_WORKSPACE}/custom-config"

# 1. 延续：定位源文件
DTS_SRC=$(find "$SRC_DIR" -type f -name "*mt7981b-sl3000-emmc.dts" | head -n 1)
MK_SRC=$(find "$SRC_DIR" -type f -name "filogic.mk" | head -n 1)
CONF_SRC=$(find "$SRC_DIR" -type f -name "*sl3000.config" | head -n 1)

# 2. 延续修复：DTS 物理合并（解决 Include 路径 Error 1）
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
# 物理嵌入 SoC 核心定义 (彻底解决 .dtsi 找不到的问题)
[ -f "$INC_DIR/mt7981.dtsi" ] && grep -v "/dts-v1/;" "$INC_DIR/mt7981.dtsi" | grep -v "#include" >> "$DTS_DEST.tmp"
[ -f "$INC_DIR/mt7981b.dtsi" ] && grep -v "/dts-v1/;" "$INC_DIR/mt7981b.dtsi" | grep -v "#include" >> "$DTS_DEST.tmp"
# 附加用户自定义 DTS 内容
tr -d '\r' < "$DTS_SRC" | grep -v "/dts-v1/;" | grep -v "mt7981.dtsi" | grep -v "mt7981b.dtsi" >> "$DTS_DEST.tmp"
cp -f "$DTS_DEST.tmp" "$DTS_DEST"

# 3. 延续修复：Feeds 协议脱敏（解决 Username for github 报错）
git config --global url."https://github.com/".insteadOf "git://github.com/" || true
git config --global url."https://github.com/".insteadOf "git@github.com:" || true
sed -i '/passwall/d' feeds.conf.default
echo "src-git-full passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages.git;main" >> feeds.conf.default
echo "src-git-full passwall https://github.com/xiaorouji/openwrt-passwall.git;main" >> feeds.conf.default
./scripts/feeds update -a && ./scripts/feeds install -a

# 4. 延续修复：PHP/Zabbix 依赖补丁
[ -d "feeds/packages/admin/zabbix" ] && find feeds/packages/admin/zabbix -name Makefile -exec sed -i 's/select PACKAGE_php8/depends on PACKAGE_php8/g' {} +

# 5. 延续修复：配置静默锁定（解决 Terminal unknown 报错）
[ -f "$CONF_SRC" ] && cat "$CONF_SRC" > .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" >> .config
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024" >> .config
make defconfig

echo "✅ [延续成功] V16.6 环境已物理锁定！"
