#!/bin/bash
set -e

echo ">>> [SL3000 SLAM-FIX] 正在执行暴力缝合与路径映射..."

ROOT_DIR=$(pwd)
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(cd ..; pwd)
SRC_DIR=$(find "$GITHUB_WORKSPACE" -maxdepth 2 -type d -name "*sl3000*" | head -n 1)

DTS_SRC=$(find "$SRC_DIR" -type f -name "*mt7981b-sl3000-emmc.dts" | head -n 1)
MK_SRC=$(find "$SRC_DIR" -type f -name "filogic.mk" | head -n 1)

# --- 1. 宿主机工具伪装 (解决编译早期报错) ---
mkdir -p staging_dir/host/bin
for t in m4 flex bison; do ln -sf /usr/bin/$t staging_dir/host/bin/$t; done
ln -sf /usr/bin/flex staging_dir/host/bin/lex
touch staging_dir/host/.tools_install_y staging_dir/host/stamp/.tools_compile_y

# --- 2. DTS 物理缝合 ---
BASE_DTSI=$(find "$ROOT_DIR/target/linux/mediatek" -name "mt7981.dtsi" | head -n 1)
INC_DIR=$(dirname "$BASE_DTSI")
DTS_DEST="$INC_DIR/mt7981b-sl3000-emmc.dts"

echo "🔨 正在将依赖物理注入 DTS..."
{
    echo '/dts-v1/;'
    grep "#include" "$BASE_DTSI" | head -n 20
    echo '#include <dt-bindings/leds/common.h>'
    echo '#include <dt-bindings/input/input.h>'
    sed -E '/\/dts-v1\/;|#include/d' "$BASE_DTSI"
    echo -e "\n/* --- SL3000 CUSTOM --- */\n"
    tr -d '\r' < "$DTS_SRC" | sed -E '/\/dts-v1\/;|#include|mt7981.dtsi/d'
} > "$DTS_DEST"

# 关键修复：同步到 target 覆盖层，这是镜像构建的第一参考源
FILES_DIR="$ROOT_DIR/target/linux/mediatek/files/arch/arm64/boot/dts/mediatek"
mkdir -p "$FILES_DIR"
cp -fv "$DTS_DEST" "$FILES_DIR/"

# --- 3. 配置锁定 ---
./scripts/feeds update -a && ./scripts/feeds install -a
[ -f "$MK_SRC" ] && cp -fv "$MK_SRC" "target/linux/mediatek/image/filogic.mk"

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
CONFIG_TARGET_ROOTFS_INITRAMFS=n
EOT

make defconfig
echo "✅ [脚本] 缝合与配置已锁定。"
