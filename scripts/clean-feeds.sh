#!/bin/bash
set -e

echo ">>> [SL3000 V16.6] 正在执行最终物理修复逻辑..."

# --- 1. 定位源文件 ---
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(cd ..; pwd)
SRC_DIR="${GITHUB_WORKSPACE}/custom-config"
DTS_SRC=$(find "$SRC_DIR" -type f -name "*mt7981b-sl3000-emmc.dts" | head -n 1)
MK_SRC=$(find "$SRC_DIR" -type f -name "filogic.mk" | head -n 1)

# --- 2. DTS 物理合并修复 (彻底解决 40 行语法错误) ---
K_DIR=$(ls -d target/linux/mediatek/files-* 2>/dev/null | sort -V | tail -n 1)
[ -z "$K_DIR" ] && K_DIR="target/linux/mediatek/files-6.6"
DTS_DEST="$K_DIR/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
INC_DIR="$K_DIR/arch/arm64/boot/dts/mediatek"

mkdir -p "$(dirname "$DTS_DEST")"
# 强制生成标准头部
echo '/dts-v1/;' > "$DTS_DEST"
echo '#include <dt-bindings/gpio/gpio.h>' >> "$DTS_DEST"
echo '#include <dt-bindings/input/input.h>' >> "$DTS_DEST"
echo '#include <dt-bindings/leds/common.h>' >> "$DTS_DEST"

# 注入依赖 (使用 sed 严格剔除所有内部头部，防止重复)
[ -f "$INC_DIR/mt7981.dtsi" ] && sed -E '/\/dts-v1\/;|#include/d' "$INC_DIR/mt7981.dtsi" >> "$DTS_DEST"
[ -f "$INC_DIR/mt7981b.dtsi" ] && sed -E '/\/dts-v1\/;|#include/d' "$INC_DIR/mt7981b.dtsi" >> "$DTS_DEST"

# 注入用户 DTS 内容 (剔除 include 行，并确保与前文隔离)
echo -e "\n\n" >> "$DTS_DEST"
tr -d '\r' < "$DTS_SRC" | sed -E '/\/dts-v1\/;|#include|mt7981.dtsi|mt7981b.dtsi/d' >> "$DTS_DEST"

# --- 3. Feeds 更新 ---
git config --global url."https://github.com/".insteadOf "git://github.com/" || true
./scripts/feeds update -a && ./scripts/feeds install -a

# --- 4. 配置注入与 MK 修复 (合入 1024M 扩容三件套) ---
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
CONFIG_PACKAGE_luci-theme-bootstrap=y
EOT

# 物理劫持镜像生成逻辑 (filogic.mk)
[ -f "$MK_SRC" ] && cp -fv "$MK_SRC" "target/linux/mediatek/image/filogic.mk"
make defconfig

echo "✅ [脚本执行完毕] 物理劫持成功！"
