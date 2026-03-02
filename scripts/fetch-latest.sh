#!/usr/bin/env bash
# Fetch latest (or pinned) ziti-sdk-c and tlsuv from GitHub, clone to WORK_DIR.
# Copyright (c) eCloudseal Inc.  All rights reserved.  Author: Lai Hou Chang (James Lai)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILDER_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Load config
if [[ -f "${BUILDER_ROOT}/config.env" ]]; then
    set -a
    source "${BUILDER_ROOT}/config.env"
    set +a
fi
export WORK_DIR="${WORK_DIR:-${BUILDER_ROOT}/work}"
mkdir -p "${WORK_DIR}"
cd "${WORK_DIR}"

# GitHub API helper: get latest release tag_name (or use override)
get_latest_tag() {
    local repo="$1"
    local override_var="$2"
    if [[ -n "${!override_var:-}" ]]; then
        echo "${!override_var}"
        return
    fi
    local url="https://api.github.com/repos/${repo}/releases/latest"
    if command -v jq &>/dev/null; then
        curl -sSfL "${url}" | jq -r '.tag_name'
    else
        curl -sSfL "${url}" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1
    fi
}

# Normalize version: v1.11.1 -> 1.11.1
norm_ver() {
    local v="$1"
    echo "${v#v}"
}

echo "==> Fetching latest release tags..."
ZITI_TAG="${ZITI_SDK_TAG:-$(get_latest_tag "openziti/ziti-sdk-c" "ZITI_SDK_TAG")}"
TLSUV_TAG="${TLSUV_TAG:-$(get_latest_tag "openziti/tlsuv" "TLSUV_TAG")}"
ZITI_VER="$(norm_ver "$ZITI_TAG")"
TLSUV_VER="$(norm_ver "$TLSUV_TAG")"
echo "    ziti-sdk-c: ${ZITI_TAG} (version ${ZITI_VER})"
echo "    tlsuv:      ${TLSUV_TAG} (version ${TLSUV_VER})"

ZITI_SRC="${WORK_DIR}/ziti-sdk-c-${ZITI_VER}"
TLSUV_SRC="${WORK_DIR}/tlsuv-${TLSUV_VER}"

if [[ -d "${ZITI_SRC}/.git" ]]; then
    echo "==> ziti-sdk-c-${ZITI_VER} already cloned, skipping."
else
    echo "==> Cloning openziti/ziti-sdk-c @ ${ZITI_TAG}..."
    rm -rf "${ZITI_SRC}"
    git clone --depth 1 --branch "${ZITI_TAG}" \
        https://github.com/openziti/ziti-sdk-c.git "${ZITI_SRC}"
fi

if [[ -d "${TLSUV_SRC}/.git" ]]; then
    echo "==> tlsuv-${TLSUV_VER} already cloned, skipping."
else
    echo "==> Cloning openziti/tlsuv @ ${TLSUV_TAG}..."
    rm -rf "${TLSUV_SRC}"
    git clone --depth 1 --branch "${TLSUV_TAG}" \
        https://github.com/openziti/tlsuv.git "${TLSUV_SRC}"
fi
# Ensure tlsuv working tree is populated (clone can leave it empty on some setups)
if [[ -d "${TLSUV_SRC}/.git" ]] && [[ ! -f "${TLSUV_SRC}/CMakeLists.txt" ]]; then
    (cd "${TLSUV_SRC}" && git checkout HEAD -- . 2>/dev/null || true)
fi

# Export for downstream scripts
export ZITI_SDK_VERSION="${ZITI_VER}"
export ZITI_SDK_TAG="${ZITI_TAG}"
export ZITI_SRC
export TLSUV_VERSION="${TLSUV_VER}"
export TLSUV_TAG="${TLSUV_TAG}"
export TLSUV_SRC
echo "==> Done. ZITI_SRC=${ZITI_SRC} TLSUV_SRC=${TLSUV_SRC}"
