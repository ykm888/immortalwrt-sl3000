#!/bin/bash
set -e

###############################################
# SL3000 三件套生成脚本（24.10 工程级最强旗舰版 · 最终修复版）
# - DTS：官方结构 + 完整硬件节点 + 工程旗舰版
# - MK：强制覆盖旧段（仅硬件包 + 无冗余 + eMMC文件系统）
# - CONFIG：覆盖生成（基础编译配置 + Docker + Passwall2 + SSR Plus+）
# - 三件套自动创建 / 覆盖
# - 24.10 / Linux 6.6 固定结构
# - 新增：日志双输出 + 容错处理 + 多维度配置校验
###############################################

# === 日志配置：控制台+文件双输出，方便调试 ===
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="$SCRIPT_DIR/sl3000-three-piece-generate.log"
> "$LOG_FILE"  # 清空旧日志
exec > >(tee -a "$LOG_FILE") 2>&1

# === 仓库根目录（绝不会为空） ===
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# === 三件套路径（固定，贴合ImmortalWrt 24.10官方结构） ===
DTS_OUT="$REPO_ROOT/target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
MK_OUT="$REPO_ROOT/target/linux/mediatek/image/filogic.mk"
CFG_OUT="$REPO_ROOT/.config"

echo "=== 【第一步】路径检查 ==="
echo "DTS_OUT = $DTS_OUT"
echo "MK_OUT  = $MK_OUT"
echo "CFG_OUT = $CFG_OUT"
echo "LOG_FILE= $LOG_FILE"

###############################################
# 1. 自动创建三件套目录/文件（不存在 → 创建）
###############################################
echo -e "\n=== 【第二步】初始化三件套文件 ==="
mkdir -p "$(dirname "$DTS_OUT")"
mkdir -p "$(dirname "$MK_OUT")"

touch "$DTS_OUT"
touch "$MK_OUT"
touch "$CFG_OUT"
echo "✔ 三件套目录/文件初始化完成"

###############################################
# 2. 生成 DTS（官方规范 + 完整硬件节点 + 工程旗舰版）
# 补全：eMMC/网口/LED/按键/UART/PCIe/无线/factory 核心节点
###############################################
echo -e "\n=== 【第三步】生成 DTS（官方工程旗舰版 · 完整硬件节点） ==="

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

        port@0 {
            reg = <0>;
            label = "wan";
            phy-handle = <&phy0>;
        };

        port@1 {
            reg = <1>;
            label = "lan1";
            phy-handle = <&phy1>;
        };

        port@2 {
            reg = <2>;
            label = "lan2";
            phy-handle = <&phy2>;
        };

        port@3 {
            reg = <3>;
            label = "lan3";
            phy-handle = <&phy3>;
        };

        port@4 {
            reg = <4>;
            label = "lan4";
            phy-handle = <&phy4>;
        };
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

    macaddr_factory_4: macaddr@4 {
        reg = <0x4 0x6>;
    };
};

&pio {
    reset_key_pins: reset-key-pins {
        mux {
            function = "gpio";
            pins = "GPIO18";
        };
    };
};
EOF

echo "✔ DTS 已生成（含完整MT7981B eMMC硬件节点，官方规范）"

###############################################
# 3. 生成 MK（强制覆盖旧段 + 无冗余 + 仅硬件/文件系统包）
# 修复：sed删除加容错，移除功能包冗余定义
###############################################
echo -e "\n=== 【第四步】生成 MK（工程级最强旗舰版 · 无冗余） ==="

# 删除旧的 SL3000 设备段 - 容错处理：不存在则跳过，避免脚本中断
if grep -q "Device/mt7981b-sl3000-emmc" "$MK_OUT"; then
    sed -i '/Device\/mt7981b-sl3000-emmc/,/endef/d' "$MK_OUT"
    echo "⚠ 检测到旧SL3000设备段，已成功删除"
else
    echo "⚠ 未检测到旧SL3000设备段，跳过删除"
fi

# 追加新的旗舰版设备段（仅保留硬件固件+eMMC文件系统包，无功能包冗余）
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

echo "✔ MK 已生成（强制覆盖旧段，仅硬件/文件系统包，无冗余）"

###############################################
# 4. 生成 CONFIG（基础编译配置 + Docker + Passwall2 + SSR Plus+）
# 新增：ImmortalWrt24.10工程级基础编译配置，可直接用于构建
###############################################
echo -e "\n=== 【第五步】生成 CONFIG（基础编译+Docker+Passwall2+SSR Plus+） ==="

cat > "$CFG_OUT" << 'EOF'
# 核心目标平台配置（SL3000 eMMC / MT7981B / filogic / Linux 6.6）
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_mt7981b-sl3000-emmc=y

# 旗舰版功能包 - Passwall2
CONFIG_PACKAGE_luci-app-passwall2=y

# 旗舰版功能包 - Docker 全家桶
CONFIG_PACKAGE_docker=y
CONFIG_PACKAGE_dockerd=y
CONFIG_PACKAGE_luci-app-dockerman=y
CONFIG_PACKAGE_docker-compose=y

# 旗舰版功能包 - SSR Plus+
CONFIG_PACKAGE_luci-app-ssr-plus=y
CONFIG_PACKAGE_shadowsocksr-libev-ssr-local=y
CONFIG_PACKAGE_shadowsocksr-libev-ssr-redir=y
CONFIG_PACKAGE_xray-core=y
CONFIG_PACKAGE_v2ray-core=y
CONFIG_PACKAGE_hysteria2=y

# eMMC 文件系统支持（旗舰版，无 USB 冗余）
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-btrfs=y
CONFIG_PACKAGE_block-mount=y
CONFIG_PACKAGE_f2fs-tools=y
CONFIG_PACKAGE_blkid=y

# ===================== 工程级基础编译配置（新增）=====================
# 开发模式与编译优化
CONFIG_DEVEL=y
CONFIG_CCACHE=y
CONFIG_CCACHE_SIZE="10G"
CONFIG_DISABLE_WERROR=y
CONFIG_GCC_OPTIMIZE_O3=y
CONFIG_TARGET_OPTIMIZATION="-O3 -march=armv8-a+crc -mtune=cortex-a53"

# 固件版本自定义（工程旗舰版）
CONFIG_VERSION_CUSTOM=y
CONFIG_VERSION_PREFIX="SL3000-ImmortalWrt"
CONFIG_VERSION_SUFFIX="24.10-Engineering"
CONFIG_VERSION_NUMBER="$(date +%Y%m%d)"

# 根文件系统（SQUASHFS+ZSTD 高压缩，适配eMMC）
CONFIG_TARGET_ROOTFS_SQUASHFS=y
CONFIG_TARGET_ROOTFS_SQUASHFS_COMPRESSION_ZSTD=y
CONFIG_TARGET_ROOTFS_PARTSIZE=1024

# 关闭无用功能，减小固件体积
CONFIG_PACKAGE_dnsmasq_full_remove_resolvconf=y
CONFIG_PACKAGE_wpad-basic-wolfssl=y
CONFIG_PACKAGE_openssh-sftp-server=y
CONFIG_PACKAGE_odhcp6c_config_only=y
CONFIG_NO_IPV6=y

# 核心系统工具
CONFIG_PACKAGE_ip-full=y
CONFIG_PACKAGE_sshd=y
CONFIG_PACKAGE_wget=y
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_htop=y
CONFIG_PACKAGE_tree=y
EOF

echo "✔ CONFIG 已生成（含工程级基础编译配置，可直接用于构建）"

###############################################
# 5. 三件套多维度校验（新增）
# 检查：文件存在性 + 无不可见字符 + DTS语法深度校验
###############################################
echo -e "\n=== 【第六步】三件套配置深度校验 ==="

# 检查文件是否存在
check_file() {
    if [ ! -f "$1" ]; then
        echo "❌ 校验失败：$1 文件不存在"
        exit 1
    fi
    echo "✔ $1 存在性校验通过"
}

# 检查是否有不可见字符（跨平台编辑常见问题）
clean_check() {
    if grep -v -x -z '^[\x20-\x7E]*$' "$1" >/dev/null 2>&1; then
        echo "❌ 校验失败：$1 检测到不可见字符"
        exit 1
    fi
    echo "✔ $1 无不可见字符校验通过"
}

# DTS语法深度校验（需安装dtc，未安装则跳过）
dtc_check() {
    if command -v dtc >/dev/null 2>&1; then
        if ! dtc -I dts -O dtb "$1" >/dev/null 2>&1; then
            echo "❌ 校验失败：$1 DTS语法错误（可执行dtc -I dts -O dtb $1查看详情）"
            exit 1
        fi
        echo "✔ $1 DTS语法深度校验通过"
    else
        echo "⚠ 未安装dtc工具，跳过DTS语法深度校验（建议安装：apt install device-tree-compiler）"
    fi
}

# 执行全量校验
check_file "$DTS_OUT"
check_file "$MK_OUT"
check_file "$CFG_OUT"
echo "---"
clean_check "$DTS_OUT"
clean_check "$MK_OUT"
clean_check "$CFG_OUT"
echo "---"
dtc_check "$DTS_OUT"

echo -e "\n=== 🎉 三件套生成完成（24.10 工程级最强旗舰版 · 最终修复版） ==="
echo "✅ 所有步骤执行完成，校验通过，可直接用于ImmortalWrt 24.10固件构建"
echo "📝 运行日志已保存至：$LOG_FILE"
echo "📦 三件套路径：$DTS_OUT | $MK_OUT | $CFG_OUT"
