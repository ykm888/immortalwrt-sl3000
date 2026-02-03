#!/bin/bash
set -e

echo ">>> [SL3000 V16.6-Stable] 启动跨版本物理缝合逻辑..."

# --- 1. 定位源文件 ---
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(cd ..; pwd)
SRC_DIR="${GITHUB_WORKSPACE}/custom-config"
DTS_SRC=$(find "$SRC_DIR" -type f -name "*mt7981b-sl3000-emmc.dts" | head -n 1)
MK_SRC=$(find "$SRC_DIR" -type f -name "filogic.mk" | head -n 1)

# --- 2. 动态探测并缝合 DTS (核心修复点) ---
# 自动寻找 mt7981.dtsi 所在的物理目录（兼容 files-6.1/6.6/6.12 等）
BASE_DTSI=$(find target/linux/mediatek -name "mt7981.dtsi" | head -n 1)

if [ -z "$BASE_DTSI" ]; then
    echo "❌ [错误] 源码树中找不到 mt7981.dtsi，请确认源码下载完整。"
    exit 1
fi

INC_DIR=$(dirname "$BASE_DTSI")
DTS_DEST="$INC_DIR/mt7981b-sl3000-emmc.dts"
echo "📂 基础路径已锁定: $INC_DIR"

# 物理深度缝合：清除重复标签，确保唯一性
{
    echo '/dts-v1/;'
    # 提取基础 dtsi 里的头文件定义，排除重复项
    grep "#include" "$BASE_DTSI" | head -n 20
    echo '#include <dt-bindings/leds/common.h>'
    echo '#include <dt-bindings/input/input.h>'

    # 注入基础架构 (清洗掉 /dts-v1/ 和 #include)
    sed -E '/\/dts-v1\/;|#include/d' "$INC_DIR/mt7981.dtsi"
    [ -f "$INC_DIR/mt7981b.dtsi" ] && sed -E '/\/dts-v1\/;|#include/d' "$INC_DIR/mt7981b.dtsi"
    
    # 注入 SL3000 自定义配置 (清洗掉用户文件里的 include，防止 Error 1)
    echo -e "\n/* --- CUSTOM SL3000 SECTION --- */\n"
    tr -d '\r' < "$DTS_SRC" | sed -E '/\/dts-v1\/;|#include|mt7981.dtsi|mt7981b.dtsi/d'
} > "$DTS_DEST"

# --- 3. 更新 Feeds 并注入扩容配置 ---
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
CONFIG_PACKAGE_luci=y
EOT

# 物理覆盖镜像生成规则
[ -f "$MK_SRC" ] && cp -fv "$MK_SRC" "target/linux/mediatek/image/filogic.mk"
make defconfig

echo "✅ [脚本任务完成] 物理劫持就绪！"
