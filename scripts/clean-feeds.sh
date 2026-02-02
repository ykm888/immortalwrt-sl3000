#!/bin/bash
set -e

echo ">>> [工程体系] 启动 clean-feeds.sh V6.0 (内核预备自愈版)"

# --- 1. 环境初始化 ---
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(cd ..; pwd)
SRC_DIR="${GITHUB_WORKSPACE}/custom-config"

# --- 2. 动态搜索源文件 ---
DTS_SRC=$(find "$SRC_DIR" -name "mt7981b-sl3000-emmc.dts" | head -n 1)
MK_SRC=$(find "$SRC_DIR" -name "filogic.mk" | head -n 1)
CONF_SRC=$(find "$SRC_DIR" -name "sl3000.config" | head -n 1)

if [ -z "$DTS_SRC" ] || [ -z "$MK_SRC" ] || [ -z "$CONF_SRC" ]; then
    echo "FATAL: 无法在 $SRC_DIR 找到三件套源文件"
    exit 1
fi

# --- 3. 基础注入 (内核 files 目录) ---
# 这是为了让内核在初次解压时能同步这个文件
K_VERSION_DIR=$(ls -d target/linux/mediatek/files-* 2>/dev/null | head -n 1)
if [ -n "$K_VERSION_DIR" ]; then
    DEST_K="$K_VERSION_DIR/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
    mkdir -p "$(dirname "$DEST_K")"
    cp -v "$DTS_SRC" "$DEST_K"
fi

# --- 4. 镜像生成配置注入 ---
echo ">>> [注入] 注入 filogic.mk 并强制修正路径..."
cp -v "$MK_SRC" "target/linux/mediatek/image/filogic.mk"
mkdir -p configs && cp -v "$CONF_SRC" "configs/sl3000-emmc.config"

# 关键：彻底修正 MK 里的 DTS 引用，确保它不带任何冗余前缀
sed -i 's/DEVICE_DTS := .*/DEVICE_DTS := mt7981b-sl3000-emmc/' target/linux/mediatek/image/filogic.mk

# --- 5. Feeds 自动化管理 ---
./scripts/feeds update -a
rm -rf package/feeds/helloworld/luci-app-ssr-plus || true
./scripts/feeds install -a

echo ">>> [成功] 初始注入与 Feeds 环境已就绪！"
