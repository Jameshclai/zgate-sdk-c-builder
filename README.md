# zgate-sdk-c-builder

自動從 [openziti/ziti-sdk-c](https://github.com/openziti/ziti-sdk-c) 與 [openziti/tlsuv](https://github.com/openziti/tlsuv) 取得最新版本、套用 ziti→zgate 品牌替換並編譯產出 **zgate-sdk-c-xx.xx.xx**。

**Copyright (c) eCloudseal Inc.  All rights reserved.**  
**Author: Lai Hou Chang (James Lai)** — 詳見 [COPYRIGHT](COPYRIGHT)。

## 需求

- **Ubuntu/Debian**：執行 `./build.sh` 時會先檢查編譯環境；若為全新安裝，腳本會詢問 sudo 密碼並安裝必要套件（build-essential、cmake、ninja-build、git、curl、pkg-config），並可選擇自動 clone/bootstrap [vcpkg](https://vcpkg.io/)。
- 若已具備環境，可設 `SKIP_ENV_CHECK=1` 略過檢查。
- 可選：`jq`（用於解析 GitHub API，否則用 grep 取得最新 tag）

## 使用方式

### 一鍵執行（建議）

```bash
./build.sh
```

會依序執行：

1. **setup-build-env.sh**：檢查編譯環境（git、curl、cmake、ninja、gcc、g++、pkg-config、vcpkg）；若缺少則詢問是否以 sudo 安裝套件，或自動 clone/bootstrap vcpkg
2. **fetch-latest.sh**：以 GitHub Releases API 取得兩 repo 最新 release tag，並 `git clone` 到 `work/`
3. **apply-patch.sh**：將 ziti-sdk-c 複製到 `zgate-sdk-c-<version>` 並套用重新命名、內容替換與 CMake 調整，並使用本次下載的 tlsuv 路徑
4. **build.sh**：在產出目錄執行 `cmake --preset ci-linux-x64` 與 `cmake --build build --config Release`
5. **cleanup-output.sh**：刪除產出目錄中不必要的檔案（如 `build/vcpkg_installed`、`build/.cmake`），縮小體積

### 分步執行

```bash
source scripts/fetch-latest.sh   # 匯出 ZITI_SRC, TLSUV_SRC, ZITI_SDK_VERSION 等
scripts/apply-patch.sh
scripts/build.sh
```

### 固定版本

在 `config.env` 或環境變數中設定：

```bash
export ZITI_SDK_TAG="v1.11.1"
export TLSUV_TAG="v0.40.12"
```

再執行 `./build.sh` 或上述分步指令。

## 設定

可複製 `config.env.example` 為 `config.env` 並依環境調整：

| 變數 | 說明 | 預設 |
|------|------|------|
| `VCPKG_ROOT` | vcpkg 根目錄 | 環境既有值或 `/home/user/vcpkg` |
| `WORK_DIR` | 下載與暫存目錄（ziti-sdk-c、tlsuv） | `./work` |
| `OUTPUT_DIR` | 產出目錄的父目錄（產出為 `OUTPUT_DIR/zgate-sdk-c-xx.xx.xx`） | `./output` |
| `ZITI_SDK_TAG` / `TLSUV_TAG` | 固定版本時指定 tag（如 `v1.11.1`） | 不設則用最新 release |
| `SKIP_CLEANUP` | 設為 `1` 時略過產出目錄清理（保留 vcpkg_installed 等） | 不設則執行清理 |
| `SKIP_ENV_CHECK` | 設為 `1` 時略過編譯環境檢查（已確認環境時使用） | 不設則執行檢查 |

## 目錄結構

```
zgate-sdk-c-builder/
├── .git/
├── .gitignore
├── COPYRIGHT                # 版權與法律聲明 (eCloudseal Inc.)
├── README.md
├── config.env.example
├── build.sh                 # 單一入口
├── scripts/
│   ├── setup-build-env.sh   # 檢查/安裝編譯環境與套件（含 sudo 詢問）
│   ├── fetch-latest.sh      # 取得並下載最新（或指定）版本
│   ├── apply-patch.sh       # 套用 zgate patch
│   ├── build.sh             # 編譯 zgate-sdk-c
│   └── cleanup-output.sh   # 產出後刪除不必要的檔案
└── output/                  # 產出目錄（zgate-sdk-c-xx.xx.xx）
```

`work/`、`output/`、產出的 `zgate-sdk-c-*/` 與 `*.log` 等由 `.gitignore` 排除，不納入版控。

## 版控

專案已初始化 Git，僅對 builder 本身做版控；下載的 ziti-sdk-c / tlsuv 與編譯產出目錄不納入。

---

## 版權聲明

- **Copyright (c) eCloudseal Inc.  All rights reserved.**
- **作者 (Author): Lai Hou Chang (James Lai)**
- 完整版權與法律聲明請見 [COPYRIGHT](COPYRIGHT)。
