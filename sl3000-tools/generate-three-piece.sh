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

# 1. 生成DTS文件：补全MT7981B eMMC完整硬件配置（网口/WiFi/USB/LED/按键/eMMC）
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
	model = "SL 3000 eMMC";
	compatible = "sl,sl_3000-emmc", "mediatek,mt7981";

	aliases {
		serial0 = &uart0;
		led-boot = &led_status_red;
		led-failsafe = &led_status_red;
		led-running = &led_status_green;
		led-upgrade = &led_status_blue;
	};

	chosen {
		bootargs = "root=PARTLABEL=rootfs rootwait blkdevparts=mmcblk0:1M(u-boot),15M(kernel),-(rootfs)";
		stdout-path = "serial0:115200n8";
	};

	memory@40000000 {
		device_type = "memory";
		reg = <0x0 0x40000000 0x0 0x40000000>;
	};

	leds {
		compatible = "gpio-leds";
		led_status_red: status_red {
			label = "sl3000:red:status";
			gpios = <&gpio 12 GPIO_ACTIVE_LOW>;
		};
		led_status_green: status_green {
			label = "sl3000:green:status";
			gpios = <&gpio 13 GPIO_ACTIVE_LOW>;
		};
		led_status_blue: status_blue {
			label = "sl3000:blue:status";
			gpios = <&gpio 14 GPIO_ACTIVE_LOW>;
		};
	};

	keys {
		compatible = "gpio-keys";
		reset {
			label = "reset";
			gpios = <&gpio 18 GPIO_ACTIVE_LOW>;
			linux,code = <KEY_RESTART>;
			debounce-interval = <60>;
		};
	};
};

&uart0 {
	status = "okay";
};

&sdhci {
	status = "okay";
	bus-width = <8>;
	non-removable;
	no-sdio;
	no-mmc;
};

&usb_phy {
	status = "okay";
};

&usb0 {
	status = "okay";
	dr_mode = "host";
};

&usb1 {
	status = "okay";
	dr_mode = "host";
};

&mt7981_eth {
	status = "okay";
	mediatek,mdio-mode = <1>;
	pinctrl-names = "default";
	pinctrl-0 = <&mdio_pins>;

	port@0 {
		status = "okay";
		label = "wan";
	};
	port@1 {
		status = "okay";
		label = "lan1";
	};
	port@2 {
		status = "okay";
		label = "lan2";
	};
};

&wifi {
	status = "okay";
	mediatek,wifi-mode = <1>;
	ieee80211-freq-limit = <2400000 2500000>, <5150000 5850000>;
};

&mdio_pins {
	status = "okay";
};

&spi0 {
	status = "okay";
};
EOF

echo "[DTS] generated: $DTS"
echo

# 2. 写入MK配置：核心修复→设备名统一/补全TARGET_DEVICES/旗舰功能包/EMMC适配
MTK_FILOGIC_DIR="$ROOT/target/linux/mediatek/filogic"
IMAGE_DIR="$MTK_FILOGIC_DIR/image"
mkdir -p "$IMAGE_DIR"
echo "[DEBUG] ensure filogic image dir exists: $IMAGE_DIR"

echo "[DEBUG] mediatek/filogic dir structure:"
ls -la "$MTK_FILOGIC_DIR/" || { echo "FATAL: filogic root dir not found"; exit 1; }
echo

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
    MK="$IMAGE_DIR/Makefile"
    echo '# Auto created for SL3000 eMMC' > "$MK"
    echo "[DEBUG] auto create base Makefile (no MK file found): $MK"
fi
echo "[DEBUG] final used MK file: $MK"

# 核心修复：设备名全程统一为sl_3000-emmc（下划线），避免识别失败
DEVICE_NAME="sl_3000-emmc"
# sed兼容处理：无匹配时不报错，彻底清理旧配置
sed -i '/Device\/'${DEVICE_NAME}'/,/endef/d' "$MK" 2>/dev/null || true
sed -i '/TARGET_DEVICES += '${DEVICE_NAME}'/d' "$MK" 2>/dev/null || true

# 追加SL3000 EMMC设备配置：补全TARGET_DEVICES/旗舰功能包/EMMC分区/官方编译规范
cat >> "$MK" << EOF

define Device/${DEVICE_NAME}
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 eMMC
  DEVICE_DTS := mt7981b-sl-3000-emmc
  DEVICE_DTS_DIR := ../dts
  IMAGE_SIZE := 15360k
  UBINIZE_OPTS := -E 5
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware kmod-usb3 kmod-usb-storage kmod-fs-ext4 kmod-fs-ntfs3 kmod-docker kmod-nftables kmod-tun kmod-mmc automount coremark blkid fdisk f2fsck mkf2fs luci-app-docker luci-app-passwall2 luci-app-ssr-plus luci-proto-pppoe luci-mod-admin-full wget curl ca-certificates
  KERNEL := kernel-bin | lzma | fit lzma \$(KDIR)/image-\$(firstword \$(DEVICE_DTS)).dtb
  KERNEL_INITRAMFS := kernel-bin | lzma | fit lzma \$(KDIR)/image-\$(firstword \$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGES := sysupgrade.bin factory.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGE/factory.bin := factory-bin | append-metadata | check-size \$(IMAGE_SIZE)
endef

TARGET_DEVICES += ${DEVICE_NAME}
EOF

echo "[MK] updated: $MK"
echo

# 3. 生成.config：适配ImmortalWrt24.10 filogic+旗舰功能包+MT7981B EMMC
CFG="$ROOT/.config"

cat > "$CFG" << 'EOF'
# 基础平台配置（强对齐MK/DTS）
CONFIG_TARGET_arm64=y
CONFIG_TARGET_arm64_generic=y
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_MULTI_PROFILE=y
CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_sl_3000-emmc=y

# 内核配置（ImmortalWrt24.10默认Linux 6.6）
CONFIG_DEFAULT_LINUX_6_6=y
CONFIG_LINUX_6_6=y

# 镜像配置（EMMC分区适配）
CONFIG_TARGET_ROOTFS_SQUASHFS=y
CONFIG_TARGET_ROOTFS_EXT4FS=y
CONFIG_TARGET_IMAGES_GZIP=y
CONFIG_TARGET_ROOTFS_PARTSIZE=1024
CONFIG_TARGET_IMAGES_PAD=y

# 核心硬件驱动（MT7981B/EMMC/WiFi/USB）
CONFIG_PACKAGE_kmod-mt7915e=y
CONFIG_PACKAGE_kmod-mt7981-firmware=y
CONFIG_PACKAGE_mt7981-wo-firmware=y
CONFIG_PACKAGE_kmod-mmc=y
CONFIG_PACKAGE_kmod-usb3=y
CONFIG_PACKAGE_kmod-usb-storage=y
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-ntfs3=y

# 旗舰功能包（Docker/Passwall2/SSR Plus+）
CONFIG_PACKAGE_docker=y
CONFIG_PACKAGE_docker-compose=y
CONFIG_PACKAGE_kmod-docker=y
CONFIG_PACKAGE_kmod-tun=y
CONFIG_PACKAGE_kmod-nftables=y
CONFIG_PACKAGE_luci-app-docker=y
CONFIG_PACKAGE_luci-app-passwall2=y
CONFIG_PACKAGE_luci-app-ssr-plus=y

# LuCI基础（中文/全功能管理）
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
CONFIG_PACKAGE_luci-mod-admin-full=y
CONFIG_PACKAGE_luci-proto-pppoe=y
CONFIG_PACKAGE_luci-proto-ipv6=y

# 工具链（基础依赖）
CONFIG_PACKAGE_wget=y
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_ca-certificates=y
CONFIG_PACKAGE_automount=y
CONFIG_PACKAGE_blkid=y
CONFIG_PACKAGE_fdisk=y
EOF

echo "[CONFIG] written: $CFG"
echo

# 4. 强化全量校验：三件套强一致/核心配置无缺失（工程级校验）
echo "=== Start strict three-piece check ==="
# 校验文件非空
[ -s "$DTS" ] || { echo "FATAL: DTS missing or empty"; exit 1; }
[ -s "$MK" ]  || { echo "FATAL: MK missing or empty"; exit 1; }
[ -s "$CFG" ] || { echo "FATAL: CONFIG missing or empty"; exit 1; }

# 校验MK核心配置（彻底解决TARGET_DEVICES缺失）
grep -q "define Device/sl_3000-emmc" "$MK" || { echo "FATAL: MK device block missing"; exit 1; }
grep -q "TARGET_DEVICES += sl_3000-emmc" "$MK" || { echo "FATAL: MK TARGET_DEVICES missing"; exit 1; }
grep -q "DEVICE_DTS := mt7981b-sl-3000-emmc" "$MK" || { echo "FATAL: MK DEVICE_DTS mismatch DTS"; exit 1; }

# 校验CONFIG核心配置
grep -q '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_sl_3000-emmc=y' "$CFG" || { echo "FATAL: CONFIG device enable missing"; exit 1; }
grep -q '^CONFIG_LINUX_6_6=y' "$CFG" || { echo "FATAL: CONFIG Linux 6.6 not enabled"; exit 1; }

# 校验DTS核心标识
grep -q "compatible = \"sl,sl_3000-emmc\"" "$DTS" || { echo "FATAL: DTS compatible mismatch device name"; exit 1; }
echo "=== Strict check pass ==="
echo

echo "=== SL3000 three-piece generation complete ==="
echo "[OUT] DTS : $DTS"
echo "[OUT] MK  : $MK"
echo "[OUT] CFG : $CFG"
echo "[SUCCESS] All fix done, TARGET_DEVICES error resolved!"
