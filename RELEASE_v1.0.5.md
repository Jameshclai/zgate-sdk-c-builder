# Release 1.0.5

**zgate-sdk-c-builder** 1.0.5：正式記錄 tlsuv **keys.c** C89 相容修正。

---

## 變更摘要（相對於 1.0.4）

本版於文件中明確記錄 **tlsuv `src/openssl/keys.c`** 的編譯修正內容，確保建置流程與修正方式可追溯。

### keys.c 修正內容

- **問題**：tlsuv 的 `keys.c` 在 `privkey_store_cert()` 內於程式區塊**中段**宣告變數（如 `X509_NAME *subj_name = X509_get_subject_name(c);`、`int subjlen = i2d_X509_NAME(subj_name, &subj_der);` 等）。在 **C89** 模式下，變數須於區塊開頭宣告，MinGW 等編譯器會報錯：`'subj_name' undeclared` 或類似未宣告符號。
- **作法**：
  1. **patches**：`patches/tlsuv-keys-c89.patch`、`patches/tlsuv-keys-c89-0.40.13.patch` 將 `store`、`objects`、`obj`、`c`、`subj_der`、`subjlen`、`der`、`derlen`、`rc` 等變數改為在函數開頭宣告，中段僅保留賦值（例如 `subjlen = i2d_X509_NAME(X509_get_subject_name(c), &subj_der);`）。
  2. **fix-tlsuv-keys-c89.py**：建置流程中若 patch 未完全套用或 tlsuv 版本變更，一律再執行此腳本，對 `keys.c` 做相同 C89 相容改寫，避免編譯錯誤。
  3. **apply-patch.sh**：先嘗試套用上述 patch，再對 `work/tlsuv-*/src/openssl/keys.c` 執行 `fix-tlsuv-keys-c89.py`，確保 keys.c 通過 MinGW 與各 C89 編譯環境。

### 相關檔案

| 項目 | 說明 |
|------|------|
| `patches/tlsuv-keys-c89-0.40.13.patch` | tlsuv 0.40.13 專用 keys.c C89 patch |
| `patches/tlsuv-keys-c89.patch` | 通用 keys.c C89 patch |
| `scripts/fix-tlsuv-keys-c89.py` | 自動將 `privkey_store_cert` 內中段宣告改為函數開頭宣告 |
| `scripts/apply-patch.sh` | 套用 patch 並呼叫 fix-tlsuv-keys-c89.py |

## 主要功能（延續）

- **一鍵建置**：執行 `./build.sh` 完成環境檢查、取得最新 SDK/tlsuv、套用 patch（含 keys.c C89 修正）、編譯與清理。
- **C89 相容**：tlsuv keys.c 修正已納入建置流程，避免 MinGW 等編譯器報錯。

---

**完整使用說明請見 [README](README.md)。**
