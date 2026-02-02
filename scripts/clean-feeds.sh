#!/bin/bash
set -e

echo ">>> [工程体系] 启动 clean-feeds.sh 自愈与 12 道门禁检测"

# --- 环境变量自愈 ---
SEARCH_ROOT="${GITHUB_WORKSPACE:-$(cd ..; pwd)}/custom-config"

# 1. 环境校验
[ -f "scripts/feeds" ] || { echo "ERROR: 必须在 OpenWrt 根目录运行"; exit 1; }

# 2. 动态探测内核版本路径
KVER_DIR=$(ls -d target/linux/mediatek/files-* 2>/dev/null | head -n 1)
[ -z "$KVER_DIR" ] && { echo "ERROR: 找不到内核 files 目录"; exit 1; }
DTS_DEST="$KVER_DIR/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"

# 3. 动态寻找源文件
echo ">>> 正在搜索源文件..."
DTS_SRC=$(find "$SEARCH_ROOT" -name "mt7981b-sl3000-emmc.dts" | head -n 1)
MK_SRC=$(find "$SEARCH_ROOT" -name "filogic.mk" | head -n 1)
CONF_SRC=$(find "$SEARCH_ROOT" -name "sl3000.config" | head -n 1)

[ -n "$DTS_SRC" ] && [ -n "$MK_SRC" ] && [ -n "$CONF_SRC" ] || { echo "ERROR: 资源文件搜索失败"; exit 1; }

# 4. 执行三件套注入
echo ">>> 正在执行三件套注入..."
mkdir -p "$(dirname "$DTS_DEST")"
cp -f "$DTS_SRC" "$DTS_DEST"

cp -f "$MK_SRC" "target/linux/mediatek/image/filogic.mk"

mkdir -p "configs"
cp -f "$CONF_SRC" "configs/sl3000-emmc.config"

# 5. Feeds 更新与冲突预处理
echo ">>> 正在同步 Feeds 并处理包冲突..."
./scripts/feeds update -a
# 预处理：删除可能引起编译中断的重复包定义
rm -rf package/feeds/helloworld/luci-app-ssr-plus || true
./scripts/feeds install -a

# --- 12 道工程门禁实装（只检测 + 修复 MK，不再动 .config） ---
echo ">>> 启动 12 道工程门禁..."

# 1. DTS 注入物理存在
[ -f "$DTS_DEST" ] || { echo "ERROR: 1. DTS 注入物理失败"; exit 1; }

# 2. DTS SoC 定义
grep -q "mediatek,mt7981" "$DTS_DEST" || { echo "ERROR: 2. DTS SoC 定义不匹配"; exit 1; }

# 3. DTS 语法检查
dtc -I dts -O dtb "$DTS_DEST" -o /dev/null || { echo "ERROR: 3. DTS 语法检查未通过"; exit 1; }

# 4. MK 模板存在 sl3000-emmc 设备定义
grep -q "Device/sl3000-emmc" "target/linux/mediatek/image/filogic.mk" || { echo "ERROR: 4. MK 模板缺少设备定义"; exit 1; }

# 5. Config 中包含 sl3000-emmc 相关内容
grep -q "sl3000-emmc" "configs/sl3000-emmc.config" || { echo "ERROR: 5. Config 缺少目标 Profile"; exit 1; }

# 6. DTS 非空
[ -s "$DTS_DEST" ] || { echo "ERROR: 6. DTS 文件为空"; exit 1; }

# 7. MK 非空
[ -s "target/linux/mediatek/image/filogic.mk" ] || { echo "ERROR: 7. MK 文件为空"; exit 1; }

# 8. Config 非空
[ -s "configs/sl3000-emmc.config" ] || { echo "ERROR: 8. Config 文件为空"; exit 1; }

# 9. MK 中包含 TARGET_DEVICES 注册
grep -q "TARGET_DEVICES += sl3000-emmc" "target/linux/mediatek/image/filogic.mk" || { echo "ERROR: 9. MK 未注册设备"; exit 1; }

# 10. Config 中包含 mediatek_filogic 平台
grep -q "CONFIG_TARGET_mediatek_filogic=y" "configs/sl3000-emmc.config" || { echo "ERROR: 10. Config 平台定义缺失"; exit 1; }

# 11. 精准修复 MK (使用强力补丁模式)
echo ">>> 11. 正在执行 MK 精准修复..."
awk -v dts="mt7981b-sl3000-emmc" '
/define Device\/sl3000-emmc/ {in_block=1; found_dts=0; print; next}
in_block && /DEVICE_DTS :=/ {print "  DEVICE_DTS := "dts; found_dts=1; next}
/endef/ && in_block {
    if (!found_dts) print "  DEVICE_DTS := "dts;
    in_block=0; print; next
}
{print}
' "target/linux/mediatek/image/filogic.mk" > "filogic.mk.tmp" && mv "filogic.mk.tmp" "target/linux/mediatek/image/filogic.mk"

# 12. 不再在这里修改 .config，由工作流统一控制
echo ">>> 12. 配置注册交由工作流统一处理（此处不再修改 .config）"

echo ">>> clean-feeds.sh 顺利通过所有门禁！"
