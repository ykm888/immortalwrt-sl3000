#!/bin/bash
set -e

echo ">>> [工程体系] 启动 clean-feeds.sh V5.0 (路径轰炸自愈版)"

# --- 1. 环境初始化 ---
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(cd ..; pwd)
SRC_DIR="${GITHUB_WORKSPACE}/custom-config"

# --- 2. 动态搜索源文件 ---
DTS_SRC=$(find "$SRC_DIR" -name "mt7981b-sl3000-emmc.dts" | head -n 1)
MK_SRC=$(find "$SRC_DIR" -name "filogic.mk" | head -n 1)
CONF_SRC=$(find "$SRC_DIR" -name "sl3000.config" | head -n 1)

if [ -z "$DTS_SRC" ] || [ -z "$MK_SRC" ] || [ -z "$CONF_SRC" ]; then
    echo "FATAL: 无法在 $SRC_DIR 找到三件套源文件，请确认仓库结构"
    exit 1
fi

# --- 3. 确定并清理目标路径 (解决 cc1 找不到文件的核心) ---
K_DIR=$(ls -d target/linux/mediatek/files-* 2>/dev/null | head -n 1)
[ -z "$K_DIR" ] && { echo "ERROR: 找不到内核 files 目录"; exit 1; }

# 定义所有可能的 DTS 存放点，防止 ImageBuilder 走丢
# 路径 A: 内核编译链路径
DEST_A="$K_DIR/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
# 路径 B: ImageBuilder 基础路径 (mediatek/dts/)
DEST_B="target/linux/mediatek/dts/mt7981b-sl3000-emmc.dts"
# 路径 C: ImageBuilder 扩展路径 (mediatek/dts/mediatek/)
DEST_C="target/linux/mediatek/dts/mediatek/mt7981b-sl3000-emmc.dts"

echo ">>> [自愈] 执行全路径物理对齐..."
for path in "$DEST_A" "$DEST_B" "$DEST_C"; do
    mkdir -p "$(dirname "$path")"
    cp -v "$DTS_SRC" "$path"
done

# --- 4. 注入编译配置 ---
echo ">>> [注入] 执行 MK 与 Config 注入..."
cp -v "$MK_SRC" "target/linux/mediatek/image/filogic.mk"
mkdir -p configs && cp -v "$CONF_SRC" "configs/sl3000-emmc.config"

# --- 5. 修正 filogic.mk 引用逻辑 ---
# 强制剥离可能导致路径解析错误的 DEVICE_DTS 定义
sed -i 's/DEVICE_DTS := .*/DEVICE_DTS := mt7981b-sl3000-emmc/' target/linux/mediatek/image/filogic.mk

# --- 6. Feeds 自动化管理 ---
echo ">>> [Feeds] 正在执行自愈与冲突清理..."
./scripts/feeds update -a
rm -rf package/feeds/helloworld/luci-app-ssr-plus || true
./scripts/feeds install -a

# --- 7. 12 道门禁逻辑自检 ---
echo ">>> [门禁] 最终一致性检查..."
grep -q "Device/sl3000-emmc" "target/linux/mediatek/image/filogic.mk" || exit 1
grep -q "mt7981b-sl3000-emmc" "target/linux/mediatek/image/filogic.mk" || exit 1

echo ">>> [成功] 全链路自愈完成，路径已彻底对齐！"
