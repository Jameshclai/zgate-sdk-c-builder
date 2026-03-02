#!/usr/bin/env bash
# Ensure build environment and required packages are installed (for fresh Ubuntu).
# Copyright (c) eCloudseal Inc.  All rights reserved.  Author: Lai Hou Chang (James Lai)
# Will prompt for sudo password if packages need to be installed.
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

echo "==> Checking build environment..."

# Required commands for fetch + patch + build
REQUIRED=(
    git
    curl
    cmake
    ninja
    gcc
    g++
    pkg-config
    zip
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
    echo "    Missing required: ${MISSING[*]}"
    echo ""
    echo "To install on Ubuntu/Debian, run (will ask for sudo password):"
    echo "  sudo apt-get update"
    echo "  sudo apt-get install -y build-essential cmake ninja-build git curl pkg-config zip"
    echo ""
    read -r -p "Install missing packages now? [y/N] " ans
    if [[ "${ans,,}" = "y" || "${ans,,}" = "yes" ]]; then
        # Prompt for sudo password once and validate
        echo "Checking sudo access (you may be asked for your password)..."
        if ! sudo -v; then
            echo "Error: sudo access failed. Install packages manually and re-run." >&2
            exit 1
        fi
        sudo apt-get update
        sudo apt-get install -y build-essential cmake ninja-build git curl pkg-config zip
        if ! command -v jq &>/dev/null; then
            read -r -p "Install optional jq for GitHub API? [y/N] " jq_ans
            if [[ "${jq_ans,,}" = "y" || "${jq_ans,,}" = "yes" ]]; then
                sudo apt-get install -y jq
            fi
        fi
        echo "    Packages installed."
    else
        echo "Please install the missing packages and run build.sh again." >&2
        exit 1
    fi
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

echo "    Build tools: OK (git, curl, cmake, ninja, gcc, g++, pkg-config, zip)"

# Check vcpkg (required for ci-linux-x64 preset)
VCPKG_ROOT="${VCPKG_ROOT:-}"
if [[ -z "${VCPKG_ROOT}" ]]; then
    # Default path when not set
    VCPKG_ROOT="${HOME}/vcpkg"
fi
if [[ ! -d "${VCPKG_ROOT}" ]] || [[ ! -x "${VCPKG_ROOT}/vcpkg" ]]; then
    echo "    vcpkg not found at ${VCPKG_ROOT}"
    echo ""
    echo "vcpkg is required for dependency management. Options:"
    echo "  1) Clone and bootstrap vcpkg to ${VCPKG_ROOT} (no sudo)"
    echo "  2) Set VCPKG_ROOT in config.env to your existing vcpkg path"
    echo "  3) Exit and install vcpkg manually"
    echo ""
    read -r -p "Clone and bootstrap vcpkg to ${VCPKG_ROOT} now? [y/N] " ans
    if [[ "${ans,,}" = "y" || "${ans,,}" = "yes" ]]; then
        mkdir -p "$(dirname "${VCPKG_ROOT}")"
        if [[ -d "${VCPKG_ROOT}/.git" ]]; then
            echo "    vcpkg directory exists; bootstrapping..."
            (cd "${VCPKG_ROOT}" && ./bootstrap-vcpkg.sh -disableMetrics)
        else
            echo "    Cloning vcpkg..."
            git clone --depth 1 https://github.com/microsoft/vcpkg.git "${VCPKG_ROOT}"
            (cd "${VCPKG_ROOT}" && ./bootstrap-vcpkg.sh -disableMetrics)
        fi
        echo "    vcpkg ready at ${VCPKG_ROOT}"
        echo "    Consider adding to config.env: export VCPKG_ROOT=${VCPKG_ROOT}"
    else
        echo "Error: vcpkg is required. Set VCPKG_ROOT in config.env or install vcpkg, then re-run." >&2
        exit 1
    fi
else
    echo "    vcpkg: OK (${VCPKG_ROOT})"
fi

# Write VCPKG_ROOT so parent build.sh can source it (needed when we just cloned vcpkg)
export VCPKG_ROOT
printf 'export VCPKG_ROOT=%q\n' "${VCPKG_ROOT}" > "${BUILDER_ROOT}/.build-env.vcpkg"

echo "==> Build environment ready."
