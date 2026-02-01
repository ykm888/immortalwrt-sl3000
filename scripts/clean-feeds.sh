#!/bin/bash
set -e

echo ">>> [自愈体系] clean-feeds.sh v12-final 启动"

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
REPODIR="$GITHUB_WORKSPACE/repo"

DTSFILE="$REPODIR/sl3000/dts/mt7981b-sl3000-emmc.dts"
MKPATCH="$REPODIR/sl3000/mk/filogic-sl3000.mk"
CONFFILE="$REPODIR/sl3000/config/sl3000.config"

if [ ! -f "$DTSFILE" ] || [ ! -f "$MKPATCH" ] || [ ! -f "$CONFFILE" ]; then
    echo "[ERROR] 三件套缺失"
    exit 1
fi

echo ">>> 三件套一致性检查..."

# --- DTS 检查 ---
grep -q "mediatek,mt7981" "$DTSFILE" \
  || { echo "[ERROR] DTS SoC 不匹配"; exit 1; }

# --- MK 检查 ---
grep -q "sl3000-emmc" "$MKPATCH" \
  || { echo "[ERROR] MK 设备名不匹配"; exit 1; }

# --- CONFIG 检查 ---
grep -q "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" "$CONFFILE" \
  || { echo "[ERROR] CONFIG 设备项缺失"; exit 1; }

echo ">>> 三件套 Hash："
sha256sum "$DTSFILE" "$MKPATCH" "$CONFFILE"

# --- 4.1 DTS 注入 ---
mkdir -p target/linux/mediatek/dts

# 删除旧 DTS 名称
rm -f target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts

cp -v "$DTSFILE" target/linux/mediatek/dts/

# --- 4.2 MK 安全插入 ---
MK_TARGET="target/linux/mediatek/image/filogic.mk"

# 删除旧定义
sed -i '/Device\/sl3000-emmc/,/endef/d' "$MK_TARGET"
sed -i '/TARGET_DEVICES += sl3000-emmc/d' "$MK_TARGET"

# 结构化插入
awk -v patch="$MKPATCH" '
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
cp -v "$CONFFILE" .config
make defconfig

# --- 4.4 激活确认 ---
grep "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" .config \
  && echo ">>> sl3000-emmc 已激活"

echo "=== clean-feeds.sh v12-final 完成（可复现 + 三件套闭环 + MK 安全插入 + DTS 固定路径） ==="
