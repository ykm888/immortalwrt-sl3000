#!/bin/sh
set -e

DTS="target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts"
DEV="sl-3000-emmc"

echo "=== 🔍 DTS 校验开始（sl‑3000‑emmc） ==="

# -----------------------------
# 1. 文件存在性
# -----------------------------
if [ ! -f "$DTS" ]; then
  echo "❌ DTS 文件不存在: $DTS"
  exit 1
fi

# -----------------------------
# 2. 设备名检查（必须包含 sl‑3000‑emmc）
# -----------------------------
if ! grep -q "$DEV" "$DTS"; then
  echo "❌ DTS 未包含设备名 $DEV"
  exit 1
fi

# -----------------------------
# 3. 必要字段检查
# -----------------------------
if ! grep -q 'compatible = "sl,3000-emmc"' "$DTS"; then
  echo "❌ DTS 缺少 compatible = \"sl,3000-emmc\""
  exit 1
fi

if ! grep -q 'model = "SL 3000 eMMC Router"' "$DTS"; then
  echo "❌ DTS 缺少 model = \"SL 3000 eMMC Router\""
  exit 1
fi

# -----------------------------
# 4. 隐藏字符检查
# -----------------------------
# BOM
if grep -q $'\xEF\xBB\xBF' "$DTS"; then
  echo "❌ DTS 含 BOM"
  exit 1
fi

# CRLF
if grep -q $'\r' "$DTS"; then
  echo "❌ DTS 含 CRLF"
  exit 1
fi

# 零宽字符
if grep -P -q "[\x{200B}\x{200C}\x{200D}]" "$DTS"; then
  echo "❌ DTS 含零宽字符"
  exit 1
fi

echo "✔ DTS 校验通过（文件 / 设备名 / 字段 / 隐藏字符全部正常）"
