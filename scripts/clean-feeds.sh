#!/bin/bash
set -e

echo ">>> [SL3000 Final-Fixed] 正在同步 1GB 扩容配置与环境补丁..."

ROOT_DIR=$(pwd)
# 修复点：确保 SRC_DIR 能准确定位到克隆下来的仓库根目录
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(cd ..; pwd)
# 这里的 custom-config 指的是你克隆下来的仓库文件夹
SRC_DIR=$(find "$GITHUB_WORKSPACE" -maxdepth 1 -type d -name "*sl3000*" | head -n 1)

DTS_SRC=$(find "$SRC_DIR" -type f -name "*mt7981b-sl3000-emmc.dts" | head -n 1)
MK_SRC=$(find "$SRC_DIR" -type f -name "filogic.mk" | head -n 1)

# --- 1. 依赖欺骗与环境占位 (解决 m4/flex 报错) ---
echo "🔗 正在执行宿主机工具链预劫持..."
mkdir -p staging_dir/host/bin
ln -sf /usr/bin/m4 staging_dir/host/bin/m4
ln -sf /usr/bin/flex staging_dir/host/bin/flex
ln -sf /usr/bin/bison staging_dir/host/bin/bison
ln -sf /usr/bin/flex staging_dir/host/bin/lex
touch staging_dir/host/.tools_install_y
mkdir -p staging_dir/host/stamp
touch staging_dir/host/stamp/.tools_compile_y
touch staging_dir/host/stamp/.m4_installed

# --- 2. DTS 物理缝合 ---
BASE_DTSI=$(find "$ROOT_DIR/target/linux/mediatek" -name "mt7981.dtsi" | head -n 1)
INC_DIR=$(dirname "$BASE_DTSI")
# 修复点：在写入前确保目录存在
mkdir -p "$INC_DIR"
DTS_DEST="$INC_DIR/mt7981b-sl3000-emmc.dts"

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

# --- 3. 注入 1GB 扩容与 eMMC 核心配置 ---
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
EOT

# 物理同步镜像规则
[ -f "$MK_SRC" ] && cp -fv "$MK_SRC" "target/linux/mediatek/image/filogic.mk"

# 强制执行 defconfig 锁定配置，防止弹出 menuconfig
make defconfig

echo "✅ [脚本完成] 劫持与 1GB 配置已就绪。"
