#!/bin/sh
set -e

CONF=".config"

echo "=== 📝 正在生成完整 .config（sl‑3000‑emmc / 24.10） ==="

cat > "$CONF" << 'EOF'
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_sl-3000-emmc=y
CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_sl-3000-emmc=y

# 内核版本（24.10 = 6.6）
CONFIG_LINUX_6_6=y

# RootFS / 文件系统支持
CONFIG_TARGET_ROOTFS_INITRAMFS=y
CONFIG_TARGET_ROOTFS_SQUASHFS=y
CONFIG_TARGET_ROOTFS_EXT4FS=y
CONFIG_TARGET_ROOTFS_PARTSIZE=160

CONFIG_PACKAGE_block-mount=y
CONFIG_PACKAGE_automount=y
CONFIG_PACKAGE_fdisk=y
CONFIG_PACKAGE_blkid=y
CONFIG_PACKAGE_f2fsck=y
CONFIG_PACKAGE_mkf2fs=y
CONFIG_PACKAGE_resize2fs=y

# 常用工具
CONFIG_PACKAGE_coremark=y
CONFIG_PACKAGE_htop=y
CONFIG_PACKAGE_iperf3=y
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_wget=y

# 驱动支持（MT7981 + eMMC）
CONFIG_PACKAGE_kmod-mt7981-firmware=y
CONFIG_PACKAGE_kmod-mt7981-eth=y
CONFIG_PACKAGE_kmod-mt7981-wifi=y
CONFIG_PACKAGE_kmod-usb3=y
CONFIG_PACKAGE_kmod-sdhci-mt7981=y
CONFIG_PACKAGE_kmod-mmc=y
CONFIG_PACKAGE_kmod-leds-gpio=y
CONFIG_PACKAGE_kmod-gpio-button-hotplug=y

# Busybox 常用功能
CONFIG_BUSYBOX_CUSTOM=y
CONFIG_BUSYBOX_CONFIG_FEATURE_EDITING=y
CONFIG_BUSYBOX_CONFIG_FEATURE_EDITING_HISTORY=256
CONFIG_BUSYBOX_CONFIG_FEATURE_EDITING_SAVEHISTORY=y
CONFIG_BUSYBOX_CONFIG_FEATURE_EDITING_FANCY_PROMPT=y
EOF

git add "$CONF"

echo "✔ .config 已生成（完整配置写入成功）"
