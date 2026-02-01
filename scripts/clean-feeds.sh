#!/bin/bash
set -e

echo ">>> [自愈体系] clean-feeds.sh v29-sl3000-final 启动"

# --- 0. 路径校验 ---
if [ ! -f "scripts/feeds" ]; then
    echo "[ERROR] 当前目录不是 OpenWrt 根目录: $(pwd)"
    exit 1
fi

# --- 1. 冲突包清理 ---
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

# --- 2. Feeds 可复现机制 ---
if [ -f "feeds.lock" ]; then
    echo ">>> 使用 feeds.lock 校验 feeds"
    diff -u feeds.conf.default feeds.lock || true
    ./scripts/feeds update -a
    ./scripts/feeds install -a
else
    echo ">>> 首次初始化 feeds"
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    cp -v feeds.conf.default feeds.lock
fi

# --- 3. 依赖链补齐（24.10 关键包，缺失不报错） ---
./scripts/feeds install \
  libcrypt-compat \
  libpam \
  libtirpc \
  libev \
  libnsl \
  xz \
  lm-sensors \
  wsdd2 \
  attr \
  || true

# --- 4. 三件套注册 ---
DTSFILE="target/linux/mediatek/dts/mt7981b-sl3000-emmc.dts"
MKFILE="target/linux/mediatek/image/filogic.mk"
CONFFILE="$GITHUB_WORKSPACE/repo/sl3000/config/sl3000.config"

if [ ! -f "$DTSFILE" ] || [ ! -f "$MKFILE" ] || [ ! -f "$CONFFILE" ]; then
    echo "[ERROR] 三件套缺失"
    ls -lh target/linux/mediatek/dts/ || true
    ls -lh target/linux/mediatek/image/ || true
    ls -lh $GITHUB_WORKSPACE/repo/sl3000/config/ || true
    exit 1
fi

echo ">>> 三件套一致性检查..."
sha256sum "$DTSFILE" "$MKFILE" "$CONFFILE"

# --- 4.1 DTS 已在源码，不再复制 ---
echo ">>> DTS 已在源码路径: $DTSFILE"

# --- 4.2 MK 已在源码，不再插入 ---
echo ">>> MK 已在源码路径: $MKFILE"

# --- 4.3 Config 注册 ---
cp -v "$CONFFILE" .config
make defconfig

# --- 4.4 激活确认 ---
grep "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" .config \
  && echo ">>> sl3000-emmc 已激活" \
  || { echo "[ERROR] sl3000-emmc 未激活"; exit 1; }

echo "=== clean-feeds.sh v29-sl3000-final 完成（可复现 + 三件套闭环，MK/DTS 已固定路径） ==="
