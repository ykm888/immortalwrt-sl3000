#!/bin/sh

DTS="target/linux/mediatek/dts/mt7981b-sl3000-emmc.dts"

cat > "$DTS" << 'EOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT
/dts-v1/;

#include "mt7981.dtsi"

/ {
    model = "SL3000 eMMC Flagship Router";
    compatible = "sl,sl3000-emmc", "mediatek,mt7981";

    aliases {
        serial0 = &uart0;
        ethernet0 = &gmac0;
        led-boot = &led_status;
        led-failsafe = &led_status;
        led-running = &led_status;
        led-upgrade = &led_status;
    };

    chosen {
        stdout-path = "serial0:115200n8";
        bootargs = "console=ttyS0,115200n8";
    };

    memory@40000000 {
        device_type = "memory";
        reg = <0x40000000 0x20000000>; /* 512MB */
    };
};

/* UART */
&uart0 {
    status = "okay";
};

/* Watchdog */
&watchdog {
    status = "okay";
};

/* Ethernet */
&gmac0 {
    status = "okay";
    phy-mode = "rgmii";
};

/* Switch ports */
&switch0 {
    status = "okay";
    ports {
        port@0 { reg = <0>; label = "lan1"; };
        port@1 { reg = <1>; label = "lan2"; };
        port@2 { reg = <2>; label = "lan3"; };
        port@3 { reg = <3>; label = "lan4"; };
        port@4 { reg = <4>; label = "wan"; };
    };
};

/* LED */
&pio {
    led_status: led_status {
        label = "sl3000:green:status";
        gpios = <&pio 12 GPIO_ACTIVE_HIGH>;
        default-state = "off";
    };
};

/* eMMC 分区 */
&mmc0 {
    status = "okay";

    partition@0 {
        label = "u-boot";
        reg = <0x00000000 0x00200000>;
        read-only;
    };

    partition@200000 {
        label = "u-boot-env";
        reg = <0x00200000 0x00100000>;
    };

    partition@300000 {
        label = "factory";
        reg = <0x00300000 0x00100000>;
    };

    partition@400000 {
        label = "firmware";
        reg = <0x00400000 0x1FC00000>;
    };
};
;
EOF

git add "$DTS"
echo "✔ DTS 已生成"
