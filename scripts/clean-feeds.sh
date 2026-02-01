#!/bin/bash
set -e

echo ">>> clean-feeds.sh（白名单）— 恢复截图工程体系 + 12 道三件套检测修复注册"

# 1. 校验 OpenWrt 根目录
if [ ! -f "scripts/feeds" ]; then
    echo "[ERROR] 当前目录不是 OpenWrt 根目录: $(pwd)"
    exit 1
fi

# 2. 清理信息流配置（白名单）
rm -f feeds.conf.default
cp feeds.conf feeds.conf.default 2>/dev/null || true

# 3. 更新信息流
./scripts/feeds update -a
./scripts/feeds install -a

# 4. 三件套路径（你确认正确）
DTS="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
MK="target/linux/mediatek/image/filogic.mk"
CONF="sl3000/config/sl3000.config"

echo ">>> 执行 12 道三件套检测修复注册"

# 1. DTS 存在性
[ -f "$DTS" ] || { echo "[ERROR] DTS 缺失"; exit 1; }

# 2. MK 存在性
[ -f "$MK" ] || { echo "[ERROR] MK 缺失"; exit 1; }

# 3. CONFIG 存在性
[ -f "$CONF" ] || { echo "[ERROR] CONFIG 缺失"; exit 1; }

# 4. DTS SoC
grep -q "mediatek,mt7981" "$DTS" || { echo "[ERROR] DTS SoC 不匹配"; exit 1; }

# 5. DTS 文件名
[[ "$(basename "$DTS")" == "mt7981b-sl3000-emmc.dts" ]] || {
    echo "[ERROR] DTS 文件名错误"; exit 1;
}

# 6. MK 包含设备名
grep -q "sl3000-emmc" "$MK" || { echo "[ERROR] MK 未包含设备名"; exit 1; }

# 7. MK 注册设备
grep -q "TARGET_DEVICES += sl3000-emmc" "$MK" || {
    echo "[ERROR] MK 未注册设备"; exit 1;
}

# 8. CONFIG 平台
grep -q "CONFIG_TARGET_mediatek_filogic=y" "$CONF" || {
    echo "[ERROR] CONFIG 平台缺失"; exit 1;
}

# 9. CONFIG 设备项
grep -q "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" "$CONF" || {
    echo "[ERROR] CONFIG 设备项缺失"; exit 1;
}

# 10. 文件非空
[[ -s "$DTS" && -s "$MK" && -s "$CONF" ]] || {
    echo "[ERROR] 三件套文件为空"; exit 1;
}

# 11. 自动修复三段式命名
echo ">>> 自动修复三段式命名"
sed -i 's/DEVICE_DTS := .*/DEVICE_DTS := mt7981b-sl3000-emmc/' "$MK"

# 12. 自动注册 CONFIG 到 .config
echo ">>> 自动注册 CONFIG"
cat "$CONF" >> .config

echo ">>> clean-feeds.sh 完成（12 道检测修复注册已恢复）"
