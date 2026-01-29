#!/bin/bash
# 白名单模式：清空所有包，只保留 luci + passwall2 + ssrplus + xray-core

echo "=== 清空主线 package/* ==="
rm -rf package/*

echo "=== 清空 feeds 包 ==="
rm -rf package/feeds/packages/*
rm -rf package/feeds/luci/*
rm -rf package/feeds/small/*
rm -rf package/feeds/helloworld/*

mkdir -p package/feeds/packages
mkdir -p package/feeds/luci
mkdir -p package/feeds/small
mkdir -p package/feeds/helloworld

echo "=== 保留 luci 基础 ==="
cp -r feeds/luci/modules/luci-base package/feeds/luci/
cp -r feeds/luci/modules/luci-compat package/feeds/luci/
cp -r feeds/luci/modules/luci-lua-runtime package/feeds/luci/
cp -r feeds/luci/libs/luci-lib-ip package/feeds/luci/
cp -r feeds/luci/libs/luci-lib-jsonc package/feeds/luci/
cp -r feeds/luci/themes/luci-theme-bootstrap package/feeds/luci/

echo "=== 保留 Passwall2 / SSRPlus / Xray ==="
cp -r feeds/helloworld/luci-app-ssr-plus package/feeds/packages/
cp -r feeds/helloworld/ssr-plus package/feeds/packages/
cp -r feeds/helloworld/xray-core package/feeds/packages/
cp -r feeds/helloworld/v2ray-geodata package/feeds/packages/

cp -r feeds/small/luci-app-passwall2 package/feeds/small/
cp -r feeds/small/passwall2 package/feeds/small/
cp -r feeds/small/xray-core package/feeds/small/ 2>/dev/null || true

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
