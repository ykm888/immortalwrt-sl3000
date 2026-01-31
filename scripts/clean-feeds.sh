#!/bin/bash
set -e

# [自愈逻辑] 自动定位并切换到 OpenWrt 源码目录
SOURCE_DIR=$(pwd)
echo "=== 企业级全链路自愈脚本 (SL3000 / 24.10) ==="

# [1] 冲突包清理 (Blacklist 模式)
CONFLICTS="package/system/refpolicy package/system/selinux-policy package/utils/policycoreutils package/utils/pcat-manager package/network/services/lldpd package/boot/kexec-tools package/emortal/default-settings package/libs/libpam package/libs/libtirpc package/libs/libnsl package/libs/xz"

for p in $CONFLICTS; do
    if [ -d "$p" ]; then
        rm -rf "$p"
        echo "已清理冲突路径: $p"
    fi
done

# [2] 依赖链注册自愈 (解决 libcrypt-compat 等卡死问题)
echo "[2] 补全底层依赖链与 Feeds 锁定..."
./scripts/feeds update -a
# 显式安装 24.10 必需的影子依赖
./scripts/feeds install libcrypt-compat libpam libtirpc libev libnsl xz lm-sensors wsdd2 attr libsasl2 libusb-compat libcurl libexpat
# 恢复 LuCI 核心白名单
./scripts/feeds install luci-base luci-compat luci-lua-runtime luci-lib-ip luci-lib-jsonc luci-theme-bootstrap

# [3] 三件套原子化注册 (DTS/MK)
# 动态寻找仓库中的三件套 (假设 checkout 到 $GITHUB_WORKSPACE/repo)
DTS_PATH=$(find $GITHUB_WORKSPACE/repo -name "mt7981b-sl3000-emmc.dts" | head -n 1)
MK_PATCH=$(find $GITHUB_WORKSPACE/repo -name "filogic-sl3000.mk" | head -n 1)

if [ -f "$DTS_PATH" ]; then
    mkdir -p target/linux/mediatek/dts
    cp -v "$DTS_PATH" target/linux/mediatek/dts/
fi

# [MK 注入自愈] 解决 append 污染致命问题
MK_TARGET="target/linux/mediatek/image/filogic.mk"
if [ -f "$MK_PATCH" ]; then
    # 使用 grep 检查，确保只注入一次
    if ! grep -q "sl_3000-emmc" "$MK_TARGET"; then
        echo ">>> 注册 SL3000 设备 ID 至 MK 系统..."
        cat "$MK_PATCH" >> "$MK_TARGET"
    else
        echo ">>> 设备已注册，跳过追加以防止 Makefile 污染。"
    fi
fi

echo "=== clean-feeds.sh 执行完毕 (自愈闭环已建立) ==="
