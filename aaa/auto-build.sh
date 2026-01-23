#!/bin/sh
set -e

echo "=== 🏗 开始构建固件 ==="

cd openwrt
make defconfig
make -j$(nproc) V=s

echo "=== 🎉 固件构建完成 ==="
