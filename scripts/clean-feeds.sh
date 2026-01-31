#!/bin/bash
set -e

# 关键修复：强制进入 OpenWrt 根目录
cd /mnt/openwrt

echo "=== clean-feeds.sh (SL3000 / 24.10 终极修复版) ==="

echo "[1] 删除 24.10 所有卡死源头（主树 package/）"

rm -rf package/system/refpolicy
rm -rf package/system/selinux-policy
rm -rf package/utils/policycoreutils

rm -rf package/libs/libpam
rm -rf package/libs/libtirpc
rm -rf package/libs/libnsl
rm -rf package/libs/xz

rm -rf package/utils/pcat-manager
rm -rf package/network/services/lldpd
rm -rf package/boot/kexec-tools

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

echo "[4] 再次检查是否还有卡死包"
find package -maxdepth 3 -type d \
  -name "policycoreutils" -o \
  -name "libpam" -o \
  -name "libtirpc" -o \
  -name "libnsl" -o \
  -name "kexec-tools"

echo "=== clean-feeds.sh 完成（24.10 卡死链已彻底清除）==="
