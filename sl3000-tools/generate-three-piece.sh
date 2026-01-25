#!/bin/bash
set -e

#########################################
# SL3000 工程级总控脚本（最终版）
# - 与 printf 版 generate-three-piece.sh 完全配套
# - 只使用仓库根目录 target/
#########################################

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$ROOT_DIR/.."

DTS_FILE="$REPO_ROOT/target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
MK_FILE="$REPO_ROOT/target/linux/mediatek/image/filogic.mk"
CFG_FILE="$REPO_ROOT/.config"

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
    mkdir -p "$REPO_ROOT/target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
    mkdir -p "$REPO_ROOT/target/linux/mediatek/image"
}

check_dts_syntax() {
    echo "=== 🔍 DTS 语法检查 ==="
    sed -n '1,20p' "$DTS_FILE"
    sed -n '1,20p' "$DTS_FILE" | sed -n 'l'

    dtc -I dts -O dtb "$DTS_FILE" -o /dev/null
    echo "✔ DTS 语法检查通过"
}

check_mk() {
    echo "=== 🔍 MK 结构检查 ==="
    grep -q "Device/mt7981b-sl3000-emmc" "$MK_FILE"
    grep -q "TARGET_DEVICES" "$MK_FILE"
    echo "✔ MK 检查通过"
}

check_config() {
    echo "=== 🔍 CONFIG 检查 ==="
    grep -q "CONFIG_TARGET_mediatek_filogic=y" "$CFG_FILE"
    grep -q "CONFIG_LINUX_6_6=y" "$CFG_FILE"
    echo "✔ CONFIG 检查通过"
}

clean_all() {
    clean_file "$DTS_FILE"
    clean_file "$MK_FILE"
    clean_file "$CFG_FILE"
}

run_check() {
    fix_paths
    clean_all
    check_dts_syntax
    check_mk
    check_config
    echo "=== ✅ CHECK 完成 ==="
}

run_full() {
    chmod +x "$ROOT_DIR/generate-three-piece.sh"
    "$ROOT_DIR/generate-three-piece.sh"

    run_check

    cd "$REPO_ROOT"
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
