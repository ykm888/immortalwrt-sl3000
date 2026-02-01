#!/bin/bash
set -e

echo ">>> [自愈体系] clean-feeds.sh v12-final + 三件套12道检测 启动"

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
  libcrypt-compat libpam libtirpc libev libnsl xz lm-sensors wsdd2 attr || true

# --- 4. 三件套注册 ---
REPO_DIR="$GITHUB_WORKSPACE/repo"

DTS_FILE="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
MK_TARGET="target/linux/mediatek/image/filogic.mk"
CONF_FILE="$REPO_DIR/sl3000/config/sl3000.config"

if [ ! -f "$DTS_FILE" ] || [ ! -f "$MK_TARGET" ] || [ ! -f "$CONF_FILE" ]; then
    echo "[ERROR] 三件套缺失"
    exit 1
fi

echo ">>> 三件套一致性检查..."

# --- 5. 三件套 12 道检测 ---
# 1. DTS SoC 校验
grep -q "mediatek,mt7981" "$DTS_FILE" || { echo "[ERROR] DTS SoC 不匹配"; exit 1; }
# 2. DTS 文件名校验
[[ "$(basename "$DTS_FILE")" == "mt7981b-sl3000-emmc.dts" ]] || { echo "[ERROR] DTS 文件名错误"; exit 1; }
# 3. MK 设备名校验
grep -q "sl3000-emmc" "$MK_TARGET" || { echo "[ERROR] MK 设备名不匹配"; exit 1; }
# 4. MK 中 TARGET_DEVICES 校验
grep -q "TARGET_DEVICES += sl3000-emmc" "$MK_TARGET" || { echo "[ERROR] MK 未注册设备"; exit 1; }
# 5. CONFIG 平台校验
grep -q "CONFIG_TARGET_mediatek_filogic=y" "$CONF_FILE" || { echo "[ERROR] CONFIG 平台缺失"; exit 1; }
# 6. CONFIG 设备项校验
grep -q "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" "$CONF_FILE" || { echo "[ERROR] CONFIG 设备项缺失"; exit 1; }
# 7. DTS Hash 校验
sha256sum "$DTS_FILE"
# 8. MK Hash 校验
sha256sum "$MK_TARGET"
# 9. CONFIG Hash 校验
sha256sum "$CONF_FILE"
# 10. 三件套文件非空
[[ -s "$DTS_FILE" && -s "$MK_TARGET" && -s "$CONF_FILE" ]] || { echo "[ERROR] 三件套文件为空"; exit 1; }
# 11. DTS 注入路径校验
[[ -d target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek ]] || mkdir -p target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek
# 12. 最终 defconfig 校验
cp -v "$CONF_FILE" .config
make defconfig

# --- 6. DTS 注入 ---
rm -f "$DTS_FILE"
cp -v "$REPO_DIR/sl3000/dts/mt7981b-sl3000-emmc.dts" "$DTS_FILE"

# --- 7. MK 安全插入 ---
sed -i '/Device\/sl3000-emmc/,/endef/d' "$MK_TARGET"
sed -i '/TARGET_DEVICES += sl3000-emmc/d' "$MK_TARGET"
awk -v patch="$REPO_DIR/sl3000/mk/filogic-sl3000.mk" '
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

echo "=== clean-feeds.sh v12-final + 三件套12道检测 完成 ==="
