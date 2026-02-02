#!/bin/bash
# ============================================================
# SL3000 V15.0 终极旗舰版：【检测-修复-注册-合并】合一脚本
# 适用：ImmortalWrt 24.10 / Kernel 6.6
# ============================================================
set -e

echo ">>> [SL3000 自动化合一 V15.0] 启动全链路任务..."

# --- 1. 定位源文件 ---
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(cd ..; pwd)
SRC_DIR="${GITHUB_WORKSPACE}/custom-config"

DTS_SRC=$(find "$SRC_DIR" -type f -name "*mt7981b-sl3000-emmc.dts" | head -n 1)
MK_SRC=$(find "$SRC_DIR" -type f -name "filogic.mk" | head -n 1)
CONF_SRC=$(find "$SRC_DIR" -type f -name "*sl3000.config" | head -n 1)

[ -z "$DTS_SRC" ] && { echo "❌ 错误: 找不到 DTS 源文件"; exit 1; }

# --- 2. 预备内核路径与 DTS 自愈 ---
K_DIR=$(ls -d target/linux/mediatek/files-* 2>/dev/null | sort -V | tail -n 1)
[ -z "$K_DIR" ] && K_DIR="target/linux/mediatek/files-6.6"
DTS_DEST="$K_DIR/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"

mkdir -p "$(dirname "$DTS_DEST")"
echo ">>> [自愈] 修复 DTS 引用并进行预校验..."
# 修复引用路径以适配内核 6.6 规范
sed -e 's/#include "mt7981.dtsi"/#include <mediatek\/mt7981.dtsi>/g' \
    -e 's/#include "mt7981b.dtsi"/#include <mediatek\/mt7981b.dtsi>/g' \
    "$DTS_SRC" > "$DTS_DEST"

# --- 3. 深度诊断：DTC 语法静态扫描 ---
DTS_INC_PATH="$K_DIR/arch/arm64/boot/dts"
if ! dtc -I dts -O dtb -p 0 -i "$DTS_INC_PATH" -i "$DTS_INC_PATH/mediatek" -o /dev/null "$DTS_DEST" 2>dts_syntax_error.log; then
    echo "===================================================="
    echo "❌ DTS 语法校验失败！请检查以下日志："
    cat dts_syntax_error.log
    echo "===================================================="
    exit 1
fi
echo "✅ DTS 预检通过"

# --- 4. 驱动与 Makefile 注册 ---
echo ">>> [注册] 同步 Makefile 并补全 eMMC 驱动..."
# 注入 eMMC 必需驱动包
if [ -f "$MK_SRC" ]; then
    sed -i '/DEVICE_PACKAGES/ s/$/ kmod-mmc kmod-mtk-sd kmod-fs-f2fs f2fs-tools/' "$MK_SRC"
    cp -f "$MK_SRC" "target/linux/mediatek/image/filogic.mk"
fi

# 核心注册：确保 cc1 触发编译
K_MAKEFILE="$K_DIR/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$K_MAKEFILE" ]; then
    grep -q "mt7981b-sl3000-emmc.dtb" "$K_MAKEFILE" || \
    sed -i '/dtb-$(CONFIG_ARCH_MEDIATEK)/a dtb-$(CONFIG_ARCH_MEDIATEK) += mt7981b-sl3000-emmc.dtb' "$K_MAKEFILE"
fi

# --- 5. 配置合并与生态扫雷 ---
echo ">>> [合并] 注入 1GB RAM 参数与 Feeds 优化..."
[ -f "$CONF_SRC" ] && cat "$CONF_SRC" > .config
{
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024"
    echo "CONFIG_EFI_PARTITION=y"
} >> .config

# Git 协议自愈
git config --global url."https://github.com/".insteadOf git://github.com/

# Feeds 优化
sed -i '/passwall/d' feeds.conf.default
echo "src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages.git;main" >> feeds.conf.default
echo "src-git passwall https://github.com/xiaorouji/openwrt-passwall.git;main" >> feeds.conf.default

./scripts/feeds update -a && ./scripts/feeds install -a

# 修复 PHP 递归依赖
[ -d "feeds/packages/admin/zabbix" ] && find feeds/packages/admin/zabbix -name Makefile -exec sed -i 's/select PACKAGE_php8/depends on PACKAGE_php8/g' {} +

echo "✅ [任务完成] 三件套已完美合并！"
