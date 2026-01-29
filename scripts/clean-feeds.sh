#!/bin/bash
# 清理所有不相关/坏包，保持构建空间干净

# -------------------------------
# packages feed - Python3 / 安全工具 / 其他坏包
# -------------------------------
rm -rf package/feeds/packages/python3 \
       package/feeds/packages/rtty \
       package/feeds/packages/samba4 \
       package/feeds/packages/screen \
       package/feeds/packages/shadow \
       package/feeds/packages/squid \
       package/feeds/packages/stress-ng \
       package/feeds/packages/sudo \
       package/feeds/packages/tac_plus \
       package/feeds/packages/tcsh \
       package/feeds/packages/xinetd \
       package/feeds/packages/ufp \
       package/feeds/packages/setools \
       package/feeds/packages/strongswan \
       package/feeds/packages/tdb \
       package/feeds/packages/text-unidecode \
       package/feeds/packages/tunneldigger-broker \
       package/feeds/packages/unbound \
       package/feeds/packages/uwsgi \
       package/feeds/packages/vectorscan \
       package/feeds/packages/vobject \
       package/feeds/packages/yt-dlp \
       package/feeds/packages/xupnpd \
       package/feeds/packages/selinux-python \
       package/feeds/packages/snort3 \
       package/feeds/packages/suricata

# -------------------------------
# small feed - 已知坏包
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
