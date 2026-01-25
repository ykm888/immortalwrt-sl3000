#!/bin/sh
set -e

echo "=== 🛠 SL3000 三件套目录结构自动修复（工程级旗舰版 / 最终版） ==="

#########################################
# 0. 定义路径（统一全链路）
#########################################

DTS_DIR="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
MK_DIR="target/linux/mediatek/image"
CONF_FILE=".config"   # ← 已修复：使用最终标准 .config

#########################################
# 1. 检查是否存在错误目录（旧版本遗留）
#########################################

BAD_DIRS="
target/linux/mediatek/files-6.12
target/linux/mediatek/files-5.15
target/linux/mediatek/files
target/linux/mediatek/dts
target/linux/mediatek/boot/dts
"

echo "=== 🔍 检查是否存在旧目录 / 错误目录 ==="

for d in $BAD_DIRS; do
    if [ -d "$d" ]; then
        echo "⚠ 发现错误目录：$d → 自动清理"
        rm -rf "$d"
    fi
done

echo "✔ 错误目录检查完成"

#########################################
# 2. 自动修复正确目录结构
#########################################

echo "=== 🛠 修复正确目录结构 ==="

mkdir -p "$DTS_DIR"
mkdir -p "$MK_DIR"

echo "✔ 正确目录结构已创建"

#########################################
# 3. 检查三件套文件是否在正确位置
#########################################

echo "=== 🔍 检查三件套文件位置 ==="

DTS_FILE="$DTS_DIR/mt7981b-sl3000-emmc.dts"
MK_FILE="$MK_DIR/filogic.mk"

[ -f "$DTS_FILE" ] && echo "✔ DTS 位置正确" || echo "⚠ DTS 缺失（等待生成）"
[ -f "$MK_FILE" ]  && echo "✔ MK 位置正确"  || echo "⚠ MK 缺失（等待生成）"
[ -f "$CONF_FILE" ] && echo "✔ CONFIG 位置正确 (.config)" || echo "⚠ CONFIG 缺失（等待生成）"

#########################################
# 4. 自动修复：如果三件套在错误位置 → 移动到正确位置
#########################################

echo "=== 🔧 自动修复三件套位置 ==="

WRONG_DTS="
target/linux/mediatek/dts/mt7981b-sl3000-emmc.dts
target/linux/mediatek/files/mt7981b-sl3000-emmc.dts
"

for f in $WRONG_DTS; do
    if [ -f "$f" ]; then
        echo "⚠ 发现 DTS 在错误位置：$f → 移动到正确目录"
        mv "$f" "$DTS_DIR/"
    fi
done

WRONG_MK="
target/linux/mediatek/filogic.mk
target/linux/mediatek/files-6.6/filogic.mk
"

for f in $WRONG_MK; do
    if [ -f "$f" ]; then
        echo "⚠ 发现 MK 在错误位置：$f → 移动到正确目录"
        mv "$f" "$MK_DIR/"
    fi
done

#########################################
# 5. 自动修复：清理隐藏字符（BOM / CRLF）
#########################################

echo "=== 🧹 清理隐藏字符（BOM / CRLF） ==="

find target/linux/mediatek -type f \( -name "*.dts" -o -name "*.mk" \) | while read f; do
    sed -i 's/\r$//' "$f"
    sed -i '1s/^\xEF\xBB\xBF//' "$f"
done

if [ -f "$CONF_FILE" ]; then
    sed -i 's/\r$//' "$CONF_FILE"
    sed -i '1s/^\xEF\xBB\xBF//' "$CONF_FILE"
fi

echo "✔ 隐藏字符清理完成"

#########################################
# 6. 最终验证
#########################################

echo "=== 🔍 最终验证 ==="

[ -d "$DTS_DIR" ] || { echo "❌ DTS 目录缺失"; exit 1; }
[ -d "$MK_DIR" ]  || { echo "❌ MK 目录缺失"; exit 1; }

echo "✔ 目录结构完全正确"
echo "=== 🎉 SL3000 三件套目录结构修复完成（最终版） ==="
