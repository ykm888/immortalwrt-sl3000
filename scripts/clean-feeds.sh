#!/bin/bash
set -e

echo ">>> [SL3000 Final-Fixed] 正在同步 1GB 扩容配置与环境补丁..."

ROOT_DIR=$(pwd)
# 1. 路径精准定位
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(cd ..; pwd)
SRC_DIR=$(find "$GITHUB_WORKSPACE" -maxdepth 2 -type d -name "*sl3000*" | head -n 1)

if [ -z "$SRC_DIR" ]; then
    echo "❌ 错误: 找不到配置仓库目录"
    exit 1
fi

DTS_SRC=$(find "$SRC_DIR" -type f -name "*mt7981b-sl3000-emmc.dts" | head -n 1)
MK_SRC=$(find "$SRC_DIR" -type f -name "filogic.mk" | head -n 1)

# --- 1. 依赖欺骗与环境占位 ---
echo "🔗 正在执行工具链预劫持..."
mkdir -p staging_dir/host/bin
for tool in m4 flex bison; do
    ln -sf /usr/bin/$tool staging_dir/host/bin/$tool
done
ln -sf /usr/bin/flex staging_dir/host/bin/lex
touch staging_dir/host/.tools_install_y
mkdir -p staging_dir/host/stamp
touch staging_dir/host/stamp/.tools_compile_y
touch staging_dir/host/stamp/.m4_installed

# --- 2. DTS 物理缝合 (延续原有逻辑并增强) ---
BASE_DTSI=$(find "$ROOT_DIR/target/linux/mediatek" -name "mt7981.dtsi" | head -n 1)
INC_DIR=$(dirname "$BASE_DTSI")
DTS_DEST="$INC_DIR/mt7981b-sl3000-emmc.dts"

echo "🧪 正在缝合 DTS 到: $DTS_DEST"
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

# 【关键修复】同步到 files 目录，强制覆盖任何中途生成的内核源码
FILES_DTS_DIR="$ROOT_DIR/target/linux/mediatek/files/arch/arm64/boot/dts/mediatek"
mkdir -p "$FILES_DTS_DIR"
cp -fv "$DTS_DEST" "$FILES_DTS_DIR/"

# --- 3. 注入配置 ---
./scripts/feeds update -a && ./scripts/feeds install -a

# 物理同步镜像规则
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
echo "✅ [脚本完成] 劫持与 1GB 配置已就绪。"
