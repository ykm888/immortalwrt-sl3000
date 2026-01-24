#!/bin/sh
set -e

CONF=".config"
DEV="sl-3000-emmc"

echo "=== 🔍 config 校验开始（sl‑3000‑emmc / 24.10） ==="

# -----------------------------
# 1. 文件存在性
# -----------------------------
if [ ! -f "$CONF" ]; then
  echo "❌ config 文件不存在: $CONF"
  exit 1
fi

# -----------------------------
# 2. 设备启用检查（24.10 正确写法）
# -----------------------------
if ! grep -q "CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_${DEV}=y" "$CONF"; then
  echo "❌ config 未启用设备 ${DEV}"
  exit 1
fi

# -----------------------------
# 3. kernel 版本检查（24.10 = 6.6）
# -----------------------------
if ! grep -q "CONFIG_LINUX_6_6=y" "$CONF"; then
  echo "❌ kernel 版本不是 6.6（24.10 必须为 6.6）"
  exit 1
fi

# -----------------------------
# 4. 隐藏字符检查
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

echo "✔ config 校验通过（设备 / 内核 / 隐藏字符全部正常）"
