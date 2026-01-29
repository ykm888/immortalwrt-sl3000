#!/bin/bash
# 全量清理所有依赖不存在的包，确保构建日志 0 警告

# -------------------------------
# Python3 相关（所有依赖 python3-* 的包）
# -------------------------------
rm -rf package/feeds/packages/python3*
rm -rf package/feeds/packages/borgbackup
rm -rf package/feeds/packages/byobu
rm -rf package/feeds/packages/bcm27xx-eeprom
rm -rf package/feeds/packages/boost
rm -rf package/feeds/packages/apparmor
rm -rf package/feeds/packages/alpine

# -------------------------------
# libcrypt-compat 依赖
# -------------------------------
rm -rf package/feeds/packages/libxcrypt
rm -rf package/feeds/packages/libcrypt-compat
rm -rf package/feeds/packages/ccrypt
rm -rf package/feeds/packages/cyrus-sasl
rm -rf package/feeds/packages/apr

# -------------------------------
# sudo / samba4 / 其他系统工具
# -------------------------------
rm -rf package/feeds/packages/sudo
rm -rf package/feeds/packages/samba4
rm -rf package/feeds/packages/backuppc

# -------------------------------
# IDS/IPS / 安全审计工具
# -------------------------------
rm -rf package/feeds/packages/snort3
rm -rf package/feeds/packages/suricata
rm -rf package/feeds/packages/selinux-python
rm -rf package/feeds/packages/setools

# -------------------------------
# bmx7 系列（依赖 bmx7-json）
# -------------------------------
rm -rf package/feeds/packages/bmx7*
rm -rf package/feeds/packages/bmx7-dnsupdate

# -------------------------------
# vectorscan 依赖
# -------------------------------
rm -rf package/feeds/packages/vectorscan

# -------------------------------
# 你之前已经清理的（保留）
# -------------------------------
rm -rf package/feeds/packages/rtty \
       package/feeds/packages/screen \
       package/feeds/packages/shadow \
       package/feeds/packages/squid \
       package/feeds/packages/stress-ng \
       package/feeds/packages/tac_plus \
       package/feeds/packages/tcsh \
       package/feeds/packages/xinetd \
       package/feeds/packages/ufp \
       package/feeds/packages/tdb \
       package/feeds/packages/text-unidecode \
       package/feeds/packages/tunneldigger-broker \
       package/feeds/packages/unbound \
       package/feeds/packages/uwsgi \
       package/feeds/packages/vobject \
       package/feeds/packages/yt-dlp \
       package/feeds/packages/xupnpd

# -------------------------------
# small feed - 坏包
# -------------------------------
rm -rf package/feeds/small/luci-app-fchomo \
       package/feeds/small/fchomo \
       package/feeds/small/nikki \
       package/feeds/small/luci-app-homeproxy \
       package/feeds/small/homeproxy \
       package/feeds/small/sing-box \
       package/feeds/small/sing-box-tiny \
       package/feeds/small/luci-app-momo \
       package/feeds/small/momo \
       package/feeds/small/trojan-plus

# -------------------------------
# small feed - 不需要的代理插件
# -------------------------------
rm -rf package/feeds/small/luci-app-vssr* \
       package/feeds/small/luci-app-openclash* \
       package/feeds/small/luci-app-clash* \
       package/feeds/small/luci-app-clashr* \
       package/feeds/small/luci-app-bypass* \
       package/feeds/small/luci-app-advanced* \
       package/feeds/small/luci-app-ikoolproxy* \
       package/feeds/small/luci-app-adguardhome*

# -------------------------------
# small feed - 不需要的代理内核
# -------------------------------
rm -rf package/feeds/small/naiveproxy \
       package/feeds/small/brook \
       package/feeds/small/kcptun \
       package/feeds/small/redsocks2 \
       package/feeds/small/ipt2socks \
       package/feeds/small/microsocks \
       package/feeds/small/trojan \
       package/feeds/small/trojan-go \
       package/feeds/small/v2ray-core

echo "Feeds cleanup completed."
