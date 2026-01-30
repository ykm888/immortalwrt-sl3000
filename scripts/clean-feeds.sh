#!/bin/bash
set -e

FEEDS_ROOT="package/feeds"

echo "=== 清空所有 feeds 包 ==="
rm -rf $FEEDS_ROOT/packages/*
rm -rf $FEEDS_ROOT/luci/*
rm -rf $FEEDS_ROOT/small/*
rm -rf $FEEDS_ROOT/helloworld/*

mkdir -p $FEEDS_ROOT/packages $FEEDS_ROOT/luci

echo "=== 白名单模式：只保留 LuCI 和基础包 ==="

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
"

copy_if_exists() {
    local pkg="$1"
    for src in feeds/luci feeds/packages; do
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

echo "=== 强制删除 utils 整个目录（彻底解决 glib2/libpam/gpiod 死锁） ==="
rm -rf package/feeds/packages/utils

echo "=== 完成：最小化 feeds，无任何死锁包 ==="
