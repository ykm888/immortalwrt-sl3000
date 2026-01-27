
define Device/sl-3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := SL-3000
  DEVICE_VARIANT := eMMC
  DEVICE_DTS := mt7981b-sl-3000-emmc
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-mt7981-firmware kmod-usb3 kmod-mmc

  BLOCKSIZE := 128k
  PAGESIZE := 2048

  IMAGES := sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata

  ARTIFACTS := emmc-gpt.bin
  ARTIFACT/emmc-gpt.bin := mt798x-gpt emmc
endef
TARGET_DEVICES += sl-3000-emmc
