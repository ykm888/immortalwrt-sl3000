define Device/mt7981b-sl3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000
  DEVICE_VARIANT := eMMC Flagship
  DEVICE_DTS := mt7981b-sl3000-emmc
  SUPPORTED_DEVICES := mt7981b-sl3000-emmc

  DEVICE_PACKAGES := \
    kmod-mt7981-firmware mt7981-wo-firmware \
    block-mount kmod-fs-f2fs kmod-fs-ext4 kmod-fs-overlay \
    luci-theme-argon luci-app-passwall2 luci-compat kmod-tun \
    xray-core xray-plugin \
    shadowsocks-libev-config shadowsocks-libev-ss-local \
    shadowsocks-libev-ss-redir shadowsocks-libev-ss-server \
    chinadns-ng dns2socks dns2tcp tcping \
    dockerd docker docker-compose luci-app-dockerman \
    kmod-br-netfilter kmod-crypto-hash \
    kmod-veth kmod-macvlan kmod-ipvlan kmod-nf-conntrack kmod-nf-nat

  IMAGES := sysupgrade.bin

  KERNEL := kernel-bin | lzma | \
    fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb

  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef

TARGET_DEVICES += mt7981b-sl3000-emmc
