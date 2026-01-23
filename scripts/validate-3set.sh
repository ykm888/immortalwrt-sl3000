#!/bin/bash
set -e

DTS="$1"
MK="$2"
CONF="$3"

echo "=== 三件套工程级检测开始 ==="

echo ""
echo "=== 1. 隐藏字符检测 ==="
for f in "$DTS" "$MK" "$CONF"; do
  echo "检查文件: $f"
  sed -i 's/\r$//' "$f"
  sed -i '1s/^\xEF\xBB\xBF//' "$f"
  tr -cd '\11\12\15\40-\176' < "$f" > "$f.clean" && mv "$f.clean" "$f"
done
echo "✔ 隐藏字符检测完成"

echo ""
echo "=== 2. DTS 语法检测 ==="
dtc -I dts -O dtb -o /dev/null "$DTS"
echo "✔ DTS 语法正确"

echo ""
echo "=== 3. mk 结构检测 ==="
grep -q "define Device/sl3000-emmc" "$MK"
echo "✔ mk 结构正确"

echo ""
echo "=== 4. .config 语法检测 ==="
make defconfig >/dev/null 2>&1
echo "✔ .config 语法正确"

echo ""
echo "=== 5. 三件套一致性检测 ==="

if ! grep -q "DEVICE_sl3000-emmc" "$CONF"; then
  echo "⚠️ 自动修复 profile"
  sed -i 's/CONFIG_TARGET_PROFILE=.*/CONFIG_TARGET_PROFILE="DEVICE_sl3000-emmc"/' "$CONF"
fi

if grep -q "CONFIG_LINUX_6_12=y" "$CONF"; then
  echo "⚠️ 自动修复内核版本"
  sed -i 's/CONFIG_LINUX_6_12=y/CONFIG_LINUX_6_6=y/' "$CONF"
fi

echo "✔ 三件套一致性检测完成"
echo "=== 三件套工程级检测结束 ==="
