#!/bin/sh
set -e

file="target/linux/mediatek/image/filogic.mk"

echo "=== 🔧 自动修复 mk（sl‑3000‑emmc） ==="

# 如果设备段不存在则追加
if ! grep -q "sl-3000-emmc" "$file"; then
    cat << 'EOF' >> "$file"

###########################################################
#  SL‑3000‑eMMC 设备定义（自动补齐）
###########################################################

define Device/sl-3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000
  DEVICE_VARIANT := eMMC bootstrap

  DEVICE_DTS := mt7981b-sl-3000-emmc
  DEVICE_DTS_DIR := ../dts

  DEVICE_PACKAGES := kmod-usb3 kmod-mt7981-firmware mt7981-wo-firmware \
        f2fsck mkf2fs automount

  IMAGES := sysupgrade.bin

  KERNEL := kernel-bin | lzma | \
        fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb

  KERNEL_INITRAMFS := kernel-bin | lzma | \
        fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k

  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += sl-3000-emmc

EOF

    echo "补齐 sl‑3000‑emmc 设备定义"
fi

echo "✔ mk 自动修复完成（已写入完整设备段）"
