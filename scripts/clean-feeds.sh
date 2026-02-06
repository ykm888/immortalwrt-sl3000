#!/bin/bash
set -e

echo ">>> [SL3000 SLAM-FIX] 启动全链路自愈与路径冲突修复..."

ROOT_DIR=$(pwd)
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(cd ..; pwd)
# 定位自定义仓库目录
SRC_DIR=$(find "$GITHUB_WORKSPACE" -maxdepth 2 -type d -name "*sl3000*" | head -n 1)

# --- 1. 磁盘空间暴力优化 (全链路自愈基础) ---
echo "清理冗余空间..."
sudo rm -rf /usr/share/dotnet /usr/local/lib/android /opt/ghc /var/lib/docker
docker image prune -a -f || true

# --- 2. 宿主机工具伪装与目录修复 ---
# 解决之前遇到的目录不存在报错
mkdir -p staging_dir/host/bin staging_dir/host/stamp
for t in m4 flex bison; do 
    ln -sf /usr/bin/$t staging_dir/host/bin/$t
done
ln -sf /usr/bin/flex staging_dir/host/bin/lex

# 注入已安装标记，跳过耗时的工具编译
touch staging_dir/host/.tools_install_y
touch staging_dir/host/stamp/.tools_compile_y
touch staging_dir/host/stamp/.m4_installed

# --- 3. DTS 物理缝合 (延续 1GB/eMMC 修复) ---
BASE_DTSI=$(find "$ROOT_DIR/target/linux/mediatek" -name "mt7981.dtsi" | head -n 1)
INC_DIR=$(dirname "$BASE_DTSI")
DTS_DEST="$INC_DIR/mt7981b-sl3000-emmc.dts"

echo "🔨 执行物理缝合: $DTS_DEST"
{
    echo '/dts-v1/;'
    grep "#include" "$BASE_DTSI" | head -n 20
    echo '#include <dt-bindings/leds/common.h>'
    echo '#include <dt-bindings/input/input.h>'
    sed -E '/\/dts-v1\/;|#include/d' "$BASE_DTSI"
    # 注入用户自定义的 DTS 逻辑
    DTS_SRC_FILE=$(find "$SRC_DIR" -type f -name "*mt7981b-sl3000-emmc.dts" | head -n 1)
    tr -d '\r' < "$DTS_SRC_FILE" | sed -E '/\/dts-v1\/;|#include|mt7981.dtsi/d'
} > "$DTS_DEST"

# 【自愈关键】建立镜像构建 files 覆盖层，解决 cc1 找不到文件
mkdir -p "$ROOT_DIR/target/linux/mediatek/files/arch/arm64/boot/dts/mediatek"
cp -fv "$DTS_DEST" "$ROOT_DIR/target/linux/mediatek/files/arch/arm64/boot/dts/mediatek/"

# --- 4. 配置自愈与 Feeds 处理 ---
./scripts/feeds update -a && ./scripts/feeds install -a

# 【修复 cp: same file 报错】检查物理路径是否一致
MK_SRC=$(find "$SRC_DIR" -type f -name "filogic.mk" | head -n 1)
MK_DEST="$ROOT_DIR/target/linux/mediatek/image/filogic.mk"
if [ -f "$MK_SRC" ]; then
    REAL_SRC=$(readlink -f "$MK_SRC")
    REAL_DEST=$(readlink -f "$MK_DEST")
    if [ "$REAL_SRC" != "$REAL_DEST" ]; then
        cp -fv "$MK_SRC" "$MK_DEST"
    else
        echo "⚠️ 跳过 filogic.mk 拷贝：源文件与目标路径相同"
    fi
fi

# --- 5. 写入锁定配置 ---
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
echo "✅ [自愈脚本] 环境锁定完成。"
