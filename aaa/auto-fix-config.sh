#!/bin/sh
set -e

echo "=== 🔧 自动修复 config（24.10 + sl‑3000‑emmc） ==="

CONF=".config"

fix() {
    key="$1"
    val="$2"

    # 删除旧的重复项
    sed -i "/^$key=/d" "$CONF"

    # 写入新的
    echo "$key=$val" >> "$CONF"
    echo "补齐: $key"
}

# -----------------------------
# 目标平台
# -----------------------------
fix CONFIG_TARGET_mediatek y
fix CONFIG_TARGET_mediatek_filogic y

# -----------------------------
# 设备名（24.10 正确写法）
# -----------------------------
fix CONFIG_TARGET_mediatek_filogic_DEVICE_sl-3000-emmc y
fix CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_sl-3000-emmc y

# -----------------------------
# 内核版本（24.10 = 6.6）
# -----------------------------
fix CONFIG_LINUX_6_6 y

# -----------------------------
# 必要 rootfs / 分区 / 文件系统
# -----------------------------
fix CONFIG_TARGET_ROOTFS_INITRAMFS y
fix CONFIG_TARGET_ROOTFS_SQUASHFS y
fix CONFIG_TARGET_ROOTFS_EXT4FS y
fix CONFIG_TARGET_ROOTFS_PARTSIZE 160

# -----------------------------
# USB / F2FS / 自动挂载
# -----------------------------
fix CONFIG_PACKAGE_kmod-usb3 y
fix CONFIG_PACKAGE_f2fsck y
fix CONFIG_PACKAGE_mkf2fs y
fix CONFIG_PACKAGE_automount y

# -----------------------------
# WiFi 固件（7981）
# -----------------------------
fix CONFIG_PACKAGE_kmod-mt7981-firmware y
fix CONFIG_PACKAGE_mt7981-wo-firmware y

# -----------------------------
# 清理重复空行并排序（保持整洁）
# -----------------------------
sort -u "$CONF" -o "$CONF"

echo "✔ config 自动修复完成（已补齐 sl‑3000‑emmc 全部关键项）"
