DTS_DIR := $(DTS_DIR)/mediatek

define Image/Prepare
	# 为 UBI 准备额外的块标记
	rm -f $(KDIR)/ubi_mark
	echo -ne '\xde\xad\xc0\xde' > $(KDIR)/ubi_mark
endef

# --- 基础构建指令 ---
define Build/mt7981-bl2
	cat $(STAGING_DIR_IMAGE)/mt7981-$1-bl2.img >> $@
endef

define Build/mt7981-bl31-uboot
	cat $(STAGING_DIR_IMAGE)/mt7981_$1-u-boot.fip >> $@
endef

# --- GPT 分区表生成器 (核心修复：适配 eMMC) ---
define Build/mt798x-gpt
	cp $@ $@.tmp 2>/dev/null || true
	ptgen -g -o $@.tmp -a 1 -l 1024 \
		$(if $(findstring sdmmc,$1), \
			-H \
			-t 0x83	-N bl2		-r	-p 4079k@17k \
		) \
		-t 0x83	-N ubootenv	-r	-p 512k@4M \
		-t 0x83	-N factory	-r	-p 2M@4608k \
		-t 0xef	-N fip		-r	-p 4M@6656k \
		-N recovery	-r	-p 32M@12M \
		$(if $(findstring sdmmc,$1), \
			-N install	-r	-p 20M@44M \
			-t 0x2e -N production		-p $(CONFIG_TARGET_ROOTFS_PARTSIZE)M@64M \
		) \
		$(if $(findstring emmc,$1), \
			-t 0x2e -N production		-p $(CONFIG_TARGET_ROOTFS_PARTSIZE)M@64M \
		)
	cat $@.tmp >> $@
	rm $@.tmp
endef

# --- GL 风格元数据生成 (用于固件校验) ---
metadata_gl_json = \
	'{ $(if $(IMAGE_METADATA),$(IMAGE_METADATA)$(comma)) \
		"metadata_version": "1.1", \
		"compat_version": "$(call json_quote,$(compat_version))", \
		$(if $(DEVICE_COMPAT_MESSAGE),"compat_message": "$(call json_quote,$(DEVICE_COMPAT_MESSAGE))"$(comma)) \
		$(if $(filter-out 1.0,$(compat_version)),"new_supported_devices": \
			[$(call metadata_devices,$(SUPPORTED_DEVICES))]$(comma) \
			"supported_devices": ["$(call json_quote,$(legacy_supported_message))"]$(comma)) \
		$(if $(filter 1.0,$(compat_version)),"supported_devices":[$(call metadata_devices,$(SUPPORTED_DEVICES))]$(comma)) \
		"version": { \
			"release": "$(call json_quote,$(VERSION_NUMBER))", \
			"date": "$(shell TZ='Asia/Chongqing' date '+%Y%m%d%H%M%S')", \
			"dist": "$(call json_quote,$(VERSION_DIST))", \
			"version": "$(call json_quote,$(VERSION_NUMBER))", \
			"revision": "$(call json_quote,$(REVISION))", \
			"target": "$(call json_quote,$(TARGETID))", \
			"board": "$(call json_quote,$(if $(BOARD_NAME),$(BOARD_NAME),$(DEVICE_NAME)))" \
		} \
	}'

define Build/append-gl-metadata
	$(if $(SUPPORTED_DEVICES),-echo $(call metadata_gl_json,$(SUPPORTED_DEVICES)) | fwtool -I - $@)
	sha256sum "$@" | cut -d" " -f1 > "$@.sha256sum"
endef

# ============================================================
# 设备定义：SL3000 eMMC 修复版
# ============================================================

define Device/sl3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := SL3000
  DEVICE_VARIANT := eMMC
  DEVICE_DTS := mt7981b-sl3000-emmc
  DEVICE_DTS_DIR := mediatek
  
  # 必须包含的驱动包，确保 eMMC 挂载
  DEVICE_PACKAGES := kmod-mmc kmod-sdhci-mtk f2fs-tools kmod-fs-f2fs \
                     kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware
  
  # 镜像生成逻辑
  # 对于 eMMC 设备，factory 镜像通常包含 GPT 分区表以便全盘刷写
  # sysupgrade 镜像通过 append-metadata 提供给 LuCI 升级
  IMAGES := sysupgrade.bin factory.bin
  IMAGE/factory.bin := append-kernel | pad-to 128k | append-rootfs | mt798x-gpt emmc
  IMAGE/sysupgrade.bin := append-kernel | pad-to 128k | append-rootfs | mt798x-gpt emmc | append-gl-metadata
endef
TARGET_DEVICES += sl3000-emmc
