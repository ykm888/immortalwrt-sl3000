#!/bin/sh

DTS="target/linux/mediatek/dts/mt7981b-sl3000-emmc.dts"
DEV="sl3000-emmc"

echo "=== 🔍 DTS 校验开始 ==="

# 1. 文件存在性
if [ ! -f "$DTS" ]; then
  echo "❌ DTS 文件不存在: $DTS"
  exit 1
fi

# 2. 设备名检查
if ! grep -q "$DEV" "$DTS"; then
  echo "❌ DTS 未包含设备名 $DEV"
  exit 1
fi

# 3. 隐藏字符检查
if grep -q $'\xEF\xBB\xBF' "$DTS"; then
  echo "❌ DTS 含 BOM"
  exit 1
fi

if grep -q $'\r' "$DTS"; then
  echo "❌ DTS 含 CRLF"
  exit 1
fi

if grep -P -q "[\x{200B}\x{200C}\x{200D}]" "$DTS"; then
  echo "❌ DTS 含零宽字符"
  exit 1
fi

echo "✔ DTS 校验通过"
