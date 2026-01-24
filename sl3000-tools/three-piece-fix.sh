#!/bin/sh
set -e

echo "=== 🛠 自动修复 SL3000 三件套目录结构（24.10） ==="

mkdir -p target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek
mkdir -p target/linux/mediatek/image

echo "✔ 目录结构已修复"
