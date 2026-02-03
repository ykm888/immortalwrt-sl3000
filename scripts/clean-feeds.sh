#!/bin/bash
# ============================================================
# SL3000 V18.5 彻底解决版：【物理扁平化-路径脱敏-生态对齐】
# 解决：fatal error: mediatek/mt7981.dtsi: No such file
# ============================================================
set -e

echo ">>> [SL3000 V18.5] 启动 DTS 物理扁平化逻辑..."

# --- 1. 定位源文件 ---
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(cd ..; pwd)
SRC_DIR="${GITHUB_WORKSPACE}/custom-config"

DTS_SRC=$(find "$SRC_DIR" -type f -name "*mt7981b-sl3000-emmc.dts" | head -n 1)
MK_SRC=$(find "$SRC_DIR" -type f -name "filogic.mk" | head -n 1)
CONF_SRC=$(find "$SRC_DIR" -type f -name "*sl3000.config" | head -n 1)

# --- 2. 核心：物理化 DTS (消除 #include 依赖) ---
K_DIR=$(ls -d target/linux/mediatek/files-* 2>/dev/null | sort -V | tail -n 1)
[ -z "$K_DIR" ] && K_DIR="target/linux/mediatek/files-6.6"
DTS_DEST="$K_DIR/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
INC_DIR="$K_DIR/arch/arm64/boot/dts/mediatek"

mkdir -p "$(dirname "$DTS_DEST")"

echo ">>> [核心操作] 正在将 mt7981.dtsi 内容物理注入主文件..."
# 创建临时扁平化文件，保留标准的 bindings include (它们通过全局路径查找，是安全的)
cat <<EOT > "$DTS_DEST.tmp"
/dts-v1/;
#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/leds/common.h>
EOT

# 依次抓取并追加 .dtsi 内容，同时过滤掉它们自带的 /dts-v1/ 声明和二次 include
grep -v "/dts-v1/;" "$INC_DIR/mt7981.dtsi" | grep -v "#include" >> "$DTS_DEST.tmp"
grep -v "/dts-v1/;" "$INC_DIR/mt7981b.dtsi" | grep -v "#include" >> "$DTS_DEST.tmp"

# 最后追加你自己的 DTS 内容，过滤掉原本失效的 include 语句
grep -v "/dts-v1/;" "$DTS_SRC" | grep -v "mt7981.dtsi" | grep -v "mt7981b.dtsi" >> "$DTS_DEST.tmp"

# 覆盖到内核文件库
cp -f "$DTS_DEST.tmp" "$DTS_DEST"
rm -f "$DTS_DEST.tmp"

# --- 3. 注册 Makefile ---
K_MAKEFILE="$K_DIR/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$K_MAKEFILE" ]; then
    sed -i '/mt7981b-sl3000-emmc.dtb/d' "$K_MAKEFILE"
    sed -i '/dtb-$(CONFIG_ARCH_MEDIATEK)/a dtb-$(CONFIG_ARCH_MEDIATEK) += mt7981b-sl3000-emmc.dtb' "$K_MAKEFILE"
fi

# --- 4. 同步 MK 与 Config ---
[ -f "$MK_SRC" ] && cp -f "$MK_SRC" "target/linux/mediatek/image/filogic.mk"
[ -f "$CONF_SRC" ] && cat "$CONF_SRC" > .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" >> .config

# --- 5. Feeds 环境自愈 ---
./scripts/feeds update -a && ./scripts/feeds install -a

echo "✅ [任务完成] DTS 已转换为独立扁平化模式，风险点已物理消除！"
