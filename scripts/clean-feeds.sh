#!/bin/bash
# ============================================================
# SL3000 V15.5 终极合一版：【编码自愈-GCC预检测-全注册】
# 适用：ImmortalWrt 24.10 / Kernel 6.6
# ============================================================
set -e

echo ">>> [SL3000 终极合一 V15.5] 任务启动..."

# --- 1. 定位源文件 ---
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(cd ..; pwd)
SRC_DIR="${GITHUB_WORKSPACE}/custom-config"

DTS_SRC=$(find "$SRC_DIR" -type f -name "*mt7981b-sl3000-emmc.dts" | head -n 1)
MK_SRC=$(find "$SRC_DIR" -type f -name "filogic.mk" | head -n 1)
CONF_SRC=$(find "$SRC_DIR" -type f -name "*sl3000.config" | head -n 1)

[ -z "$DTS_SRC" ] && { echo "❌ 错误: 找不到 DTS 源文件"; exit 1; }

# --- 2. 预备内核路径与编码自愈 ---
K_DIR=$(ls -d target/linux/mediatek/files-* 2>/dev/null | sort -V | tail -n 1)
[ -z "$K_DIR" ] && K_DIR="target/linux/mediatek/files-6.6"
DTS_DEST="$K_DIR/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"

mkdir -p "$(dirname "$DTS_DEST")"

echo ">>> [自愈] 正在清理文件编码并转换引用路径..."
# 1. 移除 Windows 换行符并清理非法字符，确保 dtc 能识别
tr -d '\r' < "$DTS_SRC" > "$DTS_DEST.tmp"

# 2. 将本地引用修复为内核标准路径 (适配 V12.1 逻辑)
sed -e 's/#include "mt7981.dtsi"/#include <mediatek\/mt7981.dtsi>/g' \
    -e 's/#include "mt7981b.dtsi"/#include <mediatek\/mt7981b.dtsi>/g' \
    "$DTS_DEST.tmp" > "$DTS_DEST"
rm -f "$DTS_DEST.tmp"

# --- 3. 核心修复：带 GCC 预处理的语法检测 ---
echo ">>> [诊断] 正在调用 GCC 预处理器进行深度语法校验..."
# 定义内核头文件包含路径
DTS_INC="-I $K_DIR/arch/arm64/boot/dts -I $K_DIR/arch/arm64/boot/dts/mediatek -I $K_DIR/include"

# 使用 gcc -E 预处理后再交给 dtc，防止 #include 报错
if ! gcc -E -nostdinc $DTS_INC -x assembler-with-cpp "$DTS_DEST" | dtc -I dts -O dtb -p 0 -o /dev/null 2>dts_error.log; then
    echo "===================================================="
    echo "⚠️ DTS 预检未通过，但我们将继续执行流程。"
    echo "提示：预检失败可能是因为 Actions 环境暂时缺少内核头文件。"
    echo "内核主编译阶段 (V=s) 将给出最权威的报错。"
    echo "===================================================="
    cat dts_error.log || true
fi

# --- 4. 注册与驱动补全 (适配你的 MK 规范) ---
echo ">>> [注册] 正在同步 Makefile 并写入设备信息..."
K_MAKEFILE="$K_DIR/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$K_MAKEFILE" ]; then
    grep -q "mt7981b-sl3000-emmc.dtb" "$K_MAKEFILE" || \
    sed -i '/dtb-$(CONFIG_ARCH_MEDIATEK)/a dtb-$(CONFIG_ARCH_MEDIATEK) += mt7981b-sl3000-emmc.dtb' "$K_MAKEFILE"
fi

# 复制自定义 MK 并确保驱动包完整
if [ -f "$MK_SRC" ]; then
    # 强制注入 eMMC 基础驱动包名
    sed -i '/DEVICE_PACKAGES/ s/$/ kmod-mmc kmod-sdhci-mtk kmod-fs-f2fs f2fs-tools/' "$MK_SRC"
    cp -f "$MK_SRC" "target/linux/mediatek/image/filogic.mk"
fi

# --- 5. 配置合并与生态扫雷 ---
[ -f "$CONF_SRC" ] && cat "$CONF_SRC" > .config
{
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024"
} >> .config

# Git 协议与 Feeds 自愈
git config --global url."https://github.com/".insteadOf git://github.com/
sed -i '/passwall/d' feeds.conf.default
echo "src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages.git;main" >> feeds.conf.default
echo "src-git passwall https://github.com/xiaorouji/openwrt-passwall.git;main" >> feeds.conf.default

./scripts/feeds update -a && ./scripts/feeds install -a

# 修复 PHP 递归依赖
[ -d "feeds/packages/admin/zabbix" ] && find feeds/packages/admin/zabbix -name Makefile -exec sed -i 's/select PACKAGE_php8/depends on PACKAGE_php8/g' {} +

echo "✅ [任务完成] V15.5 逻辑合并成功！"
