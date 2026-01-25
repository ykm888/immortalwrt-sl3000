#!/bin/bash
set -e

#########################################
# SL3000 工程级总控脚本（最终修复版）
#########################################

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 强制使用 openwrt 源码目录
OPENWRT_DIR="$ROOT_DIR/../openwrt"

DTS_FILE="$OPENWRT_DIR/target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
MK_FILE="$OPENWRT_DIR/target/linux/mediatek/image/filogic.mk"
CFG_FILE="$OPENWRT_DIR/.config"

clean_file() {
    local f="$1"
    [ -f "$f" ] || return 0

    sed -i 's/\r$//' "$f"
    sed -i '1s/^\xEF\xBB\xBF//' "$f"
    sed -i 's/\xC2\xA0//g' "$f"
    sed -i 's/\xE2\x80\x8B//g' "$f"
    tr -d '\000-\011\013\014\016-\037\177' < "$f" > "$f.clean"
    mv "$f.clean" "$f"
}

fix_paths() {
    mkdir -p "$OPENWRT_DIR/target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
    mkdir -p "$OPENWRT_DIR/target/linux/mediatek/image"
}

clean_hidden_chars() {
    clean_file "$DTS_FILE"
    clean_file "$MK_FILE"
    clean_file "$CFG_FILE"
}

check_dts_syntax() {
    echo "=== 🔍 DTS 语法检查 ==="
    sed -n '1,20p' "$DTS_FILE"
    sed -n '1,20p' "$DTS_FILE" | sed -n 'l'

    dtc -I dts -O dtb "$DTS_FILE" -o /dev/null
    echo "✔ DTS 语法检查通过"
}

run_check() {
    fix_paths
    clean_hidden_chars
    check_dts_syntax
}

run_full() {
    chmod +x "$ROOT_DIR/generate-three-piece.sh"
    "$ROOT_DIR/generate-three-piece.sh"

    run_check

    cd "$OPENWRT_DIR"
    make defconfig
    make -j"$(nproc)"
}

case "$1" in
    check) run_check ;;
    full)  run_full ;;
    *)
        echo "用法："
        echo "  ./all-in-one.sh check"
        echo "  ./all-in-one.sh full"
        exit 1
        ;;
esac
