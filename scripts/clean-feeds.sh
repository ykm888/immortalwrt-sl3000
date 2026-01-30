#!/bin/bash
set -e

FEEDS_ROOT="/mnt/openwrt/package/feeds"

echo "=== 裁剪 feeds：基于 symlink 做白名单过滤 ==="

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

is_in_whitelist() {
    local name="$1"
    for w in $WHITELIST; do
        [ "$w" = "$name" ] && return 0
    done
    return 1
}

# 只保留白名单里的 luci 包
for dir in "$FEEDS_ROOT/luci"/*; do
    [ -d "$dir" ] || continue
    base="$(basename "$dir")"
    if is_in_whitelist "$base"; then
        echo "KEEP: luci/$base"
    else
        echo "DROP: luci/$base"
        rm -rf "$dir"
    fi
done

# 删除 utils 整个目录（你不需要）
rm -rf "$FEEDS_ROOT/packages/utils"

echo "=== feeds 裁剪完成 ==="
