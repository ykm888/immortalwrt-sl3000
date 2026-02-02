#!/bin/bash
set -e

echo ">>> [工程体系] 启动 clean-feeds.sh 全链路自愈"

# ================= 1. 三件套源路径自愈 =================

echo ">>> [自愈] 探测三件套源路径..."

DTS_SRC=""
MK_SRC=""
CONF_SRC=""

# 优先：immortalwrt/sl3000 目录（当前 WORKDIR 下）
if [ -d "sl3000" ]; then
  DTS_SRC=$(find sl3000 -path "*mt7981b-sl3000-emmc.dts" | head -n 1 || true)
  MK_SRC=$(find sl3000 -name "filogic.mk" | head -n 1 || true)
  CONF_SRC=$(find sl3000 -path "*sl3000.config" | head -n 1 || true)
fi

# 兜底：GITHUB_WORKSPACE/custom-config（如果你以后想把三件套也放那）
if { [ -z "$DTS_SRC" ] || [ -z "$MK_SRC" ] || [ -z "$CONF_SRC" ]; } && [ -n "$GITHUB_WORKSPACE" ]; then
  if [ -d "${GITHUB_WORKSPACE}/custom-config" ]; then
    DTS_SRC=${DTS_SRC:-$(find "${GITHUB_WORKSPACE}/custom-config" -path "*mt7981b-sl3000-emmc.dts" | head -n 1 || true)}
    MK_SRC=${MK_SRC:-$(find "${GITHUB_WORKSPACE}/custom-config" -name "filogic.mk" | head -n 1 || true)}
    CONF_SRC=${CONF_SRC:-$(find "${GITHUB_WORKSPACE}/custom-config" -path "*sl3000.config" | head -n 1 || true)}
  fi
fi

echo "  DTS_SRC  = ${DTS_SRC:-<未找到>}"
echo "  MK_SRC   = ${MK_SRC:-<未找到>}"
echo "  CONF_SRC = ${CONF_SRC:-<未找到>}"

if [ -z "$DTS_SRC" ] || [ -z "$MK_SRC" ] || [ -z "$CONF_SRC" ]; then
  echo "ERROR: 资源文件搜索失败（三件套不完整）"
  exit 1
fi

# ================= 2. 绑定内核 files-* 目录 =================

KVER_DIR=$(ls -d target/linux/mediatek/files-* 2>/dev/null | head -n 1 || true)
if [ -z "$KVER_DIR" ]; then
  echo "ERROR: 找不到 target/linux/mediatek/files-* 目录"
  ls -d target/linux/mediatek/* || true
  exit 1
fi
echo ">>> [自愈] 绑定内核 files 目录: $KVER_DIR"

DTS_DEST="$KVER_DIR/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-emmc.dts"
MK_DEST="target/linux/mediatek/image/filogic.mk"
CONF_DEST="configs/sl3000-emmc.config"

# ================= 3. 执行三件套注入 =================

echo ">>> [注入] DTS -> $DTS_DEST"
mkdir -p "$(dirname "$DTS_DEST")"
cp -f "$DTS_SRC" "$DTS_DEST"

echo ">>> [注入] MK  -> $MK_DEST"
mkdir -p "$(dirname "$MK_DEST")"
cp -f "$MK_SRC" "$MK_DEST"

echo ">>> [注入] CONF -> $CONF_DEST"
mkdir -p "$(dirname "$CONF_DEST")"
cp -f "$CONF_SRC" "$CONF_DEST"

# ================= 4. Feeds 更新与预处理 =================

echo ">>> [Feeds] 更新与冲突预处理..."
./scripts/feeds update -a
rm -rf package/feeds/helloworld/luci-app-ssr-plus || true
./scripts/feeds install -a

# ================= 5. 12 道工程门禁 =================

echo ">>> 启动 12 道工程门禁..."

echo ">>> [门禁1] DTS 注入物理存在: $DTS_DEST"
[ -f "$DTS_DEST" ] || { echo "ERROR: 1. DTS 注入物理失败"; exit 1; }

echo ">>> [门禁2] DTS SoC 定义检查"
grep -q "mediatek,mt7981" "$DTS_DEST" || { echo "ERROR: 2. DTS SoC 定义不匹配"; exit 1; }

echo ">>> [门禁3] DTS 语法检查 (dtc)"
dtc -I dts -O dtb "$DTS_DEST" -o /dev/null || {
  echo "ERROR: 3. DTS 语法检查未通过（前 40 行如下）"
  sed -n '1,40p' "$DTS_DEST" || true
  exit 1
}

echo ">>> [门禁4] MK 存在 sl3000-emmc 设备定义"
grep -q "Device/sl3000-emmc" "$MK_DEST" || { echo "ERROR: 4. MK 模板缺少设备定义"; exit 1; }

echo ">>> [门禁5] Config 中包含 sl3000-emmc 相关内容"
grep -q "sl3000-emmc" "$CONF_DEST" || { echo "ERROR: 5. Config 缺少目标 Profile"; exit 1; }

echo ">>> [门禁6] DTS 非空"
[ -s "$DTS_DEST" ] || { echo "ERROR: 6. DTS 文件为空"; exit 1; }

echo ">>> [门禁7] MK 非空"
[ -s "$MK_DEST" ] || { echo "ERROR: 7. MK 文件为空"; exit 1; }

echo ">>> [门禁8] Config 非空"
[ -s "$CONF_DEST" ] || { echo "ERROR: 8. Config 文件为空"; exit 1; }

echo ">>> [门禁9] MK 中包含 TARGET_DEVICES 注册"
grep -q "TARGET_DEVICES += sl3000-emmc" "$MK_DEST" || { echo "ERROR: 9. MK 未注册设备"; exit 1; }

echo ">>> [门禁10] Config 中包含 mediatek_filogic 平台"
grep -q "CONFIG_TARGET_mediatek_filogic=y" "$CONF_DEST" || { echo "ERROR: 10. Config 平台定义缺失"; exit 1; }

echo ">>> [门禁11] MK 设备块中 DEVICE_DTS 自愈"
awk -v dts="mt7981b-sl3000-emmc" '
/define Device\/sl3000-emmc/ {in_block=1; found_dts=0; print; next}
in_block && /DEVICE_DTS :=/ {print "  DEVICE_DTS := "dts; found_dts=1; next}
/endef/ && in_block {
    if (!found_dts) print "  DEVICE_DTS := "dts;
    in_block=0; print; next
}
{print}
' "$MK_DEST" > "${MK_DEST}.tmp" && mv "${MK_DEST}.tmp" "$MK_DEST"

echo ">>> [门禁12] 不在此处修改 .config，由工作流统一控制"

echo ">>> clean-feeds.sh 全链路门禁通过！"
