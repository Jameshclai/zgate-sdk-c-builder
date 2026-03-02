#!/usr/bin/env bash
# Remove unnecessary files from the built output (zgate-sdk-c-xx.xx.xx) to reduce size.
# Copyright (c) eCloudseal Inc.  All rights reserved.  Author: Lai Hou Chang (James Lai)
# Keeps: built libs/executables, headers, CMake config; removes: vcpkg_installed, CMake cache, etc.
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
        echo "Error: ZGATE_OUT or (OUTPUT_DIR + ZITI_SDK_VERSION) must be set." >&2
        exit 1
    fi
    ZGATE_OUT="${OUTPUT_DIR}/zgate-sdk-c-${ZITI_SDK_VERSION}"
fi
if [[ ! -d "${ZGATE_OUT}" ]]; then
    echo "Warning: Output directory not found, skip cleanup: ${ZGATE_OUT}" >&2
    exit 0
fi

# Skip cleanup if SKIP_CLEANUP=1 (e.g. for development)
[[ "${SKIP_CLEANUP:-0}" = "1" ]] && exit 0

echo "==> Cleaning unnecessary files in ${ZGATE_OUT}"
BUILD_DIR="${ZGATE_OUT}/build"

# Remove vcpkg dependency tree (large; not needed to run built binaries)
if [[ -d "${BUILD_DIR}/vcpkg_installed" ]]; then
    rm -rf "${BUILD_DIR}/vcpkg_installed"
    echo "    removed build/vcpkg_installed"
fi

# Remove CMake API cache (can be regenerated on reconfigure)
if [[ -d "${BUILD_DIR}/.cmake" ]]; then
    rm -rf "${BUILD_DIR}/.cmake"
    echo "    removed build/.cmake"
fi

echo "==> Cleanup done."
