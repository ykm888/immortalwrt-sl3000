#!/bin/bash
set -e

echo ">>> [自愈体系] clean-feeds.sh v12-final 启动 (延续 build-sl3000-2512 工作流)"

# --- 路径校验 ---
if [ ! -f "scripts/feeds" ]; then
    echo "[ERROR] 当前目录不是 OpenWrt 根目录: $(pwd)"
    exit 1
fi

# --- 冲突包清理 ---
CONFLICTS="
package/system/refpolicy
package/system/selinux-policy
package/utils/policycoreutils
package/utils/pcat-manager
package/network/services/lldpd
package/boot/kexec-tools
package/emortal/default-settings
"
for p in $CONFLICTS; do
    [ -d "$p" ] && rm -rf "$p"
done

# --- Feeds 可复现机制 ---
if [ -f "feeds.lock" ]; then
    echo ">>> 使用 feeds.lock 重放 feeds"
    grep -q "src-git" feeds.lock || { echo "[ERROR] feeds.lock 损坏"; exit 1; }
    cp -v feeds.lock feeds.conf.default
    ./scripts/feeds update -a
    ./scripts/feeds install -a
else
    echo ">>> 首次初始化 feeds"
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    cp -v feeds.conf.default feeds.lock
fi

# --- 依赖链补齐 ---
./scripts/feeds install \
  libcrypt-compat libpam libtirpc libev libnsl xz lm-sensors wsdd2 attr || true

# --- 三件套路径定义 ---
DTS_FILE="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
MK_TARGET="target/linux/mediatek/image/filogic.mk"
CONF_FILE="sl3000/config/sl3000.config"

# --- 三件套检测 ---
grep -q "mediatek,mt7981" "$DTS_FILE" || { echo "[ERROR] DTS SoC 不匹配"; exit 1; }
[[ "$(basename "$DTS_FILE")" == "mt7981b-sl3000-emmc.dts" ]] || { echo "[ERROR] DTS 文件名错误"; exit 1; }
grep -q "sl3000-emmc" "$MK_TARGET" || { echo "[ERROR] MK 设备名不匹配"; exit 1; }
grep -q "TARGET_DEVICES += sl3000-emmc" "$MK_TARGET" || { echo "[ERROR] MK 未注册设备"; exit 1; }
grep -q "CONFIG_TARGET_mediatek_filogic=y" "$CONF_FILE" || { echo "[ERROR] CONFIG 平台缺失"; exit 1; }
grep -q "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" "$CONF_FILE" || { echo "[ERROR] CONFIG 设备项缺失"; exit 1; }
sha256sum "$DTS_FILE" "$MK_TARGET" "$CONF_FILE"
[[ -s "$DTS_FILE" && -s "$MK_TARGET" && -s "$CONF_FILE" ]] || { echo "[ERROR] 三件套文件为空"; exit 1; }

echo "=== clean-feeds.sh v12-final 完成 (延续 build-sl3000-2512 工作流) ==="
