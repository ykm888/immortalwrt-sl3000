#!/bin/sh

set -e

echo "==========================================="
echo "  SL-3000 eMMC 三件套生成器（黄金模板版）"
echo "==========================================="

#########################################
# 1. 生成 DTS：mt7981b-sl-3000-emmc.dts
#########################################

DTS="target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts"
mkdir -p target/linux/mediatek/dts

cat > "$DTS" << 'EOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT
/dts-v1/;

include "mt7981.dtsi"

/ {
    model = "SL-3000 eMMC bootstrap version";
    compatible = "sl,3000-emmc", "mediatek,mt7981";

    aliases {
        serial0 = &uart0;
        led-boot = &statusredled;
        led-failsafe = &statusredled;
        led-running = &statusgreenled;
        led-upgrade = &statusblueled;
    };

    chosen {
        stdout-path = "serial0:115200n8";
        bootargs = "console=ttyS0,115200n8 root=PARTLABEL=rootfs rootwait";
    };

    memory {
        reg = <0 0x40000000 0 0x20000000>;
    };

    leds {
        compatible = "gpio-leds";

        statusredled: led-0 {
            label = "red:status";
            gpios = <&pio 10 GPIOACTIVELOW>;
        };

        statusgreenled: led-1 {
            label = "green:status";
            gpios = <&pio 11 GPIOACTIVELOW>;
        };

        statusblueled: led-2 {
            label = "blue:status";
            gpios = <&pio 12 GPIOACTIVELOW>;
        };
    };

    gpio-keys {
        compatible = "gpio-keys";

        reset {
            label = "reset";
            linux,code = <KEY_RESTART>;
            gpios = <&pio 1 GPIOACTIVELOW>;
        };

        mesh {
            label = "mesh";
            linux,code = <BTN_9>;
            linux,input-type = <EV_SW>;
            gpios = <&pio 0 GPIOACTIVELOW>;
        };
    };
};

/ UART /
&uart0 { status = "okay"; };

/ Watchdog /
&watchdog { status = "okay"; };

/ Ethernet + Switch /
&eth {
    status = "okay";

    gmac0: mac@0 {
        compatible = "mediatek,eth-mac";
        reg = <0>;
        phy-mode = "2500base-x";

        fixed-link {
            speed = <2500>;
            full-duplex;
            pause;
        };
    };

    gmac1: mac@1 {
        compatible = "mediatek,eth-mac";
        reg = <1>;
        phy-mode = "2500base-x";

        fixed-link {
            speed = <2500>;
            full-duplex;
            pause;
        };
    };

    mdio: mdio-bus {
        #address-cells = <1>;
        #size-cells = <0>;

        switch@0 {
            compatible = "mediatek,mt7531";
            reg = <31>;
            reset-gpios = <&pio 39 GPIOACTIVELOW>;

            ports {
                #address-cells = <1>;
                #size-cells = <0>;

                port@0 { reg = <0>; label = "lan1"; };
                port@1 { reg = <1>; label = "lan2"; };
                port@2 { reg = <2>; label = "lan3"; };
                port@3 { reg = <3>; label = "wan"; };

                port@6 {
                    reg = <6>;
                    label = "cpu";
                    ethernet = <&gmac0>;
                    phy-mode = "2500base-x";

                    fixed-link {
                        speed = <2500>;
                        full-duplex;
                        pause;
                    };
                };
            };
        };
    };
};

/ eMMC /
&mmc0 {
    bus-width = <8>;
    cap-mmc-highspeed;
    max-frequency = <52000000>;
    no-sd;
    no-sdio;
    non-removable;
    pinctrl-names = "default", "state_uhs";
    pinctrl-0 = <&mmc0pinsdefault>;
    pinctrl-1 = <&mmc0pinsuhs>;
    vmmc-supply = <&reg_3p3v>;
    status = "okay";
};

/ SPI-NOR /
&spi2 {
    status = "okay";

    flash@0 {
        compatible = "jedec,spi-nor";
        reg = <0>;
        spi-max-frequency = <52000000>;

        partitions {
            compatible = "fixed-partitions";
            #address-cells = <1>;
            #size-cells = <1>;

            partition@0 {
                label = "bl2";
                reg = <0x00000000 0x00080000>;
                read-only;
            };

            partition@80000 {
                label = "fip";
                reg = <0x00080000 0x00200000>;
                read-only;
            };

            partition@280000 {
                label = "u-boot-env";
                reg = <0x00280000 0x00080000>;
            };

            partition@300000 {
                label = "factory";
                reg = <0x00300000 0x00100000>;
            };

            partition@400000 {
                label = "firmware";
                reg = <0x00400000 0x01C00000>;
            };
        };
    };
};

/ WiFi /
&wifi {
    status = "okay";
    mediatek,mtd-eeprom = <&factory 0x0>;
};

/ Power /
&reg_3p3v { status = "okay"; };
&reg_1p8v { status = "okay"; };
EOF

echo "✔ DTS 已生成（sl‑3000‑emmc 黄金模板）"


#########################################
# 2. 生成 MK：filogic.mk（官方架构）
#########################################

MK="target/linux/mediatek/image/filogic.mk"
mkdir -p target/linux/mediatek/image

cat > "$MK" << 'EOF'
SPDX-License-Identifier: GPL-2.0-or-later OR MIT

DTSDIR := $(DTSDIR)/mediatek

define Image/Prepare
	rm -f $(KDIR)/ubi_mark
	echo -ne '\xde\xad\xc0\xde' > $(KDIR)/ubi_mark
endef

define Build/mt7981-bl2
	cat $(STAGINGDIRIMAGE)/mt7981-$1-bl2.img >> $@
endef

define Build/mt7981-bl31-uboot
	cat $(STAGINGDIRIMAGE)/mt7981_$1-u-boot.fip >> $@
endef

#####################################################
# ONLY YOUR DEVICE BELOW
#####################################################

define Device/sl-3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000
  DEVICE_VARIANT := eMMC bootstrap
  DEVICE_DTS := mt7981b-sl-3000-emmc
  DEVICEDTSDIR := ../dts
  DEVICE_PACKAGES := kmod-usb3 kmod-mt7981-firmware mt7981-wo-firmware \
	f2fsck mkf2fs automount

  IMAGES := sysupgrade.bin
  KERNEL := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += sl-3000-emmc
EOF

echo "✔ MK 已生成（sl‑3000‑emmc 黄金模板）"


#########################################
# 3. 生成 CONFIG（最小启用）
#########################################

CONF=".config"

cat > "$CONF" << 'EOF'
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_sl-3000-emmc=y
CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_sl-3000-emmc=y
CONFIG_LINUX_6_6=y
EOF

echo "✔ CONFIG 已生成（最小启用 sl‑3000‑emmc）"


#########################################
# 4. 完成
#########################################

echo "==========================================="
echo "  三件套已按黄金模板生成完毕"
echo "==========================================="
