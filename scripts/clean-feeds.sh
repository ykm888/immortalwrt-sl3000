#!/bin/bash
#
# clean-feeds.sh
# 白名单 + 强制删除所有非路由器相关包
#

set -e

echo "=== Clean Feeds: 白名单清理开始 ==="

# 你原来的白名单逻辑（保持不变）
# ……

echo "=== Clean Feeds: 白名单清理完成 ==="


echo "=== Force Clean: 删除所有非路由器相关包 ==="

# 1. emortal / small
rm -rf package/emortal || true
rm -rf feeds/emortal || true
rm -rf package/small || true
rm -rf feeds/small || true

# 2. luci-app-*（保留 luci-base）
find package -type d -name "luci-app-*" -exec rm -rf {} + || true
find feeds -type d -name "luci-app-*" -exec rm -rf {} + || true

# 3. 桌面/图形/声音/蓝牙/打印
rm -rf package/xorg || true
rm -rf package/sound || true
rm -rf feeds/packages/pulseaudio* || true
rm -rf feeds/packages/pipewire* || true
rm -rf feeds/packages/bluez* || true
rm -rf feeds/packages/alsa* || true
rm -rf feeds/packages/cups* || true
rm -rf package/libs/*gtk* || true
rm -rf package/libs/qt* || true
rm -rf package/libs/cairo package/libs/pango package/libs/harfbuzz || true

# 4. 已知污染包
rm -rf package/utils/audit || true
rm -rf package/utils/policycoreutils || true
rm -rf package/utils/pcat-manager || true
rm -rf package/network/services/lldpd || true
rm -rf package/boot/kexec-tools || true

# 5. 已知污染库
rm -rf package/libs/libpam || true
rm -rf package/libs/libtirpc || true
rm -rf package/libs/glib2 || true
rm -rf package/libs/libgpiod || true
rm -rf package/libs/libnetsnmp || true
rm -rf package/libs/lm-sensors || true

rm -rf feeds/packages/libs/libpam* || true
rm -rf feeds/packages/libs/libtirpc* || true
rm -rf feeds/packages/libs/glib2* || true
rm -rf feeds/packages/libs/libgpiod* || true
rm -rf feeds/packages/libs/net-snmp* || true
rm -rf feeds/packages/libs/lm-sensors* || true

# 6. emortal 残留
rm -rf package/feeds/*/autosamba* || true
rm -rf package/feeds/*/autocore* || true
rm -rf package/feeds/*/default-settings* || true
rm -rf package/feeds/*/wsdd2* || true

echo "✔ Clean Feeds: 所有非路由器相关包已彻底删除"
