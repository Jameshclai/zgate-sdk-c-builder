#!/usr/bin/env bash
# zgate-sdk-c-builder - fetch, patch, and build zgate-sdk-c
# Copyright (c) eCloudseal Inc.  All rights reserved.  Author: Lai Hou Chang (James Lai)
set -euo pipefail
BUILDER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${BUILDER_ROOT}"

if [[ -f "${BUILDER_ROOT}/config.env" ]]; then
    set -a
    source "${BUILDER_ROOT}/config.env"
    set +a
fi
export OUTPUT_DIR="${OUTPUT_DIR:-${BUILDER_ROOT}/output}"

echo ""
echo "=============================================="
echo "  zgate-sdk-c-builder 建置流程（共 5 個步驟）"
echo "=============================================="
echo ""

echo "【步驟 1/5】檢查並準備建置環境與套件"
echo "  說明：確認 git、cmake、ninja、gcc、vcpkg 等已安裝；若缺少會詢問是否自動安裝。"
echo "----------------------------------------------------------------------"
"${BUILDER_ROOT}/scripts/setup-build-env.sh"
# Apply VCPKG_ROOT if setup script set it (e.g. after cloning vcpkg)
[[ -f "${BUILDER_ROOT}/.build-env.vcpkg" ]] && source "${BUILDER_ROOT}/.build-env.vcpkg"
echo "  ✓ 步驟 1 完成"
echo ""

echo "【步驟 2/5】取得最新 ziti-sdk-c 與 tlsuv 原始碼"
echo "  說明：從 GitHub 下載 openziti/ziti-sdk-c 與 openziti/tlsuv 的 release 並放入 work/ 目錄。"
echo "----------------------------------------------------------------------"
source "${BUILDER_ROOT}/scripts/fetch-latest.sh"
echo "  ✓ 步驟 2 完成"
echo ""

echo "【步驟 3/5】套用 zgate 品牌與程式調整（patch）"
echo "  說明：將 ziti-sdk-c 複製為 zgate-sdk-c，並進行重新命名與內容替換（ziti→zgate）。"
echo "----------------------------------------------------------------------"
"${BUILDER_ROOT}/scripts/apply-patch.sh"
echo "  ✓ 步驟 3 完成"
echo ""

echo "【步驟 4/5】編譯 zgate-sdk-c"
echo "  說明：使用 CMake 與 vcpkg 依賴進行編譯，產出程式庫與可執行檔（此步驟可能較久）。"
echo "----------------------------------------------------------------------"
"${BUILDER_ROOT}/scripts/build.sh"
echo "  ✓ 步驟 4 完成"
echo ""

echo "【步驟 5/5】清理不必要的建置暫存"
echo "  說明：刪除 vcpkg_installed、.cmake 等暫存以縮小產出目錄體積。"
echo "----------------------------------------------------------------------"
"${BUILDER_ROOT}/scripts/cleanup-output.sh"
echo "  ✓ 步驟 5 完成"
echo ""

# 產出目錄路徑
ZGATE_OUT="${ZGATE_OUT:-${OUTPUT_DIR}/zgate-sdk-c-${ZITI_SDK_VERSION}}"
BUILD_DIR="${ZGATE_OUT}/build"

echo "=============================================="
echo "  建置完成：成功編譯產出位置"
echo "=============================================="
echo ""
echo "  產出根目錄：${ZGATE_OUT}"
echo ""
echo "  主要編譯檔案位置："
echo "  ----------------------------------------------------------------------"
if [[ -d "${BUILD_DIR}" ]]; then
    # 程式庫（含 Release 等組態子目錄）
    if [[ -d "${BUILD_DIR}/library" ]]; then
        echo "  【程式庫】"
        find "${BUILD_DIR}/library" -type f \( -name "*.so" -o -name "*.a" \) 2>/dev/null | sort | while read -r f; do
            echo "    ${f}"
        done
    fi
    # 可執行檔（程式與範例）
    if [[ -d "${BUILD_DIR}/programs" ]]; then
        echo "  【可執行檔】"
        find "${BUILD_DIR}/programs" -type f -executable 2>/dev/null | sort | while read -r f; do
            echo "    ${f}"
        done
    fi
    # 測試程式
    if [[ -d "${BUILD_DIR}/tests" ]]; then
        echo "  【測試程式】"
        find "${BUILD_DIR}/tests" -type f -executable 2>/dev/null | sort | while read -r f; do
            echo "    ${f}"
        done
    fi
else
    echo "  （build 目錄不存在，請檢查前述步驟是否皆成功）"
fi
echo "  ----------------------------------------------------------------------"
echo ""
echo "  完整使用說明請見 README.md。"
echo ""
