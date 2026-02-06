define Device/sl3000-emmc
  DEVICE_VENDOR := SL3000
  DEVICE_MODEL := Custom-1GB-Edition
  DEVICE_DTS := mt7981b-sl3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,sl3000-emmc mediatek,mt7981b mediatek,mt7981
  
  # 定义依然保留，用于其他可能的逻辑引用
  KERNEL_SIZE := 134217728
  IMAGE_SIZE := 1073741824
  
  DEVICE_PACKAGES := \
	kmod-mmc kmod-sdhci-mtk \
	kmod-mt753x \
	kmod-fs-f2fs f2fs-tools f2fsck \
	kmod-usb3 kmod-usb-dwc3-mtk \
	block-mount blkid lsblk parted
  
  IMAGES := sysupgrade.bin
  # 🚀 【核心修复】直接将 128MB 的字节数 (134217728) 硬编码到命令中
  # 这样可以 100% 避开 OpenWrt 变量作用域导致 pad-to 拿不到数字的 bug
  IMAGE/sysupgrade.bin := append-kernel | pad-to 134217728 | append-rootfs | pad-rootfs | check-size | append-metadata
endef
TARGET_DEVICES += sl3000-emmc
