#!/bin/bash
set -e

echo ">>> [SL3000 Final-Strike] 开始执行深度注入..."

# --- 1. 定位与环境初始化 ---
ROOT_DIR=$(pwd)
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(cd ..; pwd)
SRC_DIR="${GITHUB_WORKSPACE}/custom-config"
DTS_SRC=$(find "$SRC_DIR" -type f -name "*mt7981b-sl3000-emmc.dts" | head -n 1)
MK_SRC=$(find "$SRC_DIR" -type f -name "filogic.mk" | head -n 1)

# --- 2. 强力工具链避让 (解决 m4/flex 报错) ---
echo "🛠️ 正在优化宿主机工具链..."
# 强制让 OpenWrt 使用 Ubuntu 系统自带的 m4/flex/bison，不进行重复编译
sed -i 's/tools-y += m4/tools-y += /g' tools/Makefile
sed -i 's/tools-y += bison/tools-y += /g' tools/Makefile
sed -i 's/tools-y += flex/tools-y += /g' tools/Makefile

# --- 3. DTS 探测与物理合成 ---
BASE_DTSI=$(find "$ROOT_DIR/target/linux/mediatek" -name "mt7981.dtsi" | head -n 1)
[ -z "$BASE_DTSI" ] && BASE_DTSI=$(find . -name "mt7981.dtsi" | head -n 1)
INC_DIR=$(dirname "$BASE_DTSI")
DTS_DEST="$INC_DIR/mt7981b-sl3000-emmc.dts"

# 物理清洗逻辑：合并为一个无语法冲突的单文件
{
    echo '/dts-v1/;'
    grep "#include" "$BASE_DTSI" | head -n 20
    echo '#include <dt-bindings/leds/common.h>'
    echo '#include <dt-bindings/input/input.h>'
    
    # 注入基础架构并剔除重复标签
    sed -E '/\/dts-v1\/;|#include/d' "$BASE_DTSI"
    [ -f "$INC_DIR/mt7981b.dtsi" ] && sed -E '/\/dts-v1\/;|#include/d' "$INC_DIR/mt7981b.dtsi"
    
    # 注入 SL3000 自定义配置，彻底剥离可能导致 Error 1 的 header
    echo -e "\n/* SL3000 CUSTOM SECTION */\n"
    tr -d '\r' < "$DTS_SRC" | sed -E '/\/dts-v1\/;|#include|mt7981.dtsi|mt7981b.dtsi/d'
} > "$DTS_DEST"

# --- 4. 固件参数强制注入 (1GB 扩容) ---
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
EOT

# 物理劫持镜像规则
[ -f "$MK_SRC" ] && cp -fv "$MK_SRC" "target/linux/mediatek/image/filogic.mk"
make defconfig

echo "✅ [SUCCESS] 物理注入完成，工具链冲突已规避。"
