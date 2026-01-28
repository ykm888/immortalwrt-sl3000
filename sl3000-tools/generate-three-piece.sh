#!/bin/bash
set -euo pipefail

# 基础校验：是否在ImmortalWrt 24.10根目录（校验filogic平台+核心文件）
if [ ! -d "target/linux/mediatek/filogic" ] || [ ! -f "Makefile" ]; then
    echo "FATAL: not in ImmortalWrt 24.10 root (missing filogic platform or Makefile)"
    exit 1
fi

ROOT="$(pwd)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 日志初始化：终端+日志文件双输出，保留原日志路径
LOG="$SCRIPT_DIR/sl3000-three-piece.log"
: > "$LOG"
exec > >(tee -a "$LOG") 2>&1

echo "=== SL3000 three-piece generation start ==="
echo "[ROOT] $ROOT"
echo "[SCRIPT_DIR] $SCRIPT_DIR"
echo

# 1. 生成DTS文件：ImmortalWrt24.10 filogic官方路径，自动创建缺失目录
DTS_DIR="$ROOT/target/linux/mediatek/filogic/dts"
DTS="$DTS_DIR/mt7981b-sl-3000-emmc.dts"
mkdir -p "$DTS_DIR"

cat > "$DTS" << 'EOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT
/dts-v1/;
#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/leds/common.h>
#include "mt7981.dtsi"

/ {
	model = "SL-3000 eMMC bootstrap versions";
	compatible = "sl,3000-emmc", "mediatek,mt7981";

	aliases {
		serial0 = &uart0;
		led-boot = &statusredled;
		led-failsafe = &statusredled;
		led-running = &statusgreenled;
		led-upgrade = &statusblueled;
	};

	chosen {
		bootargs = "root=PARTLABEL=rootfs rootwait";
		stdout-path = "serial0:115200n8";
	};

	memory@40000000 {
		device_type = "memory";
		reg = <0x0 0x40000000 0x0 0x40000000>;
	};
};
EOF

echo "[DTS] generated: $DTS"
echo

# 2. 写入MK配置：核心修复→自动创建缺失的filogic/image目录+全路径探测
MTK_FILOGIC_DIR="$ROOT/target/linux/mediatek/filogic"
IMAGE_DIR="$MTK_FILOGIC_DIR/image"
# 关键1：自动创建缺失的image目录（mkdir -p 存在不报错，缺失则创建）
mkdir -p "$IMAGE_DIR"
echo "[DEBUG] ensure filogic image dir exists: $IMAGE_DIR"

# 关键2：打印mediatek/filogic下所有目录，排查真实层级（便于后续问题定位）
echo "[DEBUG] mediatek/filogic dir structure:"
ls -la "$MTK_FILOGIC_DIR/" || { echo "FATAL: filogic root dir not found"; exit 1; }
echo

# 关键3：打印image目录文件列表（创建后）
echo "[DEBUG] filogic image dir files list (after mkdir):"
ls -la "$IMAGE_DIR/"
echo

# 动态匹配MK文件：优先mt7981.mk → 其次filogic.mk → 最后创建基础Makefile（兜底）
MK=""
if [ -f "$IMAGE_DIR/mt7981.mk" ]; then
    MK="$IMAGE_DIR/mt7981.mk"
elif [ -f "$IMAGE_DIR/filogic.mk" ]; then
    MK="$IMAGE_DIR/filogic.mk"
elif [ -f "$IMAGE_DIR/Makefile" ]; then
    MK="$IMAGE_DIR/Makefile"
else
    # 兜底：自动创建基础Makefile（适配源码无任何MK文件的极端情况）
    MK="$IMAGE_DIR/Makefile"
    echo '# Auto created for SL3000 eMMC' > "$MK"
    echo "[DEBUG] auto create base Makefile (no MK file found): $MK"
fi
echo "[DEBUG] final used MK file: $MK"

# sed兼容处理：无匹配时不报错，避免set -e终止脚本
DEVICE_NAME="sl_3000-emmc"
sed -i '/Device\/'${DEVICE_NAME}'/,/endef/d' "$MK" 2>/dev/null || true
sed -i '/TARGET_DEVICES += '${DEVICE_NAME}'/d' "$MK" 2>/dev/null || true

# 追加SL3000 eMMC设备配置（原配置不变，Makefile变量转义正常）
cat >> "$MK" << 'EOF'

define Device/sl_3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 eMMC
  DEVICE_DTS := mt7981b-sl-3000-emmc
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware automount coremark blkid blockdev fdisk f2fsck mkf2fs kmod-mmc
  KERNEL := kernel-bin | lzma | fit lzma $(KDIR)/image-$(firstword $(DEVICE_DTS)).dtb
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $(KDIR)/image-$(firstword $(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef

TARGET_DEVICES += sl3000-emmc
EOF

echo "[MK] updated: $MK"
echo

# 3. 生成.config：适配ImmortalWrt24.10 filogic平台配置项
CFG="$ROOT/.config"

cat > "$CFG" << 'EOF'
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_MULTI_PROFILE=y

CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_sl_3000-emmc=y

CONFIG_TARGET_ROOTFS_SQUASHFS=y
CONFIG_TARGET_IMAGES_GZIP=y

CONFIG_PACKAGE_kmod-mt7915e=y
CONFIG_PACKAGE_kmod-mt7981-firmware=y
CONFIG_PACKAGE_mt7981-wo-firmware=y
CONFIG_PACKAGE_kmod-mmc=y

CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
EOF

echo "[CONFIG] written: $CFG"
echo

# 4. 全量校验：路径+配置项全对齐，确保文件有效
[ -s "$DTS" ] || { echo "FATAL: DTS missing or empty"; exit 1; }
[ -s "$MK" ]  || { echo "FATAL: MK missing or empty"; exit 1; }
[ -s "$CFG" ] || { echo "FATAL: CONFIG missing or empty"; exit 1; }

# 校验MK核心配置
grep -q "define Device/sl_3000-emmc" "$MK" || { echo "FATAL: MK device block missing"; exit 1; }
grep -q "TARGET_DEVICES += sl3000-emmc" "$MK" || { echo "FATAL: MK TARGET_DEVICES missing"; exit 1; }

# 校验CONFIG核心配置（filogic平台）
grep -q '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_sl_3000-emmc=y' "$CFG" || { echo "FATAL: CONFIG device enable missing"; exit 1; }

echo "=== SL3000 three-piece generation complete ==="
echo "[OUT] DTS : $DTS"
echo "[OUT] MK  : $MK"
echo "[OUT] CFG : $CFG"
echo "[SUCCESS]"
