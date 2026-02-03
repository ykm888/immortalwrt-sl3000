#!/bin/bash
# ============================================================
# SL3000 V16.5 旗舰版（修复版）：【Feeds 强力重连-依赖补全-诊断合一】
# 适用：ImmortalWrt 24.10 / Kernel 6.6
# ============================================================
set -e

echo ">>> [SL3000 V16.5] 深度初始化开始..."

# --- 1. 定位源文件 ---
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(cd ..; pwd)
SRC_DIR="${GITHUB_WORKSPACE}/custom-config"

DTS_SRC=$(find "$SRC_DIR" -type f -name "*mt7981b-sl3000-emmc.dts" | head -n 1)
MK_SRC=$(find "$SRC_DIR" -type f -name "filogic.mk" | head -n 1)
CONF_SRC=$(find "$SRC_DIR" -type f -name "*sl3000.config" | head -n 1)

# --- 2. 核心修复：DTS 物理合并 (替换原有的 sed 引用路径修改) ---
K_DIR=$(ls -d target/linux/mediatek/files-* 2>/dev/null | sort -V | tail -n 1)
[ -z "$K_DIR" ] && K_DIR="target/linux/mediatek/files-6.6"
DTS_DEST="$K_DIR/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
INC_DIR="$K_DIR/arch/arm64/boot/dts/mediatek"

mkdir -p "$(dirname "$DTS_DEST")"

echo ">>> [核心修复] 执行内容物理合并，消除 mediatek/dtsi 路径依赖..."
# 创建包含标准系统头文件的基础文件
cat <<EOT > "$DTS_DEST.tmp"
/dts-v1/;
#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/leds/common.h>
EOT

# 物理抓取并直接粘贴 mt7981.dtsi 和 mt7981b.dtsi 的文本内容
[ -f "$INC_DIR/mt7981.dtsi" ] && grep -v "/dts-v1/;" "$INC_DIR/mt7981.dtsi" | grep -v "#include" >> "$DTS_DEST.tmp"
[ -f "$INC_DIR/mt7981b.dtsi" ] && grep -v "/dts-v1/;" "$INC_DIR/mt7981b.dtsi" | grep -v "#include" >> "$DTS_DEST.tmp"

# 追加你的板级 DTS 内容，并过滤掉原本会导致失败的 include 语句
tr -d '\r' < "$DTS_SRC" | grep -v "/dts-v1/;" | grep -v "mt7981.dtsi" | grep -v "mt7981b.dtsi" >> "$DTS_DEST.tmp"

cp -f "$DTS_DEST.tmp" "$DTS_DEST"
rm -f "$DTS_DEST.tmp"

# --- 3. Feeds 强制自愈逻辑 (延续 V16.5 原文) ---
echo ">>> [Feeds] 正在重构插件源并强制同步 (带重试机制)..."
git config --global url."https://github.com/".insteadOf git://github.com/

# 强行注入 Passwall 及其依赖
sed -i '/passwall/d' feeds.conf.default
echo "src-git-full passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages.git;main" >> feeds.conf.default
echo "src-git-full passwall https://github.com/xiaorouji/openwrt-passwall.git;main" >> feeds.conf.default

# 循环尝试更新，防止网络抖动导致 feeds 目录为空
for i in {1..3}; do
    ./scripts/feeds update -a && break || sleep 5
done

# 强制建立所有包的索引和软链接
./scripts/feeds install -a

# 特别修复：针对日志中提到的缺失项建立物理链接
[ ! -d "feeds/luci" ] && ./scripts/feeds install -p luci -f
[ ! -d "feeds/packages" ] && ./scripts/feeds install -p packages -f

# --- 4. 注册 Makefile 与 MK 补丁 (延续 V16.5 原文) ---
K_MAKEFILE="$K_DIR/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$K_MAKEFILE" ]; then
    grep -q "mt7981b-sl3000-emmc.dtb" "$K_MAKEFILE" || \
    sed -i '/dtb-$(CONFIG_ARCH_MEDIATEK)/a dtb-$(CONFIG_ARCH_MEDIATEK) += mt7981b-sl3000-emmc.dtb' "$K_MAKEFILE"
fi

if [ -f "$MK_SRC" ]; then
    # 注入驱动补丁：适配你的 MK 规范
    sed -i '/DEVICE_PACKAGES/ s/$/ kmod-mmc kmod-sdhci-mtk kmod-fs-f2fs f2fs-tools/' "$MK_SRC"
    cp -f "$MK_SRC" "target/linux/mediatek/image/filogic.mk"
fi

# --- 5. 配置合并与依赖扫雷 (延续 V16.5 原文) ---
[ -f "$CONF_SRC" ] && cat "$CONF_SRC" > .config
{
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024"
} >> .config

# 解决 PHP 递归依赖（解决 lm-sensors 等缺失问题）
[ -d "feeds/packages/admin/zabbix" ] && find feeds/packages/admin/zabbix -name Makefile -exec sed -i 's/select PACKAGE_php8/depends on PACKAGE_php8/g' {} +

echo "✅ [任务完成] V16.5 深度合并成功！"
