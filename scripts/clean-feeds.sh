#!/bin/bash
set -e

FEEDS_ROOT="package/feeds"

echo "=== 清空 feeds 包 ==="
rm -rf $FEEDS_ROOT/packages/*
rm -rf $FEEDS_ROOT/luci/*
rm -rf $FEEDS_ROOT/small/*
rm -rf $FEEDS_ROOT/helloworld/*

mkdir -p $FEEDS_ROOT/packages
mkdir -p $FEEDS_ROOT/packages/libs
mkdir -p $FEEDS_ROOT/packages/lang
mkdir -p $FEEDS_ROOT/luci
mkdir -p $FEEDS_ROOT/small
mkdir -p $FEEDS_ROOT/helloworld

copy_pkg() {
  local pkg="$1"
  for path in \
    feeds/helloworld/$pkg \
    feeds/small/$pkg \
    feeds/packages/$pkg \
    feeds/packages/libs/$pkg \
    feeds/packages/net/$pkg \
    feeds/packages/utils/$pkg \
    feeds/packages/lang/$pkg
  do
    if [ -d "$path" ]; then
      case "$path" in
        feeds/packages/libs/*)
          cp -r "$path" "$FEEDS_ROOT/packages/libs/"
          ;;
        feeds/packages/lang/*)
          cp -r "$path" "$FEEDS_ROOT/packages/lang/"
          ;;
        feeds/packages/*)
          cp -r "$path" "$FEEDS_ROOT/packages/"
          ;;
        feeds/small/*)
          cp -r "$path" "$FEEDS_ROOT/small/"
          ;;
        feeds/helloworld/*)
          cp -r "$path" "$FEEDS_ROOT/helloworld/"
          ;;
      esac
      return
    fi
  done
}

echo "=== 保留 LuCI 基础 ==="
for p in \
  luci-base luci-compat luci-lua-runtime \
  luci-lib-ip luci-lib-jsonc luci-theme-bootstrap
do
  cp -r feeds/luci/**/$p $FEEDS_ROOT/luci/ 2>/dev/null || true
done

echo "=== 写入白名单 config（无科学上网） ==="
cat > .config << "EOF"
CONFIG_ALL=n
CONFIG_ALL_KMODS=n
CONFIG_ALL_NONSHARED=n

CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_mt7981=y
CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_sl_3000-emmc=y

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
CONFIG_PACKAGE_luci-proto-ppp=y
CONFIG_PACKAGE_luci-proto-ipv6=y

CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
EOF

echo "=== 立即 defconfig（关键） ==="
make defconfig

echo "=== 白名单模式完成（最终版） ==="
