#!/bin/bash
set -e

DTS="$1"

echo "=== DTS 依赖链检测开始 ==="

echo "--- 扫描 include 链路 ---"
INCLUDES=$(grep -oP '(?<=#include ").*(?=")' "$DTS" || true)
MISSING=0

for inc in $INCLUDES; do
  if [[ "$inc" == /* ]]; then
    REAL="$inc"
  else
    REAL="$(dirname $DTS)/$inc"
  fi

  echo "检测 include: $REAL"

  if [ ! -f "$REAL" ]; then
    echo "❌ 缺失依赖: $REAL"
    MISSING=1
  fi
done

if [ "$MISSING" = "1" ]; then
  echo "❌ DTS 依赖链不完整"
  exit 1
fi

echo "--- 检查循环 include ---"
if grep -R "$(basename $DTS)" "$(dirname $DTS)" | grep -v "$DTS"; then
  echo "❌ 检测到循环 include"
  exit 1
fi

echo "--- 使用 dtc 展开依赖链 ---"
dtc -I dts -O dtb -H epapr -@ -o /dev/null "$DTS"
echo "✔ DTS 依赖链完整且可解析"

echo "--- 生成 DTS 依赖图 ---"
DOT="dts-deps.dot"
PNG="dts-deps.png"

echo "digraph DTSDeps {" > "$DOT"
echo "  node [shape=box,fontname=\"monospace\"];" >> "$DOT"
echo "  \"$(basename $DTS)\";" >> "$DOT"

for inc in $INCLUDES; do
  BASE=$(basename "$inc")
  echo "  \"$(basename $DTS)\" -> \"$BASE\";" >> "$DOT"
done

echo "}" >> "$DOT"

dot -Tpng "$DOT" -o "$PNG" || echo "⚠️ DTS 依赖图生成失败"

echo "✔ DTS 依赖图生成完成 ($PNG)"
echo "=== DTS 依赖链检测结束 ==="
