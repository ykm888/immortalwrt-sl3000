#!/bin/bash
set -e

echo ">>> [SL3000 SLAM-FIX] 正在执行全链路自愈初始化..."

ROOT_DIR=$(pwd)
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(cd ..; pwd)
SRC_DIR=$(find "$GITHUB_WORKSPACE" -maxdepth 2 -type d -name "*sl3000*" | head -n 1)

# --- 1. 优化磁盘空间 (全链路自愈第一步：清理环境) ---
echo "清理冗余文件以释放空间..."
sudo rm -rf /usr/share/dotnet /usr/local/lib/android /opt/ghc /usr/local/share/powershell /usr/share/swift
# 清理本地不必要的镜像
docker image prune -a -f || true

# --- 2. 宿主机工具强制伪装 ---
mkdir -p staging_dir/host/bin staging_dir/host/stamp
for t in m4 flex bison; do 
    ln -sf /usr/bin/$t staging_dir/host/bin/$t
done
ln -sf /usr/bin/flex staging_dir/host/bin/lex

touch staging_dir/host/.tools_install_y
touch staging_dir/host/stamp/.tools_compile_y
touch staging_dir/host/stamp/.m4_installed

# --- 3. DTS 暴力缝合与物理自愈覆盖 ---
BASE_DTSI=$(find "$ROOT_DIR/target/linux/mediatek" -name "mt7981.dtsi" | head -n 1)
INC_DIR=$(dirname "$BASE_DTSI")
DTS_DEST="$INC_DIR/mt7981b-sl3000-emmc.dts"

echo "🔨 物理缝合依赖到 DTS..."
{
    echo '/dts-v1/;'
    grep "#include" "$BASE_DTSI" | head -n 20
    echo '#include <dt-bindings/leds/common.h>'
    echo '#include <dt-bindings/input/input.h>'
    sed -E '/\/dts-v1\/;|#include/d' "$BASE_DTSI"
    echo -e "\n/* --- SL3000 CUSTOM --- */\n"
    tr -d '\r' < $(find "$SRC_DIR" -type f -name "*mt7981b-sl3000-emmc.dts" | head -n 1) | sed -E '/\/dts-v1\/;|#include|mt7981.dtsi/d'
} > "$DTS_DEST"

# 【全链路自愈关键】
# 将 DTS 放入 files 目录，OpenWrt 每次 prepare 内核时都会强制覆盖回来
FILES_DIR="$ROOT_DIR/target/linux/mediatek/files/arch/arm64/boot/dts/mediatek"
mkdir -p "$FILES_DIR"
cp -fv "$DTS_DEST" "$FILES_DIR/"

# --- 4. 配置锁定 ---
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
echo "✅ [自愈脚本] 环境与配置已加固。"
