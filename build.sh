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

echo "==> Step 1: Ensure build environment and packages are ready"
"${BUILDER_ROOT}/scripts/setup-build-env.sh"
# Apply VCPKG_ROOT if setup script set it (e.g. after cloning vcpkg)
[[ -f "${BUILDER_ROOT}/.build-env.vcpkg" ]] && source "${BUILDER_ROOT}/.build-env.vcpkg"

echo "==> Step 2: Fetch latest ziti-sdk-c and tlsuv"
source "${BUILDER_ROOT}/scripts/fetch-latest.sh"

echo "==> Step 3: Apply zgate patch"
"${BUILDER_ROOT}/scripts/apply-patch.sh"

echo "==> Step 4: Build zgate-sdk-c"
"${BUILDER_ROOT}/scripts/build.sh"

echo "==> Step 5: Cleanup unnecessary files"
"${BUILDER_ROOT}/scripts/cleanup-output.sh"

echo "==> All done. Output: ${ZGATE_OUT:-${OUTPUT_DIR:-.}/zgate-sdk-c-${ZITI_SDK_VERSION}}"
