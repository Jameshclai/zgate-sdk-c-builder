#!/usr/bin/env bash
# Single entry: fetch latest ziti-sdk-c + tlsuv -> apply zgate patch -> build.
set -euo pipefail
BUILDER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${BUILDER_ROOT}"

if [[ -f "${BUILDER_ROOT}/config.env" ]]; then
    set -a
    source "${BUILDER_ROOT}/config.env"
    set +a
fi

echo "==> Step 1: Fetch latest ziti-sdk-c and tlsuv"
source "${BUILDER_ROOT}/scripts/fetch-latest.sh"

echo "==> Step 2: Apply zgate patch"
"${BUILDER_ROOT}/scripts/apply-patch.sh"

echo "==> Step 3: Build zgate-sdk-c"
"${BUILDER_ROOT}/scripts/build.sh"

echo "==> All done. Output: ${ZGATE_OUT:-${OUTPUT_DIR:-.}/zgate-sdk-c-${ZITI_SDK_VERSION}}"
