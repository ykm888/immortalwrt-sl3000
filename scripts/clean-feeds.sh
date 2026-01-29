#!/bin/bash
# 白名单模式：只保留 luci + passwall2 + ssrplus + xray-core
# 并自动生成最小 .config，彻底避免递归依赖和 WARNING

ROOT="package/feeds"

echo "=== 清空所有 feeds 包 ==="
rm -rf $ROOT/packages/*
rm -rf $ROOT/luci/*
rm -rf $ROOT/small/*

mkdir -p $ROOT/packages
mkdir -p $ROOT/luci
mkdir -p $ROOT/small

echo "=== 保留 luci 基础 ==="
cp -r feeds/luci/modules/luci-base $ROOT/luci/
cp -r feeds/luci/modules/luci-compat $ROOT/luci/
cp -r feeds/luci/modules/luci-lua-runtime $ROOT/luci/
cp -r feeds/luci/libs/luci-lib-ip $ROOT/luci/
cp -r feeds/luci/libs/luci-lib-jsonc $ROOT/luci/
cp -r feeds/luci/themes/luci-theme-bootstrap $ROOT/luci/

echo "=== 保留 Passwall2 / SSRPlus / Xray ==="
cp -r feeds/helloworld/luci-app-ssr-plus $ROOT/packages/
cp -r feeds/helloworld/ssr-plus $ROOT/packages/
cp -r feeds/helloworld/xray-core $ROOT/packages/
cp -r feeds/helloworld/v2ray-geodata $ROOT/packages/

cp -r feeds/small/luci-app-passwall2 $ROOT/small/
cp -r feeds/small/passwall2 $ROOT/small/
cp -r feeds/small/xray-core $ROOT/small/ 2>/dev/null || true

echo "=== 生成白名单 .config ==="
cat > .config << "EOF"
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y

CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-compat=y
CONFIG_PACKAGE_luci-lua-runtime=y
CONFIG_PACKAGE_luci-lib-ip=y
CONFIG_PACKAGE_luci-lib-jsonc=y
CONFIG_PACKAGE_luci-theme-bootstrap=y

CONFIG_PACKAGE_luci-mod-admin-full=y
CONFIG_PACKAGE_luci-mod-network=y
CONFIG_PACKAGE_luci-mod-status=y
CONFIG_PACKAGE_luci-mod-system=y

CONFIG_PACKAGE_luci-app-passwall2=y
CONFIG_PACKAGE_passwall2=y

CONFIG_PACKAGE_luci-app-ssr-plus=y
CONFIG_PACKAGE_ssr-plus=y

CONFIG_PACKAGE_xray-core=y
CONFIG_PACKAGE_v2ray-geodata=y

CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
CONFIG_PACKAGE_luci-i18n-ssr-plus-zh-cn=y
CONFIG_PACKAGE_luci-i18n-passwall2-zh-cn=y
EOF

echo "=== 白名单模式完成 ==="
