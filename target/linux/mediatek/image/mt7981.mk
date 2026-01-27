
define Device/sl-3000-emmc
	DEVICE_VENDOR := SL
	DEVICE_MODEL := SL3000
	DEVICE_VARIANT := eMMC
	DEVICE_DTS := mt7981b-sl-3000-emmc
	DEVICE_DTS_DIR := ../dts
	DEVICE_PACKAGES := kmod-usb3 kmod-fs-ext4 block-mount f2fs-tools 		luci luci-base luci-i18n-base-zh-cn 		luci-app-eqos-mtk luci-app-mtwifi-cfg luci-app-turboacc-mtk luci-app-wrtbwmon
	IMAGES := sysupgrade.bin
	IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
	IMAGE/initramfs.bin := append-dtb | uImage | append-metadata
endef
TARGET_DEVICES += sl-3000-emmc
