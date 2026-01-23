# SPDX-License-Identifier: GPL-2.0-only
# ImmortalWrt Filogic image definitions
# Target: mediatek/filogic

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

# ===========================
# SL3000 eMMC — Ultimate Edition
# ===========================

define Device/sl3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := SL-3000
  DEVICE_VARIANT := eMMC

  # DTS 文件路径与名称（Linux 6.6）
  DEVICE_DTS := mt7981b-sl3000-emmc
  DEVICE_DTS_DIR := target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek

  # sysupgrade 兼容性
  SUPPORTED_DEVICES := sl3000-emmc mt7981b-sl3000-emmc
  DEVICE_COMPAT_VERSION := 1.0
  DEVICE_COMPAT_MESSAGE := "SL3000 eMMC Ultimate Edition"

  # 必要驱动与功能包（只保留硬件相关）
  DEVICE_PACKAGES := \
    kmod-mt76 kmod-mt7981-firmware mt7981-wo-firmware \
    kmod-mt7530 kmod-dsa kmod-dsa-mt7530 \
    kmod-mtk-hnat kmod-mt7981-wed \
    kmod-mmc kmod-mmc-mtk \
    kmod-leds-gpio kmod-button-hotplug \
    kmod-nvmem kmod-nvmem-mtk-efuse \
    kmod-hwmon-core kmod-hwmon-mtk \
    kmod-pstore kmod-pstore-ram \
    kmod-fs-ext4 kmod-fs-btrfs kmod-fs-f2fs kmod-dm \
    blockd fstrim fitblk fstools block-mount uboot-envtools \
    irqbalance ethtool tcpdump-mini htop \
    luci luci-theme-bootstrap

  # 移除 USB 驱动（硬件无 USB 控制器）
  DEVICE_PACKAGES := $(filter-out \
    kmod-usb3 kmod-usb2 kmod-usb-storage kmod-usb-storage-uas \
    kmod-usb-ledtrig-usbport, \
    $(DEVICE_PACKAGES))

  # 镜像大小（单位 KB，10GB eMMC）
  IMAGE_SIZE := 10485760

  # 内核与根文件系统配置
  KERNEL := kernel-bin
  KERNEL_INITRAMFS := kernel-bin | lzma
  ROOTFS := squashfs
  ROOTFS_COMPRESSION := lzma

  # 输出镜像类型
  IMAGES := sysupgrade.bin initramfs-recovery.itb

  # sysupgrade 镜像打包流程
  IMAGE/sysupgrade.bin := \
    append-kernel | append-rootfs | pad-rootfs | \
    check-size | append-metadata | check-size

  # initramfs 恢复镜像打包流程
  IMAGE/initramfs-recovery.itb := \
    export-kernel | append-dtb | pad-to 64k | \
    mkits-itb kernel-initramfs | append-metadata
endef

TARGET_DEVICES += sl3000-emmc

$(eval $(call BuildImage))
