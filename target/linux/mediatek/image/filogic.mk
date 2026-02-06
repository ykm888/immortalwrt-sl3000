define Device/sl3000-emmc
  DEVICE_VENDOR := SL3000
  DEVICE_MODEL := Custom-1GB-Edition
  DEVICE_DTS := mt7981b-sl3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,sl3000-emmc mediatek,mt7981b mediatek,mt7981
  
  # 128MB = 134217728 Bytes
  KERNEL_SIZE := 134217728
  # 1GB = 1073741824 Bytes
  IMAGE_SIZE := 1073741824
  
  DEVICE_PACKAGES := \
	kmod-mmc kmod-sdhci-mtk \
	kmod-mt753x \
	kmod-fs-f2fs f2fs-tools f2fsck \
	kmod-usb3 kmod-usb-dwc3-mtk \
	block-mount blkid lsblk parted
  
  IMAGES := sysupgrade.bin
  # 核心修复：这里必须使用单 $ 符号，否则 pad-to 接收不到参数
  IMAGE/sysupgrade.bin := append-kernel | pad-to $(KERNEL_SIZE) | append-rootfs | pad-rootfs | check-size | append-metadata
endef
TARGET_DEVICES += sl3000-emmc
