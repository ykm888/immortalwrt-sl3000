#!/bin/sh

MK="target/linux/mediatek/image/filogic.mk"
DEV="sl3000-emmc"

echo "=== 🔍 mk 校验开始 ==="

# 1. 文件存在性
if [ ! -f "$MK" ]; then
  echo "❌ mk 文件不存在: $MK"
  exit 1
fi

# 2. 设备段检查
if ! grep -q "Device/$DEV" "$MK"; then
  echo "❌ mk 未定义 Device/$DEV"
  exit 1
fi

if ! grep -q "TARGET_DEVICES += $DEV" "$MK"; then
  echo "❌ mk 未加入 TARGET_DEVICES += $DEV"
  exit 1
fi

# 3. 隐藏字符检查
if grep -q $'\xEF\xBB\xBF' "$MK"; then
  echo "❌ mk 含 BOM"
  exit 1
fi

if grep -q $'\r' "$MK"; then
  echo "❌ mk 含 CRLF"
  exit 1
fi

if grep -P -q "[\x{200B}\x{200C}\x{200D}]" "$MK"; then
  echo "❌ mk 含零宽字符"
  exit 1
fi

echo "✔ mk 校验通过"
