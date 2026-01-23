#!/bin/sh

echo "=== 清空三件套开始 ==="

DTS="target/linux/mediatek/dts/mt7981b-sl3000-emmc.dts"
MK="target/linux/mediatek/image/filogic.mk"
CONF=".config"

rm -f "$DTS" "$MK" "$CONF"

mkdir -p target/linux/mediatek/dts
mkdir -p target/linux/mediatek/image

touch "$DTS" "$MK" "$CONF"

git add "$DTS" "$MK" "$CONF"
git commit -m "reset: 清空三件套"
git push

echo "=== ✔ 三件套已清空并推送 ==="
