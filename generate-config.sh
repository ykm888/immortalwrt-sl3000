#!/bin/sh

CONF=".config"

cat > "$CONF" << 'EOF'
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y
CONFIG_LINUX_6_6=y
EOF

git add "$CONF"
echo "✔ .config 已生成"
