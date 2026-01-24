#!/bin/sh
set -e

echo "=== 🔍 三件套增强检测开始（sl‑3000‑emmc） ==="

DTS="target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts"
MK="target/linux/mediatek/image/filogic.mk"
CONF=".config"
DEV="sl-3000-emmc"

# -----------------------------
# 1. 文件存在性检查
# -----------------------------
[ -f "$DTS" ] || { echo "❌ DTS 缺失: $DTS"; exit 1; }
[ -f "$MK" ]  || { echo "❌ mk 缺失: $MK"; exit 1; }
[ -f "$CONF" ] || { echo "❌ config 缺失: $CONF"; exit 1; }

echo "✔ 文件存在性检查通过"

# -----------------------------
# 2. 设备一致性检查
# -----------------------------
grep -q "$DEV" "$DTS"  || { echo "❌ DTS 未包含设备名 $DEV"; exit 1; }
grep -q "$DEV" "$MK"   || { echo "❌ mk 未包含设备名 $DEV"; exit 1; }
grep -q "$DEV" "$CONF" || { echo "❌ config 未启用设备 $DEV"; exit 1; }

echo "✔ DTS/mk/config 设备一致性检查通过"

# -----------------------------
# 3. config 隐藏字符检查
# -----------------------------
# BOM
if grep -q $'\xEF\xBB\xBF' "$CONF"; then
    echo "❌ config 含 BOM"
    exit 1
fi

# CRLF
if grep -q $'\r' "$CONF"; then
    echo "❌ config 含 CRLF"
    exit 1
fi

# 零宽字符
if grep -P -q "[\x{200B}\x{200C}\x{200D}]" "$CONF"; then
    echo "❌ config 含零宽字符"
    exit 1
fi

# 控制字符
if grep -P "[\x00-\x1F]" "$CONF" >/dev/null; then
    echo "❌ config 存在控制字符"
    exit 1
fi

echo "✔ 隐藏字符检查通过"

# -----------------------------
# 4. DTS 必要字段检查
# -----------------------------
grep -q 'compatible = "sl,3000-emmc"' "$DTS" || { echo "❌ DTS 缺少 compatible"; exit 1; }
grep -q 'model = "SL 3000 eMMC Router"' "$DTS" || { echo "❌ DTS 缺少 model"; exit 1; }

echo "✔ DTS 字段检查通过"

echo "=== ✅ 三件套增强检测全部通过 ==="
