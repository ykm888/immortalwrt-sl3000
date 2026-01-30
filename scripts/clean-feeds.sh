#!/bin/bash
set -e

echo "=== 白名单模式：清空所有 feeds 包 ==="

FEEDS_ROOT="package/feeds"

rm -rf $FEEDS_ROOT/packages/*
rm -rf $FEEDS_ROOT/luci/*
rm -rf $FEEDS_ROOT/small/*
rm -rf $FEEDS_ROOT/helloworld/*

mkdir -p $FEEDS_ROOT/packages
mkdir -p $FEEDS_ROOT/luci
mkdir -p $FEEDS_ROOT/small
mkdir -p $FEEDS_ROOT/helloworld

echo "=== 白名单：只保留明确需要的包 ==="

# 白名单列表（你真正需要的包）
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

xray-core
v2ray-geodata

luci-i18n-base-zh-cn
luci-i18n-ssr-plus-zh-cn
luci-i18n-passwall2-zh-cn
"

is_whitelisted() {
    echo "$WHITELIST" | grep -qx "$1"
}

copy_if_exists() {
    local pkg="$1"
    for src in feeds/luci feeds/packages feeds/small feeds/helloworld; do
        if [ -d "$src/$pkg" ]; then
            local target="$FEEDS_ROOT/$(basename "$src")"
            echo "KEEP: $pkg  ←  $src"
            cp -r "$src/$pkg" "$target/"
            return
        fi
    done
    echo "SKIP: $pkg (not found in feeds)"
}

# 遍历白名单并复制
for pkg in $WHITELIST; do
    copy_if_exists "$pkg"
done

echo "=== 白名单模式完成（无依赖补齐，无兜底，无多余包）==="
