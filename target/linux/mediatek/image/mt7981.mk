define Device/siluo_sl3000
  DEVICE_VENDOR := Siluo
  DEVICE_MODEL := SL3000
  DEVICE_DTS := mt7981-siluo-sl3000
  DEVICE_TITLE := Siluo SL3000
  SUPPORTED_DEVICES := siluo,sl3000

  # 必须的硬件驱动包
  DEVICE_PACKAGES := kmod-mt7981-wifi

  # 定义生成的镜像类型
  IMAGES := preloader.bin uboot.bin sysupgrade.bin initramfs.bin

  # 各镜像规则
  IMAGE/preloader.bin := append-preloader
  IMAGE/uboot.bin := append-uboot
  IMAGE/sysupgrade.bin := append-rootfs | gzip | append-metadata
  IMAGE/initramfs.bin := append-initramfs | gzip
endef

TARGET_DEVICES += siluo_sl3000

