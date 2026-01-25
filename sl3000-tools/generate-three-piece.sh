###############################################
# 三件套自动创建（不存在 → 自动创建；存在 → 不创建）
###############################################

# DTS
if [ ! -f "$DTS_OUT" ]; then
    echo "⚠ DTS 不存在，自动创建：$DTS_OUT"
    mkdir -p "$(dirname "$DTS_OUT")"
    touch "$DTS_OUT"
else
    echo "✔ DTS 已存在：$DTS_OUT"
fi

# MK
if [ ! -f "$MK_OUT" ]; then
    echo "⚠ MK 不存在，自动创建：$MK_OUT"
    mkdir -p "$(dirname "$MK_OUT")"
    touch "$MK_OUT"
else
    echo "✔ MK 已存在：$MK_OUT"
fi

# CONFIG
if [ ! -f "$CFG_OUT" ]; then
    echo "⚠ CONFIG 不存在，自动创建：$CFG_OUT"
    touch "$CFG_OUT"
else
    echo "✔ CONFIG 已存在：$CFG_OUT"
fi
