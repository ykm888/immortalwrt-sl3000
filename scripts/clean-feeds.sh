#!/bin/bash
set -e

echo ">>> [自愈体系] clean-feeds.sh 启动"

# --- 0. 路径校验 ---
if [ ! -f "scripts/feeds" ]; then
    echo "[ERROR] 当前目录不是 OpenWrt 根目录: $(pwd)"
    exit 1
fi

# --- 1. 冲突包清理（仅清理源码树，不动 feeds） ---
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
    [ -d "$p" ] && echo "Cleaning conflict: $p" && rm -rf "$p"
done

# --- 2. Feeds 可复现机制：优先使用 feeds.lock ---
if [ -f "feeds.lock" ]; then
    echo ">>> 检测到 feeds.lock，按锁定版本重放 feeds"
    # 注意：这里假设 feeds.lock 内容是 `name url` 形式
    > feeds.conf.default
    while read -r feed; do
        name=$(echo "$feed" | awk '{print $1}')
        src=$(echo "$feed" | awk '{print $2}')
        [ -n "$name" ] && [ -n "$src" ] && echo "src-git $name $src" >> feeds.conf.default
    done < feeds.lock
else
    echo ">>> 未检测到 feeds.lock，首次初始化 feeds"
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    ./scripts/feeds list -s > feeds.lock
fi

# --- 3. 依赖链补齐（24.10 全链路） ---
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

# --- 4. 三件套注册（DTS / MK / Config） ---
DTS_FILE=$(find "$GITHUB_WORKSPACE/repo" -name "mt7981b-sl3000-emmc.dts" | head -n 1)
MK_PATCH=$(find "$GITHUB_WORKSPACE/repo" -name "filogic-sl3000.mk" | head -n 1)
CONF_FILE=$(find "$GITHUB_WORKSPACE/repo" -name "sl3000.config" | head -n 1)

if [ -z "$DTS_FILE" ] || [ -z "$MK_PATCH" ] || [ -z "$CONF_FILE" ]; then
    echo "[ERROR] 三件套缺失"
    echo "  DTS_FILE=$DTS_FILE"
    echo "  MK_PATCH=$MK_PATCH"
    echo "  CONF_FILE=$CONF_FILE"
    exit 1
fi

echo ">>> 三件套 Hash："
sha256sum "$DTS_FILE" "$MK_PATCH" "$CONF_FILE"

# --- 4.1 DTS 注入 ---
mkdir -p target/linux/mediatek/dts
rm -f target/linux/mediatek/dts/mt7981b-sl3000-emmc.dts
cp -v "$DTS_FILE" target/linux/mediatek/dts/

# --- 4.2 MK 安全插入（插入到 filogic 设备段末尾） ---
MK_TARGET="target/linux/mediatek/image/filogic.mk"

if ! grep -q "Device/sl_3000-emmc" "$MK_TARGET"; then
    echo ">>> 注入 SL3000 设备段（结构化插入）"
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
else
    echo ">>> SL3000 已存在，跳过 MK 注入"
fi

# --- 4.3 Config 注册 ---
cp -v "$CONF_FILE" .config
make defconfig

echo "=== clean-feeds.sh 完成（可复现 + 三件套闭环 + MK 安全插入） ==="
