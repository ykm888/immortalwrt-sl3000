#!/bin/bash
# ============================================================
# SL3000 V16.5 旗舰版：【Feeds 强力重连-依赖补全-诊断合一】
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

# --- 2. 核心补丁：DTS 自愈与 GCC 预处理兼容 ---
K_DIR=$(ls -d target/linux/mediatek/files-* 2>/dev/null | sort -V | tail -n 1)
[ -z "$K_DIR" ] && K_DIR="target/linux/mediatek/files-6.6"
DTS_DEST="$K_DIR/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"

mkdir -p "$(dirname "$DTS_DEST")"
# 清理 Windows 编码并修复引用
tr -d '\r' < "$DTS_SRC" > "$DTS_DEST.tmp"
sed -e 's/#include "mt7981.dtsi"/#include <mediatek\/mt7981.dtsi>/g' \
    -e 's/#include "mt7981b.dtsi"/#include <mediatek\/mt7981b.dtsi>/g' \
    "$DTS_DEST.tmp" > "$DTS_DEST"
rm -f "$DTS_DEST.tmp"

# --- 3. Feeds 强制自愈逻辑 (解决 No such file 报错) ---
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

# --- 4. 注册 Makefile 与 MK 补丁 ---
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

# --- 5. 配置合并与依赖扫雷 ---
[ -f "$CONF_SRC" ] && cat "$CONF_SRC" > .config
{
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024"
} >> .config

# 解决 PHP 递归依赖（解决 lm-sensors 等缺失问题）
[ -d "feeds/packages/admin/zabbix" ] && find feeds/packages/admin/zabbix -name Makefile -exec sed -i 's/select PACKAGE_php8/depends on PACKAGE_php8/g' {} +

echo "✅ [任务完成] V16.5 深度合并成功！"
