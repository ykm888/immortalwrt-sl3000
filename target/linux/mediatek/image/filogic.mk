# SPDX-License-Identifier: GPL-2.0-or-later OR MIT

define Device/mt7981b-sl3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000
  DEVICE_VARIANT := eMMC Flagship
  DEVICE_DTS := mt7981b-sl3000-emmc
  DEVICE_DTS_DIR := ../files-6.6/arch/arm64/boot/dts/mediatek

  DEVICE_PACKAGES := kmod-usb3 kmod-mt7981-firmware mt7981-wo-firmware \
	f2fsck mkf2fs automount block-mount kmod-fs-f2fs kmod-fs-ext4

  IMAGES := sysupgrade.bin

  KERNEL := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb

  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += mt7981b-sl3000-emmc
