#!/bin/bash
set -e

FEEDS_ROOT="/mnt/openwrt/package/feeds"

echo "=== 白名单（你要保留的 luci 基础包） ==="
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

# 删除非白名单的一级目录（严格延续你上一版）
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

# 你上一版原有的死锁目录清理（完整保留）
rm -rf /mnt/openwrt/package/feeds/packages/net
rm -rf /mnt/openwrt/package/feeds/packages/misc
rm -rf /mnt/openwrt/package/feeds/luci/liblucihttp-ucode

# 新增：24.10 download 卡死补丁（最小修复）
rm -rf /mnt/openwrt/package/feeds/packages/net/misc || true

echo "=== clean-feeds 完成 ==="
