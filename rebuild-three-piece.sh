#!/bin/sh

echo "=== SL3000 三件套重建开始 ==="

sh reset-three-piece.sh
sh generate-dts.sh
sh generate-mk.sh
sh generate-config.sh

git commit -m "rebuild: 重新生成 SL3000 三件套（DTS/mk/config）"
git push

echo "=== 🎉 三件套已重建并推送 ==="
