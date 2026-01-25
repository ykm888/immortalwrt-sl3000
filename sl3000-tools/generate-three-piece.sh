#!/bin/bash
set -euo pipefail

###############################################
# 绝对定位仓库根目录（你的仓库根就是 OpenWrt 根）
###############################################
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SCRIPT_DIR="$ROOT/sl3000-tools"
LOG="$SCRIPT_DIR/sl3000-three-piece.log"
: > "$LOG"
exec > >(tee -a "$LOG") 2>&1

echo "[INFO] ROOT = $ROOT"

###############################################
# 锁死 24.10 + kernel 6.6 路径（你的仓库结构）
###############################################
DTS_DIR="$ROOT/target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
DTS="$DTS_DIR/mt7981b-sl3000-emmc.dts"
MK="$ROOT/target/linux/mediatek/image/filogic.mk"
CFG="$ROOT/.config"

echo "[INFO] DTS_DIR = $DTS_DIR"
echo "[INFO] DTS     = $DTS"
echo "[INFO] MK      = $MK"
echo "[INFO] CFG     = $CFG"

mkdir -p "$DTS_DIR"

###############################################
# 清理 CRLF / 隐藏字符
###############################################
clean_crlf() {
    [ ! -f "$1" ] && return 0
    sed -i 's/\r$//' "$1"
}

###############################################
# Stage 1：删除旧 SL3000 段（宽松匹配）
###############################################
echo "=== Stage 1: Clean old MK entries ==="

# 删除旧 define/endef（宽松匹配）
sed -i '/define Device\/mt7981b-sl3000-emmc/,/endef/d' "$MK"

# 删除所有旧的 TARGET_DEVICES 行（宽松匹配）
sed -i '/TARGET_DEVICES[[:space:]]\+.*mt7981b-sl3000-emmc/d' "$MK"

clean_crlf "$MK"

###############################################
# Stage 2：生成 DTS（强制覆盖）
###############################################
echo "=== Stage 2: Generate DTS ==="

cat > "$DTS" << 'EOF'
// SPDX-License-Identifier: GPL-2.0-only OR MIT
/dts-v1/;

#include "mt7981.dtsi"
#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/leds/common.h>

/ {
    model = "SL3000 eMMC Engineering Flagship";
    compatible = "sl,sl3000-emmc", "mediatek,mt7981b";

    aliases {
        serial0 = &uart0;
        led-boot = &led_status;
        led-failsafe = &led_status;
        led-running = &led_status;
        led-upgrade = &led_status;
    };

    chosen { stdout-path = "serial0:115200n8"; };

    leds {
        compatible = "gpio-leds";
        status: led-0 {
            label = "sl:blue:status";
            gpios = <&pio 12 GPIO_ACTIVE_LOW>;
            linux,default-trigger = "heartbeat";
            default-state = "on";
        };
    };

    keys {
        compatible = "gpio-keys";
        reset {
            label = "reset";
            gpios = <&pio 18 GPIO_ACTIVE_LOW>;
            linux,code = <KEY_RESTART>;
            debounce-interval = <60>;
        };
    };
};

&uart0 { status = "okay"; };

&mmc {
    status = "okay";
    bus-width = <8>;
    mmc-hs200-1_8v;
    non-removable;
    cap-mmc-hw-reset;
};

&gmac0 {
    status = "okay";
    phy-mode = "2500base-x";
    phy-handle = <&phy0>;
};

&switch { status = "okay"; };

&pcie { status = "okay"; };
EOF

clean_crlf "$DTS"
echo "[OK] DTS generated → $DTS"

###############################################
# Stage 3：插入 MK 设备段（基于最后一个 TARGET_DEVICES）
###############################################
echo "=== Stage 3: Patch MK ==="

TMP_MK="$MK.tmp"

awk '
    /^TARGET_DEVICES \+=/ { last = NR }
    { lines[NR] = $0 }
    END {
        for (i = 1; i <= NR; i++) {
            print lines[i]
            if (i == last) {
                print ""
                print "define Device/mt7981b-sl3000-emmc"
                print "\tDEVICE_VENDOR := SL"
                print "\tDEVICE_MODEL := SL3000 eMMC Engineering Flagship"
                print "\tDEVICE_DTS := mt7981b-sl3000-emmc"
                print "\tDEVICE_PACKAGES := kmod-mt7981-firmware kmod-fs-ext4 block-mount"
                print "\tIMAGE/sysupgrade.bin := append-kernel | append-rootfs | pad-rootfs | append-metadata"
                print "endef"
                print "TARGET_DEVICES += mt7981b-sl3000-emmc"
                print ""
            }
        }
    }
' "$MK" > "$TMP_MK"

mv "$TMP_MK" "$MK"
clean_crlf "$MK"
echo "[OK] MK patched → $MK"

###############################################
# Stage 4：生成 CONFIG（强制覆盖）
###############################################
echo "=== Stage 4: Generate CONFIG ==="

cat > "$CFG" << 'EOF'
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_mt7981b-sl3000-emmc=y

CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y

CONFIG_PACKAGE_luci-app-passwall2=y
CONFIG_PACKAGE_luci-app-ssr-plus=y
CONFIG_PACKAGE_xray-core=y
CONFIG_PACKAGE_v2ray-core=y
CONFIG_PACKAGE_hysteria2=y
CONFIG_PACKAGE_ipset=y
CONFIG_PACKAGE_iptables-mod-tproxy=y
CONFIG_PACKAGE_iptables-mod-nat-extra=y
CONFIG_PACKAGE_ip6tables-mod-nat=y
CONFIG_PACKAGE_iproute2=y

CONFIG_PACKAGE_docker=y
CONFIG_PACKAGE_dockerd=y
CONFIG_PACKAGE_luci-app-dockerman=y
CONFIG_PACKAGE_docker-compose=y
CONFIG_PACKAGE_containerd=y
CONFIG_PACKAGE_runc=y

CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-btrfs=y
CONFIG_PACKAGE_block-mount=y
CONFIG_PACKAGE_f2fs-tools=y
CONFIG_PACKAGE_blkid=y
CONFIG_PACKAGE_losetup=y
CONFIG_PACKAGE_parted=y
CONFIG_PACKAGE_fdisk=y

CONFIG_DEVEL=y
CONFIG_CCACHE=y
CONFIG_CCACHE_SIZE="10G"
CONFIG_DISABLE_WERROR=y
CONFIG_USE_MKLIBS=y
CONFIG_STRIP_UPX=y

CONFIG_VERSION_CUSTOM=y
CONFIG_VERSION_PREFIX="SL3000-ImmortalWrt"
CONFIG_VERSION_SUFFIX="24.10-Engineering"
CONFIG_VERSION_NUMBER="20251201"

CONFIG_TARGET_ROOTFS_SQUASHFS=y
CONFIG_TARGET_ROOTFS_SQUASHFS_COMPRESSION_ZSTD=y
CONFIG_TARGET_ROOTFS_SQUASHFS_BLOCK_SIZE=256k
CONFIG_TARGET_ROOTFS_PARTSIZE=1024

CONFIG_PACKAGE_ip-full=y
CONFIG_PACKAGE_sshd=y
CONFIG_PACKAGE_wget=y
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_htop=y
CONFIG_PACKAGE_dnsmasq_full_remove_resolvconf=y
CONFIG_PACKAGE_wpad-basic-wolfssl=y
CONFIG_PACKAGE_openssh-sftp-server=y
CONFIG_PACKAGE_coreutils=y

CONFIG_SL3000_CUSTOM_CONFIG=y
EOF

clean_crlf "$CFG"
echo "[OK] CONFIG generated → $CFG"

###############################################
# Stage 5：最终校验
###############################################
echo "=== Stage 5: Validation ==="

[ -s "$DTS" ] || { echo "[FATAL] DTS missing or empty"; exit 1; }
[ -s "$CFG" ] || { echo "[FATAL] CONFIG missing or empty"; exit 1; }
grep -q "mt7981b-sl3000-emmc" "$MK" || { echo "[FATAL] MK missing device block"; exit 1; }

echo "=== Three-piece generation complete ==="
echo "[OUT] DTS: $DTS"
echo "[OUT] MK : $MK"
echo "[OUT] CFG: $CFG"
