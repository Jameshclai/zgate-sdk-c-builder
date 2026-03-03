# Release 1.0.3（正式版）

**zgate-sdk-c-builder** 1.0.3：建置流程步驟說明與編譯產出位置列表，強化環境與 vcpkg 相容性，並支援 MinGW/Windows 交叉編譯與 tlsuv C89 相容 patch。

---

## 變更摘要（相對於 1.0.2）

### 建置流程說明（build.sh）
- **步驟標示**：每個步驟以「【步驟 N/5】」與繁體中文說明呈現，安裝者可清楚知道目前進度與該步驟用途。
- **完成提示**：每步結束後顯示「✓ 步驟 N 完成」。
- **編譯產出列表**：建置成功後自動列出「成功編譯產出位置」，包含：
  - 產出根目錄路徑
  - 【程式庫】所有 `.so`、`.a` 檔案路徑
  - 【可執行檔】programs 下所有可執行檔路徑
  - 【測試程式】tests 下所有可執行檔路徑

### apply-patch：MinGW/Windows 相容性（1.0.3 後續更新）
- **MinGW 標頭檔名**：Windows 下 MinGW 使用小寫標頭檔名，腳本對 `LMAPIbuf.h`、`VersionHelpers.h`、`WinSock2.h` 加入 `#if defined(__MINGW32__)` 條件編譯，分別改用 `lmapibuf.h`、`versionhelpers.h`、`winsock2.h`。
- **zgate_log.h 巨集衝突**：在 `DEBUG_LEVELS(XX)` 前加入 `#ifdef _WIN32` 區塊，對 `ERROR`、`DEBUG`、`INFO`、`WARN`、`TRACE`、`VERBOSE` 執行 `#undef`，避免與 Windows 系統標頭巨集衝突。
- **CMake MinGW 視為 WIN32**：`library/CMakeLists.txt` 與 tlsuv 的 CMake 在 `WIN32` 判斷外一併檢查 `CMAKE_C_COMPILER MATCHES "mingw32"`，使 MinGW 交叉編譯時正確連結 netapi32、crypt32、ncrypt 等並使用 win32 keychain。
- **tlsuv C89 相容**：新增 `patches/tlsuv-keys-c89.patch`，於 apply-patch 階段自動套用，解決 MinGW 等編譯器在 C89 模式下於區塊中宣告變數的相容問題（如 `privkey_store_cert` 的 `subj_name` 等）。

### 環境與 vcpkg（1.0.2 後累積）
- **zip / unzip / tar**：納入必備套件與 apt 安裝清單，滿足 vcpkg bootstrap 需求。
- **autoconf、automake、libtool、libssl-dev**：一併納入建議安裝，供 vcpkg 編譯 libsodium 與 tlsuv 使用 OpenSSL。
- **vcpkg 完整歷史**：若 vcpkg 為 shallow clone，環境檢查時自動執行 `git fetch --unshallow`，避免「failed to git show versions/baseline.json」錯誤。
- **README 故障排除**：新增「vcpkg install failed」一節，說明手動 unshallow、安裝依賴與重跑建置的步驟。

## 主要功能

- **一鍵建置**：執行 `./build.sh` 完成環境檢查、取得最新 SDK/tlsuv、套用 patch、編譯與清理。
- **流程可讀**：五個步驟各有編號與說明，建置完成後列出所有編譯產出檔案位置。
- **環境檢查與設定**：可自動安裝編譯依賴（含 zip、unzip、tar、autoconf、libtool、libssl-dev）或自動 clone/bootstrap vcpkg；vcpkg 若為淺層 clone 會自動補齊歷史。
- **固定版本**：透過 `ZITI_SDK_TAG` / `TLSUV_TAG` 指定 tag 以鎖定版本。
- **產出整理**：`cleanup-output.sh` 移除建置暫存，縮小產出體積。

## 需求

- Bash、Git、CMake、Ninja、vcpkg、C/C++ 編譯器（Ubuntu/Debian 下可由腳本協助安裝，含 zip、unzip、tar、autoconf、libtool、libssl-dev 等）。

## 版權

- **Copyright (c) eCloudseal Inc.  All rights reserved.**
- **作者：Lai Hou Chang (James Lai)** — 詳見 [COPYRIGHT](COPYRIGHT)。

---

**完整使用說明請見 [README](README.md)。**
