#!/bin/bash
set -e

echo "=== clean-feeds.sh (SL3000 / 24.10 最终自由发挥版) ==="

echo "[1] 删除 24.10 所有卡死源头（主树 package/）"

# SELinux / policy
rm -rf package/system/refpolicy
rm -rf package/system/selinux-policy
rm -rf package/system/policycoreutils

# 缺失依赖链（libpam / libtirpc / libnsl / xz）
rm -rf package/libs/libpam
rm -rf package/libs/libtirpc
rm -rf package/libs/libnsl
rm -rf package/libs/xz

# 依赖这些库的包（busybox 会警告但不再卡死）
rm -rf package/utils/pcat-manager
rm -rf package/network/services/lldpd
rm -rf package/boot/kexec-tools

# 默认设置（依赖 luci-i18n-base-zh-cn）
rm -rf package/emortal/default-settings

echo "[2] 清空 feeds 包（只动 package/feeds）"

FEEDS_ROOT="package/feeds"

rm -rf "$FEEDS_ROOT"/packages/*
rm -rf "$FEEDS_ROOT"/luci/*
rm -rf "$FEEDS_ROOT"/small/*
rm -rf "$FEEDS_ROOT"/helloworld/*

mkdir -p "$FEEDS_ROOT"/packages
mkdir -p "$FEEDS_ROOT"/packages/libs
mkdir -p "$FEEDS_ROOT"/packages/lang
mkdir -p "$FEEDS_ROOT"/luci
mkdir -p "$FEEDS_ROOT"/small
mkdir -p "$FEEDS_ROOT"/helloworld

echo "[3] 保留 LuCI 白名单"

for p in \
  luci-base luci-compat luci-lua-runtime \
  luci-lib-ip luci-lib-jsonc luci-theme-bootstrap
do
  cp -r feeds/luci/**/"$p" "$FEEDS_ROOT"/luci/ 2>/dev/null || true
done

echo "[4] 打印剩余可能卡死的包（调试用）"
find package -maxdepth 3 -type d -name "policycoreutils" -o -name "libpam" -o -name "libtirpc" -o -name "libnsl" -o -name "kexec-tools"

echo "=== clean-feeds.sh 完成（24.10 卡死链已彻底清除）==="
