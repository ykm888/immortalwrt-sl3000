#!/bin/bash
set -e

echo ">>> [SL3000 ULTRA-SELFHEAL] 执行全链路修复..."

ROOT_DIR=$(pwd)
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(cd ..; pwd)
SRC_DIR=$(find "$GITHUB_WORKSPACE" -maxdepth 2 -type d -name "*sl3000*" | head -n 1)

# --- 1. 磁盘空间极度优化 ---
sudo rm -rf /usr/share/dotnet /usr/local/lib/android /opt/ghc /var/lib/docker
docker image prune -a -f || true

# --- 2. 补全工具链标记 ---
mkdir -p staging_dir/host/bin staging_dir/host/stamp
for t in m4 flex bison; do ln -sf /usr/bin/$t staging_dir/host/bin/$t; done
ln -sf /usr/bin/flex staging_dir/host/bin/lex
touch staging_dir/host/.tools_install_y staging_dir/host/stamp/.tools_compile_y

# --- 3. DTS 暴力缝合 (延续之前所有修复) ---
BASE_DTSI=$(find "$ROOT_DIR/target/linux/mediatek" -name "mt7981.dtsi" | head -n 1)
INC_DIR=$(dirname "$BASE_DTSI")
DTS_DEST="$INC_DIR/mt7981b-sl3000-emmc.dts"

echo "🔨 正在物理缝合依赖到 DTS: $DTS_DEST"
{
    echo '/dts-v1/;'
    grep "#include" "$BASE_DTSI" | head -n 20
    echo '#include <dt-bindings/leds/common.h>'
    echo '#include <dt-bindings/input/input.h>'
    sed -E '/\/dts-v1\/;|#include/d' "$BASE_DTSI"
    # 延续 1GB 内存与 eMMC 修复逻辑
    tr -d '\r' < $(find "$SRC_DIR" -type f -name "*mt7981b-sl3000-emmc.dts" | head -n 1) | sed -E '/\/dts-v1\/;|#include|mt7981.dtsi/d'
} > "$DTS_DEST"

# 【关键自愈：建立 files 覆盖层】
# 确保每次 make prepare 都会把这个文件同步到内核源码树
mkdir -p "$ROOT_DIR/target/linux/mediatek/files/arch/arm64/boot/dts/mediatek"
cp -fv "$DTS_DEST" "$ROOT_DIR/target/linux/mediatek/files/arch/arm64/boot/dts/mediatek/"

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
echo "✅ [脚本] 环境与补丁已强制同步。"
