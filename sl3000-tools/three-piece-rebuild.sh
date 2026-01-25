#!/bin/bash
set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

chmod +x "$ROOT_DIR/generate-three-piece.sh"
"$ROOT_DIR/generate-three-piece.sh"

chmod +x "$ROOT_DIR/all-in-one.sh"
"$ROOT_DIR/all-in-one.sh" check

echo "✔ 三件套重建完成（旗舰版）"
