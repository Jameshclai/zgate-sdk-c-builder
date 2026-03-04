#!/usr/bin/env bash
# Ensure build environment and required packages are installed (for fresh Ubuntu).
# Copyright (c) eCloudseal Inc.  All rights reserved.  Author: Lai Hou Chang (James Lai)
# 缺少套件時自動安裝（不詢問）；若設定 SUDO_PASS 則以 sudo -S 非互動執行，未設定時仍會詢問 sudo 密碼。
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILDER_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ -f "${BUILDER_ROOT}/config.env" ]]; then
    set -a
    source "${BUILDER_ROOT}/config.env"
    set +a
fi

# Skip entire check if SKIP_ENV_CHECK=1
[[ "${SKIP_ENV_CHECK:-0}" = "1" ]] && { echo "==> Skipping build env check (SKIP_ENV_CHECK=1)"; exit 0; }

# 非互動模式：若有 SUDO_PASS 則用 sudo -S 執行後續 sudo 指令（一鍵建置不詢問）
sudo_cmd() {
    if [[ -n "${SUDO_PASS:-}" ]]; then
        echo "${SUDO_PASS}" | sudo -S -p "" "$@"
    else
        sudo "$@"
    fi
}

echo "==> Checking build environment..."

# Required commands for fetch + patch + build (zip/unzip/tar needed by vcpkg bootstrap)
REQUIRED=(
    git
    curl
    cmake
    ninja
    gcc
    g++
    pkg-config
    zip
    unzip
    tar
)
# Optional (improve experience)
OPTIONAL=(jq)

MISSING=()
for cmd in "${REQUIRED[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
        MISSING+=("$cmd")
    fi
done

for cmd in "${OPTIONAL[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "    (optional) $cmd not found"
    fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo "    Missing required: ${MISSING[*]} — 自動安裝中（不詢問）..."
    echo "Checking sudo access..."
    if ! sudo_cmd -v 2>/dev/null; then
        echo "Error: sudo access failed. Set SUDO_PASS in config.env or run with sudo, then re-run." >&2
        exit 1
    fi
    sudo_cmd apt-get update -qq
    sudo_cmd apt-get install -y build-essential cmake ninja-build git curl pkg-config zip unzip tar autoconf automake libtool libssl-dev
    if ! command -v jq &>/dev/null; then
        sudo_cmd apt-get install -y jq
    fi
    echo "    Packages installed."
fi

# Re-check after possible install
MISSING=()
for cmd in "${REQUIRED[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
        MISSING+=("$cmd")
    fi
done
if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo "Error: Still missing: ${MISSING[*]}. Install them and re-run." >&2
    exit 1
fi

echo "    Build tools: OK (git, curl, cmake, ninja, gcc, g++, pkg-config, zip, unzip, tar)"

# Check vcpkg (required for ci-linux-x64 preset)
VCPKG_ROOT="${VCPKG_ROOT:-}"
if [[ -z "${VCPKG_ROOT}" ]]; then
    # Default path when not set
    VCPKG_ROOT="${HOME}/vcpkg"
fi
if [[ ! -d "${VCPKG_ROOT}" ]] || [[ ! -x "${VCPKG_ROOT}/vcpkg" ]]; then
    echo "    vcpkg not found at ${VCPKG_ROOT} — 自動 clone 並 bootstrap（不詢問）..."
    mkdir -p "$(dirname "${VCPKG_ROOT}")"
    if [[ -d "${VCPKG_ROOT}/.git" ]]; then
        echo "    vcpkg directory exists; bootstrapping..."
        (cd "${VCPKG_ROOT}" && ./bootstrap-vcpkg.sh -disableMetrics)
    else
        echo "    Cloning vcpkg..."
        git clone --depth 1 https://github.com/microsoft/vcpkg.git "${VCPKG_ROOT}"
        (cd "${VCPKG_ROOT}" && ./bootstrap-vcpkg.sh -disableMetrics)
    fi
    # Fetch full history so vcpkg baseline (versions/baseline.json) resolves correctly
    if (cd "${VCPKG_ROOT}" && git rev-parse --is-shallow-repository 2>/dev/null) | grep -q true; then
        echo "    Fetching vcpkg full history (for baseline)..."
        (cd "${VCPKG_ROOT}" && git fetch --unshallow)
    fi
    echo "    vcpkg ready at ${VCPKG_ROOT}"
else
    echo "    vcpkg: OK (${VCPKG_ROOT})"
    # Ensure full history so vcpkg baseline resolves (avoids "failed to git show versions/baseline.json")
    if (cd "${VCPKG_ROOT}" && git rev-parse --is-shallow-repository 2>/dev/null) | grep -q true; then
        echo "    Fetching vcpkg full history (for baseline)..."
        (cd "${VCPKG_ROOT}" && git fetch --unshallow)
    fi
fi

# Write VCPKG_ROOT so parent build.sh can source it (needed when we just cloned vcpkg)
export VCPKG_ROOT
printf 'export VCPKG_ROOT=%q\n' "${VCPKG_ROOT}" > "${BUILDER_ROOT}/.build-env.vcpkg"

echo "==> Build environment ready."
