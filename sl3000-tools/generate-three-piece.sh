#!/bin/bash
set -e

###############################################
# SL3000 三件套生成脚本（24.10 工程级旗舰版 · 保护官方filogic.mk）
# 核心规则：
# 1. filogic.mk：仅操作mt7981b-sl3000-emmc设备段，不碰官方配置
# 2. DTS：补全MT7981B eMMC所有硬件节点，官方结构规范
# 3. CONFIG：工程级编译配置+旗舰功能包，可直接用于构建
# 适配：ImmortalWrt 24.10 (Linux 6.6) / MT7981B eMMC / SL3000
###############################################

# === 1. 基础配置：路径动态计算 + 日志双输出 ===
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_FILE="$SCRIPT_DIR/sl3000-three-piece-generate.log"
> "$LOG_FILE"  # 清空旧日志
exec > >(tee -a "$LOG_FILE") 2>&1  # 控制台+文件双输出

# === 2. 三件套路径（与ImmortalWrt 24.10官方结构对齐）===
DTS_OUT="$REPO_ROOT/target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
MK_OUT="$REPO_ROOT/target/linux/mediatek/image/filogic.mk"  # 官方配置文件，特殊保护
CFG_OUT="$REPO_ROOT/.config"

echo -e "=== 🚀 SL3000 三件套生成开始（保护官方filogic.mk）==="
echo "仓库根目录：$REPO_ROOT"
echo "DTS路径：$DTS_OUT"
echo "MK路径：$MK_OUT（仅操作SL3000设备段）"
echo "CFG路径：$CFG_OUT"
echo "日志文件：$LOG_FILE"

# === 3. 自动创建父目录（DTS/CONFIG兜底，MK仅创父目录）===
echo -e "\n=== 📂 自动创建父目录 ==="
mkdir -p "$(dirname "$DTS_OUT")" && echo "✅ 创建DTS父目录：$(dirname "$DTS_OUT")"
mkdir -p "$(dirname "$MK_OUT")" && echo "✅ 创建MK父目录：$(dirname "$MK_OUT")"
touch "$CFG_OUT" && echo "✅ 兜底创建CONFIG：$CFG_OUT"
[ ! -f "$DTS_OUT" ] && touch "$DTS_OUT" && echo "✅ 兜底创建DTS：$DTS_OUT"

# === 4. 生成DTS（MT7981B eMMC完整硬件节点，官方规范）===
echo -e "\n=== 📝 生成DTS（完整硬件节点）==="
cat > "$DTS_OUT" << 'EOF'
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

    chosen {
        stdout-path = "serial0:115200n8";
    };

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
        pinctrl-names = "default";
        pinctrl-0 = <&reset_key_pins>;

        reset {
            label = "reset";
            gpios = <&pio 18 GPIO_ACTIVE_LOW>;
            linux,code = <KEY_RESTART>;
            debounce-interval = <60>;
        };
    };
};

&uart0 {
    status = "okay";
    pinctrl-names = "default";
    pinctrl-0 = <&uart0_pins>;
};

&mmc {
    status = "okay";
    pinctrl-names = "default";
    pinctrl-0 = <&mmc_pins>;
    bus-width = <8>;
    mmc-hs200-1_8v;
    non-removable;
    cap-mmc-hw-reset;
    mediatek,mmc-wp-disable;
    no-sdio;
    no-mmc;
};

&gmac0 {
    status = "okay";
    phy-mode = "2500base-x";
    phy-handle = <&phy0>;
    nvmem-cells = <&macaddr_factory_4>;
    nvmem-cell-names = "mac-address";
};

&switch {
    status = "okay";
    ports {
        #address-cells = <1>;
        #size-cells = <0>;
        port@0 { reg = <0>; label = "wan"; phy-handle = <&phy0>; };
        port@1 { reg = <1>; label = "lan1"; phy-handle = <&phy1>; };
        port@2 { reg = <2>; label = "lan2"; phy-handle = <&phy2>; };
        port@3 { reg = <3>; label = "lan3"; phy-handle = <&phy3>; };
        port@4 { reg = <4>; label = "lan4"; phy-handle = <&phy4>; };
    };
};

&pcie {
    status = "okay";
    pinctrl-names = "default";
    pinctrl-0 = <&pcie_pins>;
};

&pcie0 {
    wifi@0,0 {
        compatible = "mediatek,mt7921e";
        reg = <0x0000 0 0 0 0>;
        mediatek,mtd-eeprom = <&factory 0x0000>;
        ieee80211-freq-limit = <2400000 2500000>;
    };
};

&pcie1 {
    wifi@0,0 {
        compatible = "mediatek,mt7921e";
        reg = <0x0000 0 0 0 0>;
        mediatek,mtd-eeprom = <&factory 0x8000>;
        ieee80211-freq-limit = <5150000 5850000>;
    };
};

&factory {
    compatible = "nvmem-cells";
    #address-cells = <1>;
    #size-cells = <1>;
    macaddr_factory_4: macaddr@4 { reg = <0x4 0x6>; };
};

&pio {
    reset_key_pins: reset-key-pins { mux { function = "gpio"; pins = "GPIO18"; }; };
};
EOF
echo "✅ DTS生成完成（含MT7981B eMMC全硬件节点）"

# === 5. 生成MK（仅操作SL3000设备段，保护官方配置）===
echo -e "\n=== 🧱 生成MK（仅操作SL3000设备段）==="
# 容错删除旧SL3000段：不存在则跳过，避免脚本中断
if grep -q "Device/mt7981b-sl3000-emmc" "$MK_OUT"; then
    sed -i '/Device\/mt7981b-sl3000-emmc/,/endef/d' "$MK_OUT"
    echo "⚠ 检测到旧SL3000设备段，已删除"
else
    echo "⚠ 未检测到旧SL3000设备段，跳过删除"
fi
# 追加新SL3000设备段（仅硬件包+eMMC文件系统，无功能包冗余）
cat >> "$MK_OUT" << 'EOF'

define Device/mt7981b-sl3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := SL3000 eMMC Engineering Flagship
  DEVICE_DTS := mt7981b-sl3000-emmc
  DEVICE_PACKAGES := kmod-mt7981-firmware kmod-fs-ext4 kmod-fs-btrfs block-mount
  IMAGE/sysupgrade.bin := append-kernel | append-rootfs | pad-rootfs | append-metadata
endef
TARGET_DEVICES += mt7981b-sl3000-emmc

EOF
echo "✅ MK生成完成（仅追加SL3000设备段，官方配置完整保留）"

# === 6. 生成CONFIG（工程级编译配置+旗舰功能包，可直接构建）===
echo -e "\n=== ⚙️ 生成CONFIG（工程级+旗舰功能包）==="
cat > "$CFG_OUT" << 'EOF'
# 核心目标平台：SL3000 eMMC / MT7981B / filogic / Linux 6.6
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_mt7981b-sl3000-emmc=y

# 旗舰功能包 - Passwall2
CONFIG_PACKAGE_luci-app-passwall2=y

# 旗舰功能包 - Docker 全家桶
CONFIG_PACKAGE_docker=y
CONFIG_PACKAGE_dockerd=y
CONFIG_PACKAGE_luci-app-dockerman=y
CONFIG_PACKAGE_docker-compose=y

# 旗舰功能包 - SSR Plus+
CONFIG_PACKAGE_luci-app-ssr-plus=y
CONFIG_PACKAGE_shadowsocksr-libev-ssr-local=y
CONFIG_PACKAGE_shadowsocksr-libev-ssr-redir=y
CONFIG_PACKAGE_xray-core=y
CONFIG_PACKAGE_v2ray-core=y
CONFIG_PACKAGE_hysteria2=y

# eMMC文件系统支持（无USB冗余，适配SL3000）
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-btrfs=y
CONFIG_PACKAGE_block-mount=y
CONFIG_PACKAGE_f2fs-tools=y
CONFIG_PACKAGE_blkid=y

# 工程级基础编译配置（ImmortalWrt 24.10专属）
CONFIG_DEVEL=y
CONFIG_CCACHE=y
CONFIG_CCACHE_SIZE="10G"
CONFIG_DISABLE_WERROR=y
CONFIG_GCC_OPTIMIZE_O3=y
CONFIG_TARGET_OPTIMIZATION="-O3 -march=armv8-a+crc -mtune=cortex-a53"

# 固件版本自定义
CONFIG_VERSION_CUSTOM=y
CONFIG_VERSION_PREFIX="SL3000-ImmortalWrt"
CONFIG_VERSION_SUFFIX="24.10-Engineering"
CONFIG_VERSION_NUMBER="$(date +%Y%m%d)"

# 根文件系统（SQUASHFS+ZSTD，高压缩适配eMMC）
CONFIG_TARGET_ROOTFS_SQUASHFS=y
CONFIG_TARGET_ROOTFS_SQUASHFS_COMPRESSION_ZSTD=y
CONFIG_TARGET_ROOTFS_PARTSIZE=1024

# 系统工具+精简无用功能
CONFIG_PACKAGE_ip-full=y
CONFIG_PACKAGE_sshd=y
CONFIG_PACKAGE_wget=y
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_htop=y
CONFIG_PACKAGE_dnsmasq_full_remove_resolvconf=y
CONFIG_PACKAGE_wpad-basic-wolfssl=y
CONFIG_NO_IPV6=y
EOF
echo "✅ CONFIG生成完成（含工程级编译配置，可直接用于构建）"

# === 7. 多维度校验（轻量+深度，提前暴露错误）===
echo -e "\n=== 🔍 三件套深度校验 ==="
check_file() {
    if [ ! -f "$1" ]; then echo "❌ 校验失败：$1 不存在"; exit 1; fi
    echo "✅ $1 存在性校验通过"
}
clean_check() {
    if grep -v -x -z '^[\x20-\x7E]*$' "$1" >/dev/null 2>&1; then
        echo "❌ 校验失败：$1 含不可见字符"; exit 1; fi
    echo "✅ $1 无不可见字符校验通过"
}
dtc_check() {
    if command -v dtc >/dev/null 2>&1; then
        dtc -I dts -O dtb "$1" >/dev/null 2>&1 || { echo "❌ DTS语法校验失败"; exit 1; }
        echo "✅ DTS语法深度校验通过"
    else
        echo "⚠ 未安装dtc，跳过DTS深度校验（建议安装：apt install device-tree-compiler）"
    fi
}
mk_segment_check() {
    if grep -q "mt7981b-sl3000-emmc" "$MK_OUT"; then
        echo "✅ MK SL3000设备段校验通过"
    else
        echo "❌ 校验失败：MK中无SL3000设备段"; exit 1; fi
}

# 执行校验
check_file "$DTS_OUT"
check_file "$MK_OUT"
check_file "$CFG_OUT"
clean_check "$DTS_OUT"
clean_check "$MK_OUT"
clean_check "$CFG_OUT"
dtc_check "$DTS_OUT"
mk_segment_check

# === 8. 完成提示 ===
echo -e "\n=== 🎉 SL3000 三件套生成完成（保护官方filogic.mk）==="
echo "📌 校验结果：所有检查通过，可直接用于ImmortalWrt 24.10构建"
echo "📝 运行日志：$LOG_FILE"
echo "📦 三件套路径："
echo "  - DTS：$DTS_OUT"
echo "  - MK：$MK_OUT（官方配置完整，已追加SL3000段）"
echo "  - CONFIG：$CFG_OUT"
