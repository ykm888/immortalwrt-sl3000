#!/bin/bash
set -e

#########################################
# SL3000 工程级总控脚本（双模式，24.10 / Linux 6.6）
#   ./all-in-one.sh check  → 只检测
#   ./all-in-one.sh full   → 生成三件套 + 同步 + 构建
#########################################

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -d "$ROOT_DIR/../openwrt" ]; then
    OPENWRT_DIR="$ROOT_DIR/../openwrt"
else
    OPENWRT_DIR="$ROOT_DIR/.."
fi

DTS_FILE="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
MK_FILE="target/linux/mediatek/image/filogic.mk"
CFG_FILE="mt7981b-sl3000-emmc.config"

clean_file() {
    local f="$1"
    [ -f "$f" ] || return 0

    # CR
    sed -i 's/\r$//' "$f"
    # BOM
    sed -i '1s/^\xEF\xBB\xBF//' "$f"
    # NBSP
    sed -i 's/\xC2\xA0//g' "$f"
    # 零宽空格
    sed -i 's/\xE2\x80\x8B//g' "$f"
    # 所有 C0/C1 控制字符
    tr -d '\000-\011\013\014\016-\037\177' < "$f" > "$f.clean"
    mv "$f.clean" "$f"
}

fix_paths() {
    echo "=== 🛠 自动修复：路径检查 ==="
    mkdir -p target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek
    mkdir -p target/linux/mediatek/image
    echo "✔ 路径检查完成"
}

clean_hidden_chars() {
    echo "=== 🧹 自动清理隐藏字符（BOM / CRLF / 控制字符） ==="
    for f in $(find target -type f \( -name "*.dts" -o -name "*.mk" \); echo "$CFG_FILE"); do
        clean_file "$f"
    done
    echo "✔ 隐藏字符清理完成"
}

check_build_env() {
    echo "=== 🧪 构建环境检查 ==="
    command -v gcc >/dev/null || { echo "❌ 缺少 gcc"; exit 1; }
    command -v make >/dev/null || { echo "❌ 缺少 make"; exit 1; }
    command -v dtc >/dev/null || { echo "❌ 缺少 dtc"; exit 1; }
    echo "✔ 构建环境检查通过"
}

check_dts_syntax() {
    echo "=== 🔍 DTS 语法检查（显示 dtc 输出） ==="

    if [ ! -f "$DTS_FILE" ]; then
        echo "❌ DTS 文件不存在：$DTS_FILE"
        exit 1
    fi

    echo "=== 🧾 DTS 前 20 行（CI 实际使用版本） ==="
    sed -n '1,20p' "$DTS_FILE"

    echo "=== 🧾 DTS 前 20 行（显示不可见字符） ==="
    sed -n '1,20p' "$DTS_FILE" | sed -n 'l'

    if ! dtc -I dts -O dtb "$DTS_FILE" -o /dev/null; then
        echo "❌ DTS 语法错误：$DTS_FILE"
        exit 1
    fi

    echo "✔ DTS 语法检查通过"
}

check_mk_structure() {
    echo "=== 🔍 MK 结构检查 ==="

    local req=(
        "define Device/mt7981b-sl3000-emmc"
        "DEVICE_PACKAGES"
        "IMAGE/sysupgrade.bin"
    )

    for p in "${req[@]}"; do
        if ! grep -q "$p" "$MK_FILE"; then
            echo "❌ MK 缺少字段：$p"
            exit 1
        fi
    done

    echo "✔ MK 结构检查通过"
}

check_config_consistency() {
    echo "=== 🔍 CONFIG 一致性检查 ==="

    grep -q "CONFIG_TARGET_mediatek_filogic=y" "$CFG_FILE" || { echo "❌ CONFIG 缺少 filogic"; exit 1; }
    grep -q "CONFIG_LINUX_6_6=y" "$CFG_FILE" || { echo "❌ CONFIG 未启用 Linux 6.6"; exit 1; }
    grep -q "CONFIG_PACKAGE_luci-app-passwall2=y" "$CFG_FILE" || echo "⚠ Passwall2 未启用"
    grep -q "CONFIG_PACKAGE_docker=y" "$CFG_FILE" || echo "⚠ Docker 未启用"

    echo "✔ CONFIG 一致性检查通过"
}

upstream_report() {
    echo "=== 📡 上游变更报告 ==="
    if [ -x "$ROOT_DIR/compare-with-upstream-smart.sh" ]; then
        "$ROOT_DIR/compare-with-upstream-smart.sh"
    fi
}

sync_three_piece() {
    echo "=== 🔄 同步三件套到 openwrt 源码 ==="

    sync_file() {
        local SRC="$1"
        local DST="$OPENWRT_DIR/$1"
        mkdir -p "$(dirname "$DST")"
        if [ "$(realpath "$SRC")" = "$(realpath "$DST")" ]; then
            echo "⚠ 跳过同步（源文件与目标文件相同）：$SRC"
        else
            cp "$SRC" "$DST"
        fi
    }

    sync_file "$DTS_FILE"
    sync_file "$MK_FILE"
    sync_file "$CFG_FILE"

    echo "✔ 三件套同步完成"
}

run_check() {
    echo "=== 🔍 运行 CHECK 模式（不构建固件） ==="
    check_build_env
    fix_paths
    clean_hidden_chars
    check_dts_syntax
    check_mk_structure
    check_config_consistency
    upstream_report
    echo "=== ✅ CHECK 模式完成 ==="
}

run_full() {
    echo "=== 🚀 FULL 模式：完整构建固件 ==="

    chmod +x "$ROOT_DIR/generate-three-piece.sh"
    "$ROOT_DIR/generate-three-piece.sh"

    run_check
    sync_three_piece

    echo "=== 🧱 构建固件 ==="
    cd "$OPENWRT_DIR"
    make defconfig
    make toolchain/install -j"$(nproc)"
    make -j"$(nproc)"

    echo "=== 🎉 FULL 模式完成：固件已生成 ==="
}

case "$1" in
    check) run_check ;;
    full)  run_full  ;;
    *)
        echo "用法："
        echo "  ./all-in-one.sh check   # 只检测"
        echo "  ./all-in-one.sh full    # 完整构建固件"
        exit 1
        ;;
esac
