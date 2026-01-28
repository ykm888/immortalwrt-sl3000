name: Rebuild SL3000 Three-Piece (24.10 / mt7981)

on:
  workflow_dispatch:

permissions:
  contents: write
  actions: read

jobs:
  rebuild-sl3000-three-piece:
    runs-on: ubuntu-22.04
    timeout-minutes: 10

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
          persist-credentials: true

      - name: Check Script Exists
        run: |
          if [ ! -f "sl3000-tools/generate-three-piece.sh" ]; then
            echo "❌ Script not found"
            exit 1
          fi
          echo "✅ Script found"

      - name: Add Execute Permission
        run: chmod 755 sl3000-tools/*.sh

      - name: Clone OpenWrt 24.10
        run: |
          git clone --depth=1 -b openwrt-24.10 https://github.com/openwrt/openwrt.git openwrt-src

      # 🟦 修复 1：确保 openwrt-src 可写
      - name: Fix Permissions
        run: chmod -R 755 openwrt-src

      # 🟦 修复 2：删除可能存在的空 .config
      - name: Remove Pre-existing .config
        working-directory: openwrt-src
        run: rm -f .config

      # 🟦 修复 3：用绝对路径执行脚本，保证 pwd = openwrt-src
      - name: Run Three-Piece Script
        working-directory: openwrt-src
        run: |
          bash $GITHUB_WORKSPACE/sl3000-tools/generate-three-piece.sh

          # 立即验证 .config 是否生成
          if [ ! -s ".config" ]; then
            echo "❌ .config not generated after script"
            exit 1
          fi
          echo "✅ .config generated"

      - name: Strict Verify Three-Piece
        working-directory: openwrt-src
        run: |
          DTS_FILE="target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts"
          MK_FILE="target/linux/mediatek/image/filogic.mk"
          CFG_FILE=".config"

          [ -s "$DTS_FILE" ] || { echo "❌ DTS missing or empty"; exit 1; }
          [ -s "$MK_FILE" ]  || { echo "❌ MK missing or empty"; exit 1; }
          [ -s "$CFG_FILE" ] || { echo "❌ CONFIG missing or empty"; exit 1; }

          grep -q "CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_sl_3000-emmc=y" "$CFG_FILE" \
            || { echo "❌ CONFIG missing device enable"; exit 1; }

          grep -q "define Device/sl_3000-emmc" "$MK_FILE" \
            || { echo "❌ MK missing sl_3000-emmc segment"; exit 1; }

          echo "DTS_FILE=$DTS_FILE" >> $GITHUB_ENV
          echo "MK_FILE=$MK_FILE" >> $GITHUB_ENV
          echo "CFG_FILE=$CFG_FILE" >> $GITHUB_ENV

      - name: Upload Three-Piece & Logs
        uses: actions/upload-artifact@v4
        with:
          name: sl3000-three-piece-2410
          path: |
            openwrt-src/${{ env.DTS_FILE }}
            openwrt-src/${{ env.MK_FILE }}
            openwrt-src/${{ env.CFG_FILE }}
          retention-days: 30

      - name: Git Commit & Push
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

          cp openwrt-src/${{ env.DTS_FILE }} target/linux/mediatek/dts/
          cp openwrt-src/${{ env.MK_FILE }} target/linux/mediatek/image/
          cp openwrt-src/${{ env.CFG_FILE }} sl3000-tools/sl3000-full-config.txt

          git add -f target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts
          git add -f target/linux/mediatek/image/filogic.mk
          git add -f sl3000-tools/sl3000-full-config.txt

          git commit -m "ci: rebuild SL3000 three-piece (24.10 / mt7981)" || exit 0
          git push
