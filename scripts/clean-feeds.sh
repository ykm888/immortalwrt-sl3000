#!/bin/bash
set -e

echo ">>> [自愈体系] clean-feeds.sh v12 启动"

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
    echo ">>> 使用 feeds.lock 重放 feeds"
    cp -v feeds.lock feeds.conf.default
    ./scripts/feeds update -a
    ./scripts/feeds install -a
else
    echo ">>> 首次初始化 feeds"
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    cp -v feeds.conf.default feeds.lock
fi

# --- 3. 依赖链补齐 ---
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
REPO_DIR="$GITHUB_WORKSPACE/repo"

DTS_FILE="$REPO_DIR/sl3000/dts/mt7981b-sl-3000-emmc.dts"
MK_PATCH="$REPO_DIR/sl3000/mk/filogic-sl3000.mk"
CONF_FILE="$REPO_DIR/sl3000/config/sl3000.config"

if [ ! -f "$DTS_FILE" ] || [ ! -f "$MK_PATCH" ] || [ ! -f "$CONF_FILE" ]; then
    echo "[ERROR] 三件套缺失"
    exit 1
fi

echo ">>> 三件套一致性检查..."
grep -q "mediatek,mt7981" "$DTS_FILE" || { echo "[ERROR] DTS SoC 不匹配"; exit 1; }
grep -q "sl3000-emmc" "$MK_PATCH" || { echo "[ERROR] MK 设备名不匹配"; exit 1; }
grep -q "CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_sl_3000-emmc=y" "$CONF_FILE" || {
    echo "[ERROR] CONFIG 设备项缺失"
    exit 1
}

echo ">>> 三件套 Hash："
sha256sum "$DTS_FILE" "$MK_PATCH" "$CONF_FILE"

# --- 4.1 DTS 注入 ---
mkdir -p target/linux/mediatek/dts
rm -f target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts
cp -v "$DTS_FILE" target/linux/mediatek/dts/

# --- 4.2 MK 安全插入 ---
MK_TARGET="target/linux/mediatek/image/filogic.mk"

sed -i '/Device\/sl3000-emmc/,/endef/d' "$MK_TARGET"
sed -i '/TARGET_DEVICES += sl3000-emmc/d' "$MK_TARGET"

awk -v patch="$MK_PATCH" '
  BEGIN { inserted=0 }
  /^define Device/ { last=NR }
  { lines[NR]=$0 }
  END {
    for (i=1;i<=NR;i++) {
      print lines[i]
      if (i==last && !inserted) {
        while ((getline line < patch) > 0) print line
        inserted=1
      }
    }
  }
' "$MK_TARGET" > "$MK_TARGET.tmp"
mv "$MK_TARGET.tmp" "$MK_TARGET"

# --- 4.3 Config 注册 ---
cp -v "$CONF_FILE" .config
make defconfig

echo "=== clean-feeds.sh v12 完成（可复现 + 三件套闭环 + MK 安全插入 + DTS 固定路径） ==="
