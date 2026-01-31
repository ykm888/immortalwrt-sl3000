#!/bin/bash
set -e

echo "=== clean-feeds.sh (SL3000 / 24.10 / Dependency Fixed) ==="

# 强制进入 OpenWrt 根目录
cd /mnt/openwrt || { echo "[FATAL] Directory /mnt/openwrt not found"; exit 1; }

# [1] 清理源码树中导致冲突的旧包
# 24.10 版本中，这些包在主树中往往与第三方 Feeds 冲突
CONFLICT_PACKS="
package/system/refpolicy 
package/system/selinux-policy 
package/utils/policycoreutils
package/utils/pcat-manager 
package/network/services/lldpd 
package/boot/kexec-tools 
package/emortal/default-settings
"

# 同时也清理主树中可能导致版本冲突的旧库（稍后通过 feeds 补回）
OLD_LIBS="package/libs/libpam package/libs/libtirpc package/libs/libnsl package/libs/xz"

for p in $CONFLICT_PACKS $OLD_LIBS; do
    rm -rf "$p"
done

# [2] 重置 feeds 链接（彻底杜绝残留软链接导致的扫描卡顿）
FEEDS_ROOT="package/feeds"
rm -rf "$FEEDS_ROOT"
mkdir -p "$FEEDS_ROOT"/packages "$FEEDS_ROOT"/luci "$FEEDS_ROOT"/small "$FEEDS_ROOT"/helloworld

# [3] 修复“地基”：重新从 feeds 安装被清理的底层库
# 这一步是解决 "libpam not exist" 警告、让 busybox 顺利通过编译的关键
echo "[3] 修复核心系统依赖 (libpam/libtirpc/libev)..."
./scripts/feeds install -p packages libpam libtirpc libev libnsl xz lm-sensors wsdd2 attr

# [4] 恢复 LuCI 基础框架白名单
echo "[4] 恢复 LuCI 基础组件..."
./scripts/feeds install -p luci luci-base luci-compat luci-lua-runtime luci-lib-ip luci-lib-jsonc luci-theme-bootstrap

echo "=== clean-feeds.sh 执行完毕 ==="
