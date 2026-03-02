#!/usr/bin/env bash
# Configure and build zgate-sdk-c in ZGATE_OUT using local tlsuv.
# Expects: ZGATE_OUT (or OUTPUT_DIR + ZITI_SDK_VERSION), TLSUV_SRC (optional), VCPKG_ROOT (optional)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILDER_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ -f "${BUILDER_ROOT}/config.env" ]]; then
    set -a
    source "${BUILDER_ROOT}/config.env"
    set +a
fi

if [[ -z "${ZGATE_OUT:-}" ]]; then
    if [[ -z "${OUTPUT_DIR:-}" ]] || [[ -z "${ZITI_SDK_VERSION:-}" ]]; then
        echo "Error: ZGATE_OUT or (OUTPUT_DIR + ZITI_SDK_VERSION) must be set (run apply-patch.sh after fetch-latest.sh)." >&2
        exit 1
    fi
    ZGATE_OUT="${OUTPUT_DIR}/zgate-sdk-c-${ZITI_SDK_VERSION}"
fi
if [[ ! -d "${ZGATE_OUT}" ]]; then
    echo "Error: ZGATE_OUT directory not found: ${ZGATE_OUT}" >&2
    exit 1
fi

PRESET="${CMAKE_PRESET:-ci-linux-x64}"
BUILD_DIR="${ZGATE_OUT}/build"

echo "==> Building ${ZGATE_OUT} (preset=${PRESET})"
cd "${ZGATE_OUT}"

# Pass tlsuv_DIR so CMake uses local tlsuv (from fetch)
CMAKE_EXTRA=()
if [[ -n "${TLSUV_SRC:-}" ]] && [[ -d "${TLSUV_SRC}" ]]; then
    CMAKE_EXTRA+=(-Dtlsuv_DIR="${TLSUV_SRC}")
    echo "    tlsuv_DIR=${TLSUV_SRC}"
fi
if [[ -n "${VCPKG_ROOT:-}" ]] && [[ -d "${VCPKG_ROOT}" ]]; then
    export VCPKG_ROOT
    echo "    VCPKG_ROOT=${VCPKG_ROOT}"
fi

cmake --preset "${PRESET}" "${CMAKE_EXTRA[@]}"
cmake --build build --config Release

echo "==> Build complete. Output: ${BUILD_DIR}"
