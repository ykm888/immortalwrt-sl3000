#!/bin/bash
set -e

echo ">>> [SL3000 V16.6-Final] 启动物理注入与环境强固逻辑..."

# --- 1. 定位环境 ---
ROOT_DIR=$(pwd)
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(cd ..; pwd)
SRC_DIR="${GITHUB_WORKSPACE}/custom-config"
DTS_SRC=$(find "$SRC_DIR" -type f -name "*mt7981b-sl3000-emmc.dts" | head -n 1)
MK_SRC=$(find "$SRC_DIR" -type f -name "filogic.mk" | head -n 1)

# --- 2. 动态路径探测 ---
BASE_DTSI=$(find "$ROOT_DIR/target/linux/mediatek" -name "mt7981.dtsi" | head -n 1)
if [ -z "$BASE_DTSI" ]; then
    echo "❌ 找不到基础 dtsi，尝试深度搜索..."
    BASE_DTSI=$(find . -name "mt7981.dtsi" | head -n 1)
fi
[ -z "$BASE_DTSI" ] && { echo "❌ 严重错误: 找不到核心 DTS 文件"; exit 1; }

INC_DIR=$(dirname "$BASE_DTSI")
DTS_DEST="$INC_DIR/mt7981b-sl3000-emmc.dts"

# --- 3. DTS 物理合并 (彻底消灭语法冲突) ---
{
    echo '/dts-v1/;'
    grep "#include" "$BASE_DTSI" | head -n 20
    echo '#include <dt-bindings/leds/common.h>'
    echo '#include <dt-bindings/input/input.h>'
    sed -E '/\/dts-v1\/;|#include/d' "$BASE_DTSI"
    [ -f "$INC_DIR/mt7981b.dtsi" ] && sed -E '/\/dts-v1\/;|#include/d' "$INC_DIR/mt7981b.dtsi"
    echo -e "\n/* --- SL3000 CUSTOM --- */\n"
    tr -d '\r' < "$DTS_SRC" | sed -E '/\/dts-v1\/;|#include|mt7981.dtsi/d'
} > "$DTS_DEST"

# --- 4. 配置与镜像规则注入 ---
./scripts/feeds update -a && ./scripts/feeds install -a

cat <<EOT > .config
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y
CONFIG_TARGET_KERNEL_PARTSIZE=128
CONFIG_TARGET_ROOTFS_PARTSIZE=1024
CONFIG_PACKAGE_kmod-mmc=y
CONFIG_PACKAGE_kmod-sdhci-mtk=y
CONFIG_PACKAGE_f2fs-tools=y
CONFIG_PACKAGE_kmod-fs-f2fs=y
CONFIG_PACKAGE_kmod-mt7981-firmware=y
CONFIG_PACKAGE_luci=y
EOT

[ -f "$MK_SRC" ] && cp -fv "$MK_SRC" "target/linux/mediatek/image/filogic.mk"
make defconfig

echo "✅ [完成] 环境与 DTS 修复就绪！"
