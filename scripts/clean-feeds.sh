#!/bin/bash
set -e

echo ">>> [终极修复] 启动 DTS 物理路径全对齐自愈"

# 1. 环境初始化
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(cd ..; pwd)
SRC_DIR="${GITHUB_WORKSPACE}/custom-config"

# 2. 动态搜索源文件
DTS_SRC=$(find "$SRC_DIR" -name "mt7981b-sl3000-emmc.dts" | head -n 1)
MK_SRC=$(find "$SRC_DIR" -name "filogic.mk" | head -n 1)
CONF_SRC=$(find "$SRC_DIR" -name "sl3000.config" | head -n 1)

if [ -z "$DTS_SRC" ] || [ -z "$MK_SRC" ] || [ -z "$CONF_SRC" ]; then
    echo "FATAL: 无法在 $SRC_DIR 找到三件套文件"
    exit 1
fi

# 3. 确定所有潜在的目标路径 (关键修复)
K_DIR=$(ls -d target/linux/mediatek/files-* 2>/dev/null | head -n 1)
# 路径 A: 内核源码 DTS 目录
DEST_A="$K_DIR/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
# 路径 B: Target 平台 DTS 目录 (ImageBuilder 报错的核心位置)
DEST_B="target/linux/mediatek/dts/mt7981b-sl3000-emmc.dts"
# 路径 C: 顶层根目录的补丁位置 (兜底)
DEST_C="target/linux/mediatek/dts/mediatek/mt7981b-sl3000-emmc.dts"

# 执行物理拷贝
echo ">>> 正在执行全路径 DTS 同步..."
for path in "$DEST_A" "$DEST_B" "$DEST_C"; do
    mkdir -p "$(dirname "$path")"
    cp -v "$DTS_SRC" "$path"
done

# 4. 注入编译配置文件
cp -v "$MK_SRC" "target/linux/mediatek/image/filogic.mk"
mkdir -p configs && cp -v "$CONF_SRC" "configs/sl3000-emmc.config"

# 5. 修正 filogic.mk 中的路径逻辑 (防止打包工具走偏)
echo ">>> 正在修正 filogic.mk 的引用路径..."
# 确保 DEVICE_DTS 变量纯净，不带目录前缀
sed -i 's/DEVICE_DTS := .*/DEVICE_DTS := mt7981b-sl3000-emmc/' target/linux/mediatek/image/filogic.mk

# 6. Feeds 处理
./scripts/feeds update -a
rm -rf package/feeds/helloworld/luci-app-ssr-plus || true
./scripts/feeds install -a

echo ">>> [成功] 物理路径已彻底对齐"
