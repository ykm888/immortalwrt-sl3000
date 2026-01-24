#!/bin/sh
set -e

echo "=== 🛠 生成 SL3000 eMMC 三件套（24.10 / Linux 6.6） ==="

#########################################
# 1. DTS（24.10 → files-6.6）
#########################################

DTS="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
mkdir -p target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek

cat > "$DTS" << 'EOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT
/dts-v1/;

/* 你的 DTS 内容放这里（略） */
EOF

echo "✔ DTS 生成完成"


#########################################
# 2. MK（24.10）
#########################################

MK="target/linux/mediatek/image/filogic.mk"
mkdir -p target/linux/mediatek/image

cat > "$MK" << 'EOF'
# SPDX-License-Identifier: GPL-2.0-or-later OR MIT

define Device/mt7981b-sl3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000
  DEVICE_VARIANT := eMMC
  DEVICE_DTS := mt7981b-sl3000-emmc
  DEVICE_DTS_DIR := ../files-6.6/arch/arm64/boot/dts/mediatek

  DEVICE_PACKAGES := kmod-usb3 kmod-mt7981-firmware mt7981-wo-firmware \
	f2fsck mkf2fs automount

  IMAGES := sysupgrade.bin

  KERNEL := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb

  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += mt7981b-sl3000-emmc
EOF

echo "✔ MK 生成完成"


#########################################
# 3. CONFIG（24.10）
#########################################

CONF=".config"

cat > "$CONF" << 'EOF'
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_mt7981b-sl3000-emmc=y
CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_mt7981b-sl3000-emmc=y
CONFIG_LINUX_6_6=y
EOF

echo "✔ CONFIG 生成完成"
echo "=== 🎉 三件套生成完成（24.10 / Linux 6.6） ==="
