#!/bin/bash
set -e

echo "=== clean-feeds.sh (SL3000 / 24.10 修复版) ==="

FEEDS_ROOT="package/feeds"

echo "[1] 移除 24.10 卡死源头"

rm -rf package/system/refpolicy
rm -rf package/system/selinux-policy
rm -rf package/system/policycoreutils

rm -rf package/utils/pcat-manager
rm -rf package/network/services/lldpd

rm -rf package/libs/libpam
rm -rf package/libs/libtirpc
rm -rf package/libs/libnsl

rm -rf package/utils/kexec-tools
rm -rf package/libs/xz

rm -rf package/lean/default-settings 2>/dev/null || true

echo "[2] 清空 feeds 包（只动 package/feeds）"

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

echo "[3] 保留 LuCI 基础白名单"

for p in \
  luci-base luci-compat luci-lua-runtime \
  luci-lib-ip luci-lib-jsonc luci-theme-bootstrap
do
  cp -r feeds/luci/**/"$p" "$FEEDS_ROOT"/luci/ 2>/dev/null || true
done

echo "=== clean-feeds.sh 完成 ==="
