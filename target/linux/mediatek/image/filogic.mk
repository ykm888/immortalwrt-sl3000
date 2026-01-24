define Device/mt7981b-sl3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := SL3000 eMMC Flagship
  DEVICE_PACKAGES := kmod-usb3 kmod-mt7981-firmware \
        luci-app-passwall2 docker dockerd luci-app-dockerman
  IMAGE/sysupgrade.bin := append-kernel | append-rootfs | pad-rootfs | append-metadata
endef
TARGET_DEVICES += mt7981b-sl3000-emmc
