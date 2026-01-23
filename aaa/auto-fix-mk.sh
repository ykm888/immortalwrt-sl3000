#!/bin/sh
set -e

file="target/linux/mediatek/image/filogic.mk"

echo "=== 🔧 自动修复 mk ==="

if ! grep -q "sl3000-emmc" "$file"; then
    cat << 'EOF' >> "$file"

define Device/sl3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000
  DEVICE_VARIANT := EMMC
  DEVICE_PACKAGES := kmod-mt7981-eth kmod-mt7981-wifi kmod-usb3
endef
TARGET_DEVICES += sl3000-emmc

EOF
    echo "补齐 sl3000-emmc 设备定义"
fi

echo "✔ mk 自动修复完成"
