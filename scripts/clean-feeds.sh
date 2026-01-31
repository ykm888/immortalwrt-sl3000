#!/bin/bash
set -e

echo "=== SL3000 24.10 clean-feeds.sh（最终修复版） ==="

FEEDS_ROOT="package/feeds"

echo "=== 1) 移除 24.10 卡死源头（精准修复，不动工程体系） ==="

# 24.10 卡死核心源头
rm -rf package/system/refpolicy
rm -rf package/system/selinux-policy
rm -rf package/system/policycoreutils

# 依赖链卡死源头
rm -rf package/utils/pcat-manager
rm -rf package/network/services/lldpd

# busybox 的 pam/tirpc 依赖链
rm -rf package/libs/libpam
rm -rf package/libs/libtirpc
rm -rf package/libs/libnsl

# kexec-tools 的 lzma 依赖链
rm -rf package/utils/kexec-tools
rm -rf package/libs/xz

# default-settings 的 luci 依赖链（如果存在）
rm -rf package/lean/default-settings 2>/dev/null || true

echo "=== 2) 清空 feeds 包（主树不动，延续你的工程体系） ==="
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

echo "=== 3) 保留 LuCI 基础（白名单体系，延续你的工程结构） ==="
for p in \
  luci-base luci-compat luci-lua-runtime \
  luci-lib-ip luci-lib-jsonc luci-theme-bootstrap
do
  cp -r feeds/luci/**/$p $FEEDS_ROOT/luci/ 2>/dev/null || true
done

echo "=== 4) 写入白名单 config（无科学上网） ==="
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

echo "=== 5) defconfig（关键步骤） ==="
make defconfig

echo "=== clean-feeds.sh 完成（最终版） ==="
