# Release 1.0.4

**zgate-sdk-c-builder** 1.0.4：tlsuv keys.c C89 自動修正、patch 與 SUDO_PASS 保留。

---

## 變更摘要（相對於 1.0.3）

- **fix-tlsuv-keys-c89.py**：新增自動修正腳本，僅在 `privkey_store_cert` 內插入宣告區塊，避免誤改 `privkey_get_cert`；適用任意 tlsuv 版本。
- **patches/tlsuv-keys-c89-0.40.13.patch**：tlsuv 0.40.13 專用 C89 patch。
- **apply-patch.sh**：先嘗試 0.40.13 / 0.40.12 patch，再一律執行 `fix-tlsuv-keys-c89.py`，確保 keys.c 通過 MinGW 等 C89 編譯。
- **build.sh**：保留呼叫端傳入的 `SUDO_PASS`（例如 Telegram Bot 詢問的密碼），不被 config.env 覆寫。
- **.gitignore**：新增 `__pycache__/`、`*.pyc`。

## 主要功能（延續）

- **一鍵建置**：執行 `./build.sh` 完成環境檢查、取得最新 SDK/tlsuv、套用 patch（含 C89 自動修正）、編譯與清理。
- **C89 相容**：tlsuv keys.c 中段宣告改為函數開頭宣告，避免 MinGW 等編譯器報錯。

---

**完整使用說明請見 [README](README.md)。**
