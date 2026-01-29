define Device/sl_3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 eMMC
  DEVICE_DTS := mt7981b-sl-3000-emmc
  DEVICE_DTS_DIR := ../dts

  DEVICE_PACKAGES := \
	kmod-mt7915e \
	kmod-mt7981-firmware \
	mt7981-wo-firmware \
	automount \
	coremark \
	blkid blockdev fdisk \
	f2fsck mkf2fs \
	kmod-mmc

  KERNEL := kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb

  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k

  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef

TARGET_DEVICES += sl_3000-emmc
