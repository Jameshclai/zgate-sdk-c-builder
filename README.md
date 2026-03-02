# zgate-sdk-c-builder

自動從 [openziti/ziti-sdk-c](https://github.com/openziti/ziti-sdk-c) 與 [openziti/tlsuv](https://github.com/openziti/tlsuv) 取得最新版本、套用 ziti→zgate 品牌替換並編譯產出 **zgate-sdk-c-xx.xx.xx**。

## 需求

- Bash、Git、CMake、Ninja、C/C++ 編譯器
- [vcpkg](https://vcpkg.io/)（用於 ci-linux-x64 preset 的依賴：libsodium、libprotobuf-c、json-c、stc、OpenSSL 等）
- 可選：`jq`（用於解析 GitHub API，否則用 grep 取得最新 tag）

## 使用方式

### 一鍵執行（建議）

```bash
./build.sh
```

會依序執行：

1. **fetch-latest.sh**：以 GitHub Releases API 取得兩 repo 最新 release tag，並 `git clone` 到 `work/`
2. **apply-patch.sh**：將 ziti-sdk-c 複製到 `zgate-sdk-c-<version>` 並套用重新命名、內容替換與 CMake 調整，並使用本次下載的 tlsuv 路徑
3. **build.sh**：在產出目錄執行 `cmake --preset ci-linux-x64` 與 `cmake --build build --config Release`

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
| `OUTPUT_DIR` | 產出目錄的父目錄（產出為 `OUTPUT_DIR/zgate-sdk-c-xx.xx.xx`） | `/home/user` |
| `ZITI_SDK_TAG` / `TLSUV_TAG` | 固定版本時指定 tag（如 `v1.11.1`） | 不設則用最新 release |

## 目錄結構

```
zgate-sdk-c-builder/
├── .git/
├── .gitignore
├── README.md
├── config.env.example
├── build.sh                 # 單一入口
├── scripts/
│   ├── fetch-latest.sh      # 取得並下載最新（或指定）版本
│   ├── apply-patch.sh       # 套用 zgate patch
│   └── build.sh             # 編譯 zgate-sdk-c
└── patch/                   # 可選，供日後 patch 檔使用
```

`work/`、產出的 `zgate-sdk-c-*/` 與 `*.log` 等由 `.gitignore` 排除，不納入版控。

## 版控

專案已初始化 Git，僅對 builder 本身做版控；下載的 ziti-sdk-c / tlsuv 與編譯產出目錄不納入。
