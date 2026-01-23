#!/bin/bash
set -e

echo "=== 构建后验证开始 ==="

DTB=$(ls build_dir/target-*/linux-mediatek_filogic/*sl3000-emmc*.dtb 2>/dev/null || true)
if [ -z "$DTB" ]; then
  echo "❌ DTB 未生成"
  exit 1
fi
echo "✔ DTB 已生成: $(basename $DTB)"

MANIFEST=$(ls bin/targets/mediatek/filogic/*.manifest)
if ! grep -q "sl3000-emmc" "$MANIFEST"; then
  echo "❌ manifest 未包含 sl3000-emmc"
  exit 1
fi
echo "✔ manifest 正确"

FW=$(ls bin/targets/mediatek/filogic/*sl3000-emmc* 2>/dev/null || true)
if [ -z "$FW" ]; then
  echo "❌ 固件文件名错误"
  exit 1
fi
echo "✔ 固件文件名正确"

echo ""
echo "=== 固件信息分析 ==="
KERNEL=$(grep -oP 'Linux version \K[^\s]+' build.log | head -1)
SIZE=$(du -h "$FW" | cut -f1)
SHA=$(sha256sum "$FW" | cut -d' ' -f1)

echo "Kernel: $KERNEL"
echo "Size:   $SIZE"
echo "SHA256: $SHA"

echo "=== 构建后验证完成 ==="
