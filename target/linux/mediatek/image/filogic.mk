# SPDX-License-Identifier: GPL-2.0-or-later OR MIT

define Device/sl3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 eMMC
  DEVICE_DTS := mt7981b-sl3000-emmc
  DEVICE_PACKAGES := kmod-mt7981-firmware \
                     kmod-usb3 \
                     kmod-mt7981-eth \
                     kmod-mt7981-wifi \
                     kmod-sdhci-mt7981 \
                     kmod-mmc \
                     kmod-leds-gpio \
                     kmod-gpio-button-hotplug
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += sl3000-emmc
