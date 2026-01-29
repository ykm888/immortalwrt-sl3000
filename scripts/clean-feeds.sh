#!/bin/bash
# 白名单模式：只保留必要包，其余全部删除
# 目标：构建日志 0 WARNING，feeds 完全干净

ROOT="package/feeds"

echo "=== 白名单模式：开始清理所有 feeds 包 ==="

# -------------------------------
# 1. 删除 packages feed 全部内容
# -------------------------------
rm -rf $ROOT/packages/*

# -------------------------------
# 2. 删除 luci feed 全部内容
# -------------------------------
rm -rf $ROOT/luci/*

# -------------------------------
# 3. 删除 small feed 全部内容
# -------------------------------
rm -rf $ROOT/small/*

# -------------------------------
# 4. 重新创建白名单目录
# -------------------------------

mkdir -p $ROOT/luci
mkdir -p $ROOT/packages
mkdir -p $ROOT/small

echo "=== 保留 luci 基础框架 ==="
# luci 基础必须保留
cp -r feeds/luci/modules/luci-base $ROOT/luci/
cp -r feeds/luci/modules/luci-compat $ROOT/luci/
cp -r feeds/luci/modules/luci-lua-runtime $ROOT/luci/
cp -r feeds/luci/libs/luci-lib-ip $ROOT/luci/
cp -r feeds/luci/libs/luci-lib-jsonc $ROOT/luci/
cp -r feeds/luci/libs/luci-lib-nixio $ROOT/luci/ 2>/dev/null || true
cp -r feeds/luci/themes/luci-theme-bootstrap $ROOT/luci/

echo "=== 保留 Passwall2 / SSRPlus ==="
# helloworld feed
cp -r feeds/helloworld/luci-app-ssr-plus $ROOT/packages/
cp -r feeds/helloworld/ssr-plus $ROOT/packages/
cp -r feeds/helloworld/xray-core $ROOT/packages/
cp -r feeds/helloworld/v2ray-geodata $ROOT/packages/

# passwall2
cp -r feeds/small/luci-app-passwall2 $ROOT/small/
cp -r feeds/small/passwall2 $ROOT/small/
cp -r feeds/small/xray-core $ROOT/small/ 2>/dev/null || true

echo "=== 白名单保留完成 ==="
echo "=== 所有非白名单包已删除 ==="
