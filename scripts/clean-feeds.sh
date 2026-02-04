#!/bin/bash
set -e

echo ">>> [SL3000] 执行源码层级初始化..."

# 1. 更新并安装 Feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 2. 注入 1GB 内存与 eMMC 核心配置到 .config
# 注意：CONFIG_TARGET_KERNEL_PARTSIZE 必须匹配分区表
cat <<EOT > .config
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y
CONFIG_TARGET_KERNEL_PARTSIZE=128
CONFIG_TARGET_ROOTFS_PARTSIZE=1024
CONFIG_PACKAGE_kmod-mmc=y
CONFIG_PACKAGE_kmod-sdhci-mtk=y
CONFIG_PACKAGE_f2fs-tools=y
CONFIG_PACKAGE_kmod-fs-f2fs=y
EOT

# 3. 修正镜像定义文件 (filogic.mk)
# 从 custom-config 中拷贝预设好的镜像产生规则
SRC_DIR="../../custom-config"
if [ -d "$SRC_DIR" ]; then
    MK_SRC=$(find "$SRC_DIR" -name "filogic.mk" | head -n 1)
    [ -f "$MK_SRC" ] && cp -fv "$MK_SRC" target/linux/mediatek/image/filogic.mk
fi

# 4. 执行 defconfig 确保依赖完整
make defconfig

echo "✅ [customize.sh] 基础配置注入完成。"
