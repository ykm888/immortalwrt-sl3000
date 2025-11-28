define Device/siluo_sl3000
  DEVICE_VENDOR := Siluo
  DEVICE_MODEL := SL3000
  DEVICE_DTS := mt7981-siluo-sl3000
  DEVICE_TITLE := Siluo SL3000
  SUPPORTED_DEVICES := siluo,sl3000

  # 仅保留硬件必须包
  DEVICE_PACKAGES := kmod-mt7981-wifi

  IMAGES := sysupgrade.bin initramfs.bin

  IMAGE/sysupgrade.bin := append-rootfs | gzip | append-metadata
  IMAGE/initramfs.bin := append-initramfs | gzip
endef

TARGET_DEVICES += siluo_sl3000
