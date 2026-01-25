#!/bin/bash
set -e

echo "=== 🔍 SL3000 三件套轻量检查（不依赖 toolchain） ==="

DTS="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
MK="target/linux/mediatek/image/filogic.mk"
CFG=".config"

check_file() {
    local f="$1"
    if [ ! -f "$f" ]; then
        echo "❌ 文件不存在: $f"
        exit 1
    fi
    echo "✔ 文件存在: $f"
}

clean_check() {
    local f="$1"
    echo "--- 检查不可见字符: $f ---"
    if grep -P "[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]" "$f" >/dev/null; then
        echo "❌ 检测到不可见字符"
        exit 1
    fi
    echo "✔ 无不可见字符"
}

echo "--- DTS 前 20 行 ---"
sed -n '1,20p' "$DTS" || true

check_file "$DTS"
check_file "$MK"
check_file "$CFG"

clean_check "$DTS"
clean_check "$MK"
clean_check "$CFG"

echo "✔ 轻量检查完成（未执行 cpp/dtc，不依赖 toolchain）"
