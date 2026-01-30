#!/bin/bash
set -e

FEEDS_ROOT="package/feeds"

echo "=== 清空所有 feeds 包 ==="
rm -rf $FEEDS_ROOT/packages/*
rm -rf $FEEDS_ROOT/luci/*
rm -rf $FEEDS_ROOT/small/*
rm -rf $FEEDS_ROOT/helloworld/*

mkdir -p $FEEDS_ROOT/packages $FEEDS_ROOT/luci $FEEDS_ROOT/small $FEEDS_ROOT/helloworld

echo "=== 白名单模式：只保留需要的包 ==="

WHITELIST="
luci
luci-base
luci-compat
luci-lua-runtime
luci-lib-ip
luci-lib-jsonc
luci-theme-bootstrap

luci-mod-admin-full
luci-mod-network
luci-mod-status
luci-mod-system
luci-proto-ppp
luci-proto-ipv6

luci-app-passwall2
passwall2

luci-app-ssr-plus
ssr-plus

v2ray-geodata

luci-i18n-base-zh-cn
luci-i18n-ssr-plus-zh-cn
luci-i18n-passwall2-zh-cn
"

copy_if_exists() {
    local pkg="$1"
    for src in feeds/luci feeds/packages feeds/small feeds/helloworld; do
        if [ -d "$src/$pkg" ]; then
            local target="$FEEDS_ROOT/$(basename "$src")"
            echo "KEEP: $pkg ← $src"
            cp -r "$src/$pkg" "$target/"
            return
        fi
    done
    echo "SKIP: $pkg (not found)"
}

for pkg in $WHITELIST; do
    copy_if_exists "$pkg"
done

echo "=== 补齐 SSRPlus/Passwall2/Xray 依赖目录（只复制，不启用） ==="

SSR_DEPS=(
  dns2tcp microsocks tcping shadowsocksr-libev-ssr-check
  curl nping chinadns-ng dns2socks dns2socks-rust dnsproxy mosdns
  hysteria tuic-client shadow-tls ipt2socks kcptun-client naiveproxy
  redsocks2 shadowsocks-libev shadowsocksr-libev simple-obfs
  lua-neturl coreutils coreutils-base64
  shadowsocks-libev-ss-local shadowsocks-libev-ss-redir shadowsocks-libev-ss-server
  shadowsocks-rust-sslocal shadowsocks-rust-ssserver
  shadowsocksr-libev-ssr-local shadowsocksr-libev-ssr-redir shadowsocksr-libev-ssr-server
)

# ❌ 移除 trojan / v2ray-plugin / xray-core，避免 boost/golang/host 依赖
# ✅ 如果你确实需要它们，请手动启用 boost/golang/host 工具链

LIB_DEPS=(libev libsodium libudns glib2 libgpiod libpam libtirpc liblzma libnetsnmp)
HOST_DEPS=(golang rust csstidy luasrcdiet)

for dep in "${SSR_DEPS[@]}" "${LIB_DEPS[@]}"; do
  for path in feeds/helloworld feeds/packages feeds/small; do
    if [ -d "$path/$dep" ]; then
      cp -r "$path/$dep" "$FEEDS_ROOT/$(basename "$path")/"
      echo "DEP: $dep ← $path"
    fi
  done
done

for dep in "${HOST_DEPS[@]}"; do
  if [ -d "feeds/packages/lang/$dep" ]; then
    mkdir -p "$FEEDS_ROOT/packages/lang"
    cp -r "feeds/packages/lang/$dep" "$FEEDS_ROOT/packages/lang/"
    echo "HOST DEP: $dep ← feeds/packages/lang"
  fi
done

echo "=== 白名单 + 依赖补齐完成 ==="
