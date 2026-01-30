#!/bin/bash
set -e

FEEDS_ROOT="package/feeds"

echo "=== 清空所有 feeds 包 ==="
rm -rf $FEEDS_ROOT/packages/*
rm -rf $FEEDS_ROOT/luci/*
rm -rf $FEEDS_ROOT/small/*
rm -rf $FEEDS_ROOT/helloworld/*

mkdir -p $FEEDS_ROOT/packages $FEEDS_ROOT/luci $FEEDS_ROOT/small $FEEDS_ROOT/helloworld

echo "=== 白名单模式：只保留明确需要的包（无依赖补齐） ==="

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

echo "=== 强制删除 utils 中的死锁包 ==="
rm -rf package/feeds/packages/utils/pcat-manager
rm -rf package/feeds/packages/utils/policycoreutils
rm -rf package/feeds/packages/utils/*glib*
rm -rf package/feeds/packages/utils/*pam*
rm -rf package/feeds/packages/utils/*gpiod*

echo "=== 完成：白名单 + 死锁清理 ==="
