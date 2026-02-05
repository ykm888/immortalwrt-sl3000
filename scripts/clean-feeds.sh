#!/bin/bash
set -e

echo ">>> [SL3000 ULTRA-FIX] 开启全链路修复与磁盘优化..."

ROOT_DIR=$(pwd)
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(cd ..; pwd)
SRC_DIR=$(find "$GITHUB_WORKSPACE" -maxdepth 2 -type d -name "*sl3000*" | head -n 1)

# --- 1. 宿主机环境暴力补全 ---
# 修复之前的目录不存在报错
mkdir -p staging_dir/host/bin staging_dir/host/stamp
for t in m4 flex bison; do 
    ln -sf /usr/bin/$t staging_dir/host/bin/$t
done
ln -sf /usr/bin/flex staging_dir/host/bin/lex

# 注入自愈标记
touch staging_dir/host/.tools_install_y
touch staging_dir/host/stamp/.tools_compile_y
touch staging_dir/host/stamp/.m4_installed
touch staging_dir/host/stamp/.flex_installed

# --- 2. DTS 物理缝合 (解决 cc1 找不到依赖的关键) ---
BASE_DTSI=$(find "$ROOT_DIR/target/linux/mediatek" -name "mt7981.dtsi" | head -n 1)
INC_DIR=$(dirname "$BASE_DTSI")
DTS_DEST="$INC_DIR/mt7981b-sl3000-emmc.dts"

echo "🔨 正在执行物理缝合，合并所有 dtsi 依赖到单一文件..."
{
    echo '/dts-v1/;'
    grep "#include" "$BASE_DTSI" | head -n 20
    echo '#include <dt-bindings/leds/common.h>'
    echo '#include <dt-bindings/input/input.h>'
    sed -E '/\/dts-v1\/;|#include/d' "$BASE_DTSI"
    [ -f "$INC_DIR/mt7981b.dtsi" ] && sed -E '/\/dts-v1\/;|#include/d' "$INC_DIR/mt7981b.dtsi"
    echo -e "\n/* --- SL3000 CUSTOM SECTION --- */\n"
    tr -d '\r' < $(find "$SRC_DIR" -type f -name "*mt7981b-sl3000-emmc.dts" | head -n 1) | sed -E '/\/dts-v1\/;|#include|mt7981.dtsi/d'
} > "$DTS_DEST"

# 建立 Files 覆盖层（最高优先级自愈路径）
mkdir -p "$ROOT_DIR/target/linux/mediatek/files/arch/arm64/boot/dts/mediatek"
cp -fv "$DTS_DEST" "$ROOT_DIR/target/linux/mediatek/files/arch/arm64/boot/dts/mediatek/"

# --- 3. 配置与镜像规则注入 ---
./scripts/feeds update -a && ./scripts/feeds install -a
MK_SRC=$(find "$SRC_DIR" -type f -name "filogic.mk" | head -n 1)
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
echo "✅ [脚本] 自愈环境就绪。"
