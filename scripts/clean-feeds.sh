#!/bin/bash
set -e

echo ">>> [SL3000 V16.6-Final] 启动增强型物理缝合逻辑..."

# --- 1. 环境与路径初始化 ---
# 无论在哪个目录运行，都自动定位到源码根目录
ROOT_DIR=$(pwd)
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(cd ..; pwd)

SRC_DIR="${GITHUB_WORKSPACE}/custom-config"
DTS_SRC=$(find "$SRC_DIR" -type f -name "*mt7981b-sl3000-emmc.dts" | head -n 1)
MK_SRC=$(find "$SRC_DIR" -type f -name "filogic.mk" | head -n 1)

echo "🔍 正在全盘探测内核基础文件..."
# 动态寻找基础 dtsi (不依赖硬编码路径)
BASE_DTSI=$(find "$ROOT_DIR/target/linux/mediatek" -name "mt7981.dtsi" | head -n 1)

if [ -z "$BASE_DTSI" ]; then
    echo "❌ [严重错误] 无法定位 mt7981.dtsi。请检查源码下载是否完整。"
    echo "当前所在目录: $(pwd)"
    find . -maxdepth 2
    exit 1
fi

INC_DIR=$(dirname "$BASE_DTSI")
DTS_DEST="$INC_DIR/mt7981b-sl3000-emmc.dts"
echo "✅ 基础路径已锁定: $INC_DIR"

# --- 2. DTS 物理清洗缝合 (预防 Error 1) ---
{
    echo '/dts-v1/;'
    # 提取所有必需的头文件，且不重复
    grep "#include" "$BASE_DTSI" | head -n 15
    echo '#include <dt-bindings/leds/common.h>'
    echo '#include <dt-bindings/input/input.h>'

    # 注入基础架构 (物理剔除头声明，防止语法冲突)
    sed -E '/\/dts-v1\/;|#include/d' "$BASE_DTSI"
    
    # 注入你的 SL3000 配置，彻底清洗所有 include
    echo -e "\n/* --- CUSTOM SL3000 SECTION START --- */\n"
    tr -d '\r' < "$DTS_SRC" | sed -E '/\/dts-v1\/;|#include|mt7981.dtsi/d'
} > "$DTS_DEST"

# --- 3. 更新 Feeds 并注入扩容补丁 ---
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

# 物理劫持镜像生成规则 (确保 1GB GPT 分区生效)
[ -f "$MK_SRC" ] && cp -fv "$MK_SRC" "target/linux/mediatek/image/filogic.mk"
make defconfig

echo "✅ [完成] 脚本物理修复已就绪！"
