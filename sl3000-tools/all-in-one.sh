#!/bin/bash
set -e

#########################################
# SL3000 工程级总控脚本（最终版）
# - 与 printf 版 generate-three-piece.sh 完全配套
# - 使用仓库根目录 target/
#########################################

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$ROOT_DIR/.."

DTS_FILE="$REPO_ROOT/target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
MK_FILE="$REPO_ROOT/target/linux/mediatek/image/filogic.mk"
CFG_FILE="$REPO_ROOT/.config"

#########################################
# 清理隐藏字符（最关键）
#########################################
clean_file() {
    local f="$1"
    [ -f "$f" ] || return 0

    # 删除 CR
    sed -i 's/\r$//' "$f"

    # 删除 BOM
    sed -i '1s/^\xEF\xBB\xBF//' "$f"

    # 删除 NBSP
    sed -i 's/\xC2\xA0//g' "$f"

    # 删除零宽空格
    sed -i 's/\xE2\x80\x8B//g' "$f"

    # 删除所有 C0/C1 控制字符（核心）
    tr -d '\000-\011\013\014\016-\037\177' < "$f" > "$f.clean"
    mv "$f.clean" "$f"
}

clean_all() {
    clean_file "$DTS_FILE"
    clean_file "$MK_FILE"
    clean_file "$CFG_FILE"
}

#########################################
# 路径修复
#########################################
fix_paths() {
    mkdir -p "$REPO_ROOT/target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
    mkdir -p "$REPO_ROOT/target/linux/mediatek/image"
}

#########################################
# DTS 语法检查
#########################################
check_dts_syntax() {
    echo "=== 🔍 DTS 语法检查 ==="

    echo "--- DTS 前 20 行 ---"
    sed -n '1,20p' "$DTS_FILE"

    echo "--- DTS 前 20 行（显示不可见字符） ---"
    sed -n '1,20p' "$DTS_FILE" | sed -n 'l'

    dtc -I dts -O dtb "$DTS_FILE" -o /dev/null
    echo "✔ DTS 语法检查通过"
}

#########################################
# MK 检查
#########################################
check_mk() {
    echo "=== 🔍 MK 检查 ==="
    grep -q "Device/mt7981b-sl3000-emmc" "$MK_FILE"
    grep -q "TARGET_DEVICES" "$MK_FILE"
    echo "✔ MK 检查通过"
}

#########################################
# CONFIG 检查
#########################################
check_config() {
    echo "=== 🔍 CONFIG 检查 ==="
    grep -q "CONFIG_TARGET_mediatek_filogic=y" "$CFG_FILE"
    grep -q "CONFIG_LINUX_6_6=y" "$CFG_FILE"
    echo "✔ CONFIG 检查通过"
}

#########################################
# CHECK 模式
#########################################
run_check() {
    echo "=== 🔍 运行 CHECK 模式 ==="
    fix_paths
    clean_all
    check_dts_syntax
    check_mk
    check_config
    echo "=== ✅ CHECK 完成 ==="
}

#########################################
# FULL 模式
#########################################
run_full() {
    echo "=== 🚀 FULL 模式：生成三件套 + 检查 + 构建 ==="

    chmod +x "$ROOT_DIR/generate-three-piece.sh"
    "$ROOT_DIR/generate-three-piece.sh"

    run_check

    cd "$REPO_ROOT"
    make defconfig
    make -j"$(nproc)"
}

#########################################
# 主入口
#########################################
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
