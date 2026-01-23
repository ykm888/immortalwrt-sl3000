#!/bin/sh

CONF=".config"
DEV="sl3000-emmc"

echo "=== 🔍 config 校验开始 ==="

# 1. 文件存在性
if [ ! -f "$CONF" ]; then
  echo "❌ config 文件不存在: $CONF"
  exit 1
fi

# 2. 设备启用检查
if ! grep -q "CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_${DEV}=y" "$CONF"; then
  echo "❌ config 未启用设备 $DEV"
  exit 1
fi

# 3. kernel 版本检查
if grep -q "CONFIG_LINUX_6_12=y" "$CONF"; then
  echo "⚠️ 检测到 CONFIG_LINUX_6_12=y，应为 6.6"
  exit 1
fi

# 4. 隐藏字符检查
if grep -q $'\xEF\xBB\xBF' "$CONF"; then
  echo "❌ config 含 BOM"
  exit 1
fi

if grep -q $'\r' "$CONF"; then
  echo "❌ config 含 CRLF"
  exit 1
fi

if grep -P -q "[\x{200B}\x{200C}\x{200D}]" "$CONF"; then
  echo "❌ config 含零宽字符"
  exit 1
fi

echo "✔ config 校验通过"
