#!/bin/bash
set -e

FEEDS_ROOT="/mnt/openwrt/package/feeds"

# === 白名单（你要保留的 luci 基础包） ===
WHITELIST="
luci-base
luci-compat
luci-lib-base
luci-lib-ip
luci-lib-jsonc
luci-lib-nixio
luci-mod-admin-full
luci-mod-network
luci-mod-status
luci-mod-system
luci-theme-bootstrap
"

echo "=== 清理 feeds（白名单模式） ==="

# 删除非白名单的一级目录
for dir in $FEEDS_ROOT/*; do
    pkg=$(basename "$dir")

    if echo "$WHITELIST" | grep -q "^$pkg$"; then
        echo "KEEP: $pkg"
        continue
    fi

    echo "DEL:  $pkg"
    rm -rf "$dir"
done

echo "=== 删除死锁链目录（一次性彻底修复） ==="

# download 阶段卡死的根因目录
rm -rf /mnt/openwrt/package/feeds/packages/net
rm -rf /mnt/openwrt/package/feeds/packages/misc
rm -rf /mnt/openwrt/package/feeds/luci/liblucihttp-ucode

echo "=== clean-feeds 完成 ==="
