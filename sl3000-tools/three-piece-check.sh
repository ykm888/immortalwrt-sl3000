#!/bin/sh
set -e

echo "=== 🔍 三件套校验开始 ==="

DTS="target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts"
MK="target/linux/mediatek/image/filogic.mk"
CONF=".config"
DEV="sl-3000-emmc"

# 文件存在性
[ -f "$DTS" ] || { echo "❌ DTS 缺失"; exit 1; }
[ -f "$MK" ]  || { echo "❌ MK 缺失"; exit 1; }
[ -f "$CONF" ] || { echo "❌ CONFIG 缺失"; exit 1; }
echo "✔ 文件存在性通过"

# 设备一致性
grep -q "$DEV" "$DTS"  || { echo "❌ DTS 未包含设备名"; exit 1; }
grep -q "$DEV" "$MK"   || { echo "❌ MK 未包含设备名"; exit 1; }
grep -q "$DEV" "$CONF" || { echo "❌ CONFIG 未启用设备"; exit 1; }
echo "✔ 设备一致性通过"

# CONFIG 内核版本
grep -q "CONFIG_LINUX_6_6=y" "$CONF" || { echo "❌ CONFIG 未启用内核 6.6"; exit 1; }
echo "✔ CONFIG 内核检查通过"

# 隐藏字符检查
for f in "$DTS" "$MK" "$CONF"; do
    grep -q $'\xEF\xBB\xBF' "$f" && { echo "❌ $f 含 BOM"; exit 1; }
    grep -q $'\r' "$f" && { echo "❌ $f 含 CRLF"; exit 1; }
done

echo "✔ 隐藏字符检查通过"
echo "=== ✅ 三件套校验全部通过 ==="
