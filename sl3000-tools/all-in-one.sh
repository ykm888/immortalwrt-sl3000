check_dts_syntax() {
    echo "=== 🔍 DTS 语法检查 ==="

    echo "--- DTS 前 20 行 ---"
    sed -n '1,20p' "$DTS_FILE"

    echo "--- DTS 前 20 行（显示不可见字符） ---"
    sed -n '1,20p' "$DTS_FILE" | sed -n 'l'

    echo "--- 使用 cpp 预处理后再检查 ---"

    cpp -P \
        -I"$DTS_DIR" \
        -I"$REPO_ROOT/target/linux/mediatek/files-6.6/include" \
        -I"$REPO_ROOT/include" \
        "$DTS_FILE" \
    | dtc -I dts -O dtb -o /dev/null -

    echo "✔ DTS 语法检查通过"
}
