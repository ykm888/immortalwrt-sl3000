#!/bin/bash
set -e

echo ">>> [SL3000 SLAM-FIX] 开始执行暴力补丁..."

ROOT_DIR=$(pwd)
# 自动定位配置仓库
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(cd ..; pwd)
SRC_DIR=$(find "$GITHUB_WORKSPACE" -maxdepth 2 -type d -name "*sl3000*" | head -n 1)

DTS_SRC=$(find "$SRC_DIR" -type f -name "*mt7981b-sl3000-emmc.dts" | head -n 1)
MK_SRC=$(find "$SRC_DIR" -type f -name "filogic.mk" | head -n 1)

# --- 1. 宿主机工具伪装 (修复：必须先创建目录) ---
echo "🔗 正在预建工具链标记目录..."
mkdir -p staging_dir/host/bin
mkdir -p staging_dir/host/stamp

# 劫持系统工具以加快构建并绕过 m4/flex 报错
for t in m4 flex bison; do 
    ln -sf /usr/bin/$t staging_dir/host/bin/$t
done
ln -sf /usr/bin/flex staging_dir/host/bin/lex

# 暴力标记工具已“安装”
touch staging_dir/host/.tools_install_y
touch staging_dir/host/stamp/.tools_compile_y
touch staging_dir/host/stamp/.m4_installed
touch staging_dir/host/stamp/.flex_installed

# --- 2. DTS 物理缝合 (延续原有逻辑) ---
BASE_DTSI=$(find "$ROOT_DIR/target/linux/mediatek" -name "mt7981.dtsi" | head -n 1)
INC_DIR=$(dirname "$BASE_DTSI")
DTS_DEST="$INC_DIR/mt7981b-sl3000-emmc.dts"

echo "🔨 物理缝合依赖到 DTS: $DTS_DEST"
{
    echo '/dts-v1/;'
    grep "#include" "$BASE_DTSI" | head -n 20
    echo '#include <dt-bindings/leds/common.h>'
    echo '#include <dt-bindings/input/input.h>'
    sed -E '/\/dts-v1\/;|#include/d' "$BASE_DTSI"
    [ -f "$INC_DIR/mt7981b.dtsi" ] && sed -E '/\/dts-v1\/;|#include/d' "$INC_DIR/mt7981b.dtsi"
    echo -e "\n/* --- SL3000 CUSTOM SECTION --- */\n"
    tr -d '\r' < "$DTS_SRC" | sed -E '/\/dts-v1\/;|#include|mt7981.dtsi/d'
} > "$DTS_DEST"

# 镜像构建优先级修复：将 DTS 放入 files 目录，这是 OpenWrt 覆盖机制的最高优先级
FILES_DIR="$ROOT_DIR/target/linux/mediatek/files/arch/arm64/boot/dts/mediatek"
mkdir -p "$FILES_DIR"
cp -fv "$DTS_DEST" "$FILES_DIR/"

# --- 3. 配置与 Feeds ---
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
echo "✅ [脚本完成] 环境伪装与 DTS 缝合就绪。"
