# Release 1.0.2

**zgate-sdk-c-builder** 1.0.2：環境檢查與 apt 安裝清單加入 **zip** 套件，便於建置與產物打包。

---

## 變更摘要（相對於 1.0.1）

- **預裝 zip**：`scripts/setup-build-env.sh` 將 `zip` 列入必備指令與 apt 安裝清單；若缺少會一併安裝，無需手動 `apt install zip`。

## 主要功能（同 1.0.1）

- **一鍵建置**：執行 `./build.sh` 完成環境檢查、取得最新 SDK/tlsuv、套用 patch、編譯與清理。
- **環境檢查與設定**：可自動安裝編譯依賴（含 zip）或自動 clone/bootstrap vcpkg，或設 `SKIP_ENV_CHECK=1` 略過。
- **固定版本**：透過 `ZITI_SDK_TAG` / `TLSUV_TAG` 指定 tag 以鎖定版本。
- **產出整理**：`cleanup-output.sh` 移除建置暫存，縮小產出體積。

## 需求

- Bash、Git、CMake、Ninja、vcpkg、C/C++ 編譯器（Ubuntu/Debian 下可由腳本協助安裝，含 zip）。

## 版權

- **Copyright (c) eCloudseal Inc.  All rights reserved.**
- **作者：Lai Hou Chang (James Lai)** — 詳見 [COPYRIGHT](COPYRIGHT)。

---

**完整使用說明請見 [README](README.md)。**
