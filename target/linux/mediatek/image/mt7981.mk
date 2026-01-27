
define Device/sl-3000-emmc
	DEVICE_VENDOR := SL
	DEVICE_MODEL := SL3000 eMMC Engineering Flagship Edition
	DEVICE_DTS := mt7981b-sl-3000-emmc
	DEVICE_PACKAGES := kmod-fs-ext4 block-mount
	IMAGES := sysupgrade.bin
	IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += sl-3000-emmc
