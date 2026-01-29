#!/bin/bash
# 全量 + 智能清理所有依赖不存在模块的包，确保构建日志 0 警告

FEEDS_DIR="package/feeds/packages"

BAD_DEPS=(
  "python3"
  "python3-"
  "libcrypt-compat"
  "libxcrypt"
  "sudo"
  "samba4"
  "uwsgi"
  "unbound"
  "libunbound"
  "libsasl2"
  "libpam"
  "libcli"
  "libdht"
  "boost"
  "boost-"
  "apr"
  "libapr"
  "libmesa"
  "libwayland"
  "libgraphene"
  "bmx7"
  "bmx7-json"
  "olsrd"
  "olsrd-mod"
  "babeld"
  "kmod-team"
  "kmod-team-mode"
  "kmod-batman-adv"
  "vectorscan"
  "jq/host"
  "unetmsg"
)

echo "=== 自动扫描并删除依赖不存在的包 ==="

for mk in $(find $FEEDS_DIR -name Makefile); do
    for dep in "${BAD_DEPS[@]}"; do
        if grep -q "$dep" "$mk"; then
            pkg_dir=$(dirname "$mk")
            echo "删除包: $pkg_dir  （依赖不存在：$dep）"
            rm -rf "$pkg_dir"
            break
        fi
    done
done

echo "=== 删除 luci feed 中依赖不存在的包 ==="

rm -rf package/feeds/luci/luci-app-bmx7
rm -rf package/feeds/luci/luci-app-olsr*
rm -rf package/feeds/luci/luci-proto-batman-adv
rm -rf package/feeds/luci/luci-app-babeld
rm -rf package/feeds/luci/luci-lib-nixio

echo "=== 删除 small feed 中不需要的代理插件/内核 ==="

rm -rf package/feeds/small/luci-app-*clash*
rm -rf package/feeds/small/luci-app-vssr*
rm -rf package/feeds/small/luci-app-bypass*
rm -rf package/feeds/small/luci-app-ikoolproxy*
rm -rf package/feeds/small/luci-app-adguardhome*
rm -rf package/feeds/small/luci-app-homeproxy*
rm -rf package/feeds/small/homeproxy
rm -rf package/feeds/small/sing-box*
rm -rf package/feeds/small/trojan*
rm -rf package/feeds/small/v2ray-core
rm -rf package/feeds/small/brook
rm -rf package/feeds/small/kcptun
rm -rf package/feeds/small/redsocks2
rm -rf package/feeds/small/ipt2socks
rm -rf package/feeds/small/microsocks

echo "=== 清理完成 ==="
