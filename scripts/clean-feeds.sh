#!/bin/bash
# ============================================================
# SL3000 V16.5 旗舰全量修复版：【原文逻辑照抄 + 历次错误全修】
# 修复：DTS路径缺失、Feeds断连、PHP依赖、Terminal终端报错
# ============================================================
set -e

echo ">>> [SL3000 V16.5] 深度初始化与多重修复开始..."

# --- 1. 定位源文件 (延续 V16.5 原文) ---
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(cd ..; pwd)
SRC_DIR="${GITHUB_WORKSPACE}/custom-config"

DTS_SRC=$(find "$SRC_DIR" -type f -name "*mt7981b-sl3000-emmc.dts" | head -n 1)
MK_SRC=$(find "$SRC_DIR" -type f -name "filogic.mk" | head -n 1)
CONF_SRC=$(find "$SRC_DIR" -type f -name "*sl3000.config" | head -n 1)

# --- 2. DTS 物理合并修复 (延续之前解决 Error 1 的核心) ---
K_DIR=$(ls -d target/linux/mediatek/files-* 2>/dev/null | sort -V | tail -n 1)
[ -z "$K_DIR" ] && K_DIR="target/linux/mediatek/files-6.6"
DTS_DEST="$K_DIR/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
INC_DIR="$K_DIR/arch/arm64/boot/dts/mediatek"

mkdir -p "$(dirname "$DTS_DEST")"
echo ">>> [修复1] 执行 DTS 内容物理合并，消除路径依赖..."
cat <<EOT > "$DTS_DEST.tmp"
/dts-v1/;
#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/leds/common.h>
EOT
# 抓取 SoC 定义文本内容并粘贴 (物理避开路径搜索)
[ -f "$INC_DIR/mt7981.dtsi" ] && grep -v "/dts-v1/;" "$INC_DIR/mt7981.dtsi" | grep -v "#include" >> "$DTS_DEST.tmp"
[ -f "$INC_DIR/mt7981b.dtsi" ] && grep -v "/dts-v1/;" "$INC_DIR/mt7981b.dtsi" | grep -v "#include" >> "$DTS_DEST.tmp"
# 追加自定义 DTS 并清理格式
tr -d '\r' < "$DTS_SRC" | grep -v "/dts-v1/;" | grep -v "mt7981.dtsi" | grep -v "mt7981b.dtsi" >> "$DTS_DEST.tmp"
cp -f "$DTS_DEST.tmp" "$DTS_DEST"

# --- 3. Feeds 强制自愈 (延续之前成功的补丁) ---
echo ">>> [修复2] 正在重构 Feeds 插件源并强制同步..."
git config --global url."https://github.com/".insteadOf git://github.com/
sed -i '/passwall/d' feeds.conf.default
echo "src-git-full passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages.git;main" >> feeds.conf.default
echo "src-git-full passwall https://github.com/xiaorouji/openwrt-passwall.git;main" >> feeds.conf.default
for i in {1..3}; do ./scripts/feeds update -a && break || sleep 5; done
./scripts/feeds install -a
[ ! -d "feeds/luci" ] && ./scripts/feeds install -p luci -f
[ ! -d "feeds/packages" ] && ./scripts/feeds install -p packages -f

# --- 4. 注册 Makefile 与驱动 (延续 eMMC 修复) ---
K_MAKEFILE="$K_DIR/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$K_MAKEFILE" ]; then
    grep -q "mt7981b-sl3000-emmc.dtb" "$K_MAKEFILE" || \
    sed -i '/dtb-$(CONFIG_ARCH_MEDIATEK)/a dtb-$(CONFIG_ARCH_MEDIATEK) += mt7981b-sl3000-emmc.dtb' "$K_MAKEFILE"
fi
if [ -f "$MK_SRC" ]; then
    sed -i '/DEVICE_PACKAGES/ s/$/ kmod-mmc kmod-sdhci-mtk kmod-fs-f2fs f2fs-tools/' "$MK_SRC"
    cp -f "$MK_SRC" "target/linux/mediatek/image/filogic.mk"
fi

# --- 5. 配置合并与静默加固 (【新增修复】解决 Error opening terminal) ---
echo ">>> [修复3] 强制执行静默配置生成..."
[ -f "$CONF_SRC" ] && cat "$CONF_SRC" > .config
{
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024"
} >> .config

# 关键：彻底解决 PHP 依赖报错
[ -d "feeds/packages/admin/zabbix" ] && find feeds/packages/admin/zabbix -name Makefile -exec sed -i 's/select PACKAGE_php8/depends on PACKAGE_php8/g' {} +

# 绝杀：强制锁死静默配置，不给 menuconfig 弹窗机会
make defconfig

echo "✅ [任务完成] V16.5 所有错误项已延续修复并锁定！"
