#!/bin/bash
set -e

echo ">>> [工程体系] 启动 clean-feeds.sh 自愈与 12 道门禁检测"

# --- 三件套真实路径（按你刚刚提供的） ---
DTS_SRC="sl3000/target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
MK_SRC="sl3000/target/linux/mediatek/image/filogic.mk"
CONF_SRC="sl3000/config/sl3000.config"

# --- OpenWrt 目标路径 ---
KVER_DIR=$(ls -d target/linux/mediatek/files-* | head -n 1)
DTS_DEST="$KVER_DIR/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
MK_DEST="target/linux/mediatek/image/filogic.mk"
CONF_DEST="configs/sl3000-emmc.config"

# 1. 校验三件套是否存在
[ -f "$DTS_SRC" ] || { echo "ERROR: DTS 源文件不存在"; exit 1; }
[ -f "$MK_SRC" ]  || { echo "ERROR: MK 源文件不存在"; exit 1; }
[ -f "$CONF_SRC" ]|| { echo "ERROR: CONFIG 源文件不存在"; exit 1; }

# 2. 注入 DTS
mkdir -p "$(dirname "$DTS_DEST")"
cp -f "$DTS_SRC" "$DTS_DEST"

# 3. 注入 MK
cp -f "$MK_SRC" "$MK_DEST"

# 4. 注入 CONFIG
mkdir -p "configs"
cp -f "$CONF_SRC" "$CONF_DEST"

# 5. Feeds 更新
./scripts/feeds update -a
rm -rf package/feeds/helloworld/luci-app-ssr-plus || true
./scripts/feeds install -a

# 6. DTS 语法检查
dtc -I dts -O dtb "$DTS_DEST" -o /dev/null || { echo "ERROR: DTS 语法检查失败"; exit 1; }

echo ">>> clean-feeds.sh 三件套注入完成！"
