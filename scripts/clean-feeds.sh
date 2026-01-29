#!/bin/bash

FEEDS_ROOT="package/feeds"

rm -rf $FEEDS_ROOT/packages/*
rm -rf $FEEDS_ROOT/luci/*
rm -rf $FEEDS_ROOT/small/*
rm -rf $FEEDS_ROOT/helloworld/*

mkdir -p $FEEDS_ROOT/packages
mkdir -p $FEEDS_ROOT/luci
mkdir -p $FEEDS_ROOT/small
mkdir -p $FEEDS_ROOT/helloworld

# luci 基础
cp -r feeds/luci/modules/luci-base $FEEDS_ROOT/luci/
cp -r feeds/luci/modules/luci-compat $FEEDS_ROOT/luci/
cp -r feeds/luci/modules/luci-lua-runtime $FEEDS_ROOT/luci/
cp -r feeds/luci/libs/luci-lib-ip $FEEDS_ROOT/luci/
cp -r feeds/luci/libs/luci-lib-jsonc $FEEDS_ROOT/luci/
cp -r feeds/luci/themes/luci-theme-bootstrap $FEEDS_ROOT/luci/

# SSRPlus / Xray / geodata → 必须放在 helloworld feed 下
cp -r feeds/helloworld/luci-app-ssr-plus $FEEDS_ROOT/helloworld/
cp -r feeds/helloworld/ssr-plus $FEEDS_ROOT/helloworld/
cp -r feeds/helloworld/xray-core $FEEDS_ROOT/helloworld/
cp -r feeds/helloworld/v2ray-geodata $FEEDS_ROOT/helloworld/

# Passwall2
cp -r feeds/small/luci-app-passwall2 $FEEDS_ROOT/small/
cp -r feeds/small/passwall2 $FEEDS_ROOT/small/
cp -r feeds/small/xray-core $FEEDS_ROOT/small/ 2>/dev/null || true
