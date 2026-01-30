#!/bin/bash
set -e

FEEDS_ROOT="package/feeds"

echo "=== 清空 feeds 包 ==="
rm -rf $FEEDS_ROOT/packages/*
rm -rf $FEEDS_ROOT/luci/*
rm -rf $FEEDS_ROOT/small/*
rm -rf $FEEDS_ROOT/helloworld/*
rm -rf feeds/packages/utils/policycoreutils  # ← 关键修复：彻底移除 libpam 脏包

mkdir -p $FEEDS_ROOT/packages
mkdir -p $FEEDS_ROOT/packages/libs
mkdir -p $FEEDS_ROOT/packages/lang
mkdir -p $FEEDS_ROOT/luci
mkdir -p $FEEDS_ROOT/small
mkdir -p $FEEDS_ROOT/helloworld

# -------------------------------
# 自动 fallback 复制函数（保留）
# -------------------------------
copy_pkg() {
  local pkg="$1"
  for path in \
    feeds/helloworld/$pkg \
    feeds/small/$pkg \
    feeds/packages/$pkg \
    feeds/packages/libs/$pkg \
    feeds/packages/net/$pkg \
    feeds/packages/utils/$pkg \
    feeds/packages/lang/$pkg
  do
    if [ -d "$path" ]; then
      case "$path" in
        feeds/packages/libs/*)
          cp -r "$path" "$FEEDS_ROOT/packages/libs/"
          ;;
        feeds/packages/lang/*)
          cp -r "$path" "$FEEDS_ROOT/packages/lang/"
          ;;
        feeds/packages/*)
          cp -r "$path" "$FEEDS_ROOT/packages/"
          ;;
        feeds/small/*)
          cp -r "$path" "$FEEDS_ROOT/small/"
          ;;
        feeds/helloworld/*)
          cp -r "$path" "$FEEDS_ROOT/helloworld/"
          ;;
      esac
      return
    fi
  done
}

# -------------------------------
# 1. LuCI 基础（保留）
# -------------------------------
echo "=== 保留 LuCI 基础 ==="
for p in \
  luci-base luci-compat luci-lua-runtime \
  luci-lib-ip luci-lib-jsonc luci-theme-bootstrap
do
  cp -r feeds/luci/**/$p $FEEDS_ROOT/luci/ 2>/dev/null || true
done

# -------------------------------
# 2. 删除科学上网包（彻底移除）
# -------------------------------
echo "=== 已禁用：Passwall2 / SSRPlus / Xray（不再复制） ==="
# 故意留空，不复制任何科学上网包

# -------------------------------
# 3. 删除 SSRPlus 依赖补齐（彻底移除）
# -------------------------------
echo "=== 已禁用：SSRPlus 依赖补齐 ==="
# 故意留空，不复制任何依赖

# -------------------------------
# 4. 删除底层库依赖补齐（彻底移除）
# -------------------------------
echo "=== 已禁用：底层库依赖（libev/libsodium/libudns/boost） ==="
# 故意留空

# -------------------------------
# 5. 删除 host 工具依赖（golang / rust）
# -------------------------------
echo "=== 已禁用：golang / rust host 工具 ==="
# 故意留空

# -------------------------------
# 6. 禁用主线扫描（保留）
# -------------------------------
echo "=== 禁用主线包扫描 ==="
cat > .config << "EOF"
CONFIG_ALL=n
CONFIG_ALL_KMODS=n
CONFIG_ALL_NONSHARED=n
EOF

# -------------------------------
# 7. 写入白名单 config（无科学上网包）
# -------------------------------
echo "=== 写入白名单 config（无科学上网包） ==="
cat >> .config << "EOF"
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y

# LuCI 基础
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-compat=y
CONFIG_PACKAGE_luci-lua-runtime=y
CONFIG_PACKAGE_luci-lib-ip=y
CONFIG_PACKAGE_luci-lib-jsonc=y
CONFIG_PACKAGE_luci-theme-bootstrap=y

# LuCI 网络管理
CONFIG_PACKAGE_luci-mod-admin-full=y
CONFIG_PACKAGE_luci-mod-network=y
CONFIG_PACKAGE_luci-mod-status=y
CONFIG_PACKAGE_luci-mod-system=y
CONFIG_PACKAGE_luci-proto-ppp=y
CONFIG_PACKAGE_luci-proto-ipv6=y

# 中文语言包
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
EOF

echo "=== 白名单模式完成（无科学上网版） ==="
