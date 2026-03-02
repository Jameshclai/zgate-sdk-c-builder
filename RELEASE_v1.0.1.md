# Release 1.0.1

**zgate-sdk-c-builder** 首個正式版本，提供從 [openziti/ziti-sdk-c](https://github.com/openziti/ziti-sdk-c) 與 [openziti/tlsuv](https://github.com/openziti/tlsuv) 自動取得原始碼、套用 ziti→zgate 品牌替換並編譯產出 **zgate-sdk-c-xx.xx.xx** 的完整流程。

---

## 主要功能

- **一鍵建置**：執行 `./build.sh` 即可完成環境檢查、取得最新 SDK/tlsuv、套用 patch、編譯與清理。
- **環境檢查與設定**：可自動安裝編譯依賴（build-essential、cmake、ninja、vcpkg 等），或設 `SKIP_ENV_CHECK=1` 略過。
- **固定版本**：透過 `ZITI_SDK_TAG` / `TLSUV_TAG` 指定 tag（如 `v1.11.1`）以鎖定版本。
- **產出整理**：`cleanup-output.sh` 移除建置暫存，縮小產出體積。

## 目錄與腳本

| 項目 | 說明 |
|------|------|
| `scripts/setup-build-env.sh` | 檢查/安裝編譯環境與 vcpkg |
| `scripts/fetch-latest.sh` | 取得最新 ziti-sdk-c、tlsuv 與版本變數 |
| `scripts/apply-patch.sh` | 複製並套用 ziti→zgate 重新命名與內容替換 |
| `scripts/build.sh` | 在產出目錄執行 CMake 編譯 |
| `scripts/cleanup-output.sh` | 清理產出目錄 |

## 需求

- Bash、Git、CMake、Ninja、vcpkg、C/C++ 編譯器（Ubuntu/Debian 下可由腳本協助安裝）。

## 版權

- **Copyright (c) eCloudseal Inc.  All rights reserved.**
- **作者：Lai Hou Chang (James Lai)** — 詳見 [COPYRIGHT](COPYRIGHT)。

---

**完整使用說明請見 [README](README.md)。**
