#!/bin/bash
set -e

# ============================================================
# SL3000 24.10 专用版：【探测-修复-注册-合并】合一脚本 V13.1
# ============================================================

echo ">>> [SL3000 24.10 模式] 启动全链路自愈..."

# --- 1. 定位源文件 ---
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(cd ..; pwd)
SRC_DIR="${GITHUB_WORKSPACE}/custom-config"

DTS_SRC=$(find "$SRC_DIR" -type f -name "*mt7981b-sl3000-emmc.dts" | head -n 1)
MK_SRC=$(find "$SRC_DIR" -type f -name "filogic.mk" | head -n 1)
CONF_SRC=$(find "$SRC_DIR" -name "sl3000.config" | head -n 1)

[ -z "$DTS_SRC" ] && { echo "❌ 错误: 找不到 DTS 源文件"; exit 1; }

# --- 2. 预先注入与头文件自愈 ---
# 针对 24.10 动态锁定 files-6.6 或类似目录
K_DIR=$(ls -d target/linux/mediatek/files-* 2>/dev/null | sort -V | tail -n 1)
[ -z "$K_DIR" ] && { echo "❌ 无法定位内核 files 目录"; exit 1; }
DTS_DEST="$K_DIR/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"

mkdir -p "$(dirname "$DTS_DEST")"

echo ">>> [自愈] 修复 DTS 内部头文件引用路径 (24.10 规范)..."
# 将本地引用转换为内核标准的系统引用，防止 cc1 编译时找不到 mt7981.dtsi
sed -e 's/#include "mt7981.dtsi"/#include <mediatek\/mt7981.dtsi>/g' \
    -e 's/#include "mt7981b.dtsi"/#include <mediatek\/mt7981b.dtsi>/g' \
    "$DTS_SRC" > "$DTS_DEST"

# --- 3. 驱动注册与内核 Makefile 补丁 ---
echo ">>> [注册] 补全 eMMC 驱动并注册设备至内核编译链..."
# 确保 filogic.mk 包含 eMMC 启动必需驱动
if ! grep -q "kmod-mtk-sd" "$MK_SRC"; then
    sed -i '/DEVICE_PACKAGES/ s/$/ kmod-mmc kmod-mtk-sd kmod-fs-f2fs f2fs-tools/' "$MK_SRC"
fi
cp -f "$MK_SRC" "target/linux/mediatek/image/filogic.mk"

# 关键：在内核 Makefile 中插入编译指令，否则生成不了 dtb
K_MAKEFILE="$K_DIR/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$K_MAKEFILE" ]; then
    grep -q "mt7981b-sl3000-emmc.dtb" "$K_MAKEFILE" || \
    sed -i '/dtb-$(CONFIG_ARCH_MEDIATEK)/a dtb-$(CONFIG_ARCH_MEDIATEK) += mt7981b-sl3000-emmc.dtb' "$K_MAKEFILE"
fi

# --- 4. 配置合并与 Feeds 优化 ---
echo ">>> [合并] 注入 GPT 分区与环境优化..."
mkdir -p configs && cp -f "$CONF_SRC" "configs/sl3000-emmc.config"

# 修复 Git 协议与 Feeds 冲突
git config --global url."https://github.com/".insteadOf git://github.com/
sed -i '/passwall/d' feeds.conf.default
echo "src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages.git;main" >> feeds.conf.default
echo "src-git passwall https://github.com/xiaorouji/openwrt-passwall.git;main" >> feeds.conf.default

./scripts/feeds update -a || echo "⚠️ 部分 Feed 更新失败"
./scripts/feeds install -a

# 解决 PHP 递归依赖（PHP8 补丁）
[ -d "feeds/packages/admin/zabbix" ] && find feeds/packages/admin/zabbix -name Makefile -exec sed -i 's/select PACKAGE_php8/depends on PACKAGE_php8/g' {} +

echo "✅ [任务完成] 24.10 自愈环境已就绪！"
