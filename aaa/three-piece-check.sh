#!/bin/sh
set -e

echo "=== 🔍 三件套增强检测开始 ==="

# 文件存在性
[ -f target/linux/mediatek/dts/mt7981b-sl3000-emmc.dts ] || { echo "❌ DTS 缺失"; exit 1; }
[ -f target/linux/mediatek/image/filogic.mk ] || { echo "❌ mk 缺失"; exit 1; }
[ -f .config ] || { echo "❌ config 缺失"; exit 1; }
echo "✔ 文件存在性检查通过"

# 设备一致性
grep -q "sl3000-emmc" target/linux/mediatek/dts/mt7981b-sl3000-emmc.dts
grep -q "sl3000-emmc" target/linux/mediatek/image/filogic.mk
grep -q "sl3000-emmc" .config
echo "✔ DTS/mk/config 设备一致性检查通过"

# 隐藏字符检查
if grep -P "[\x00-\x1F]" .config >/dev/null; then
    echo "❌ config 存在隐藏字符"
    exit 1
fi
echo "✔ 隐藏字符检查通过"

echo "=== ✅ 三件套增强检测全部通过 ==="
