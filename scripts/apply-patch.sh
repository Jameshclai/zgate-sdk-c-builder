#!/usr/bin/env bash
# Copy ziti-sdk-c to zgate-sdk-c-{version}, apply renames and content replacement.
# Expects: ZITI_SRC, TLSUV_SRC, ZITI_SDK_VERSION, OUTPUT_DIR (from fetch-latest or env)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILDER_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ -f "${BUILDER_ROOT}/config.env" ]]; then
    set -a
    source "${BUILDER_ROOT}/config.env"
    set +a
fi
OUTPUT_DIR="${OUTPUT_DIR:-/home/user}"
if [[ -z "${ZITI_SRC:-}" ]] || [[ -z "${ZITI_SDK_VERSION:-}" ]]; then
    echo "Error: ZITI_SRC and ZITI_SDK_VERSION must be set (run fetch-latest.sh first or source it)." >&2
    exit 1
fi
TLSUV_SRC="${TLSUV_SRC:-}"
VER="${ZITI_SDK_VERSION}"
OUT="${OUTPUT_DIR}/zgate-sdk-c-${VER}"
echo "==> Applying patch: ${ZITI_SRC} -> ${OUT}"

rm -rf "${OUT}"
cp -a "${ZITI_SRC}" "${OUT}"
rm -rf "${OUT}/.git" "${OUT}/.github" 2>/dev/null || true

# ---- Directory renames ----
mv "${OUT}/includes/ziti" "${OUT}/includes/zgate" 2>/dev/null || true
mv "${OUT}/programs/ziti-prox-c" "${OUT}/programs/zgate-prox-c" 2>/dev/null || true
mv "${OUT}/programs/zitilib-samples" "${OUT}/programs/zgatelib-samples" 2>/dev/null || true

# ---- Library source renames ----
[[ -f "${OUT}/library/ziti.c" ]] && mv "${OUT}/library/ziti.c" "${OUT}/library/zgate.c"
[[ -f "${OUT}/library/zitilib.c" ]] && mv "${OUT}/library/zitilib.c" "${OUT}/library/zgatelib.c"
[[ -f "${OUT}/library/ziti_ctrl.c" ]] && mv "${OUT}/library/ziti_ctrl.c" "${OUT}/library/zgate_ctrl.c"
[[ -f "${OUT}/library/ziti_src.c" ]] && mv "${OUT}/library/ziti_src.c" "${OUT}/library/zgate_src.c"
[[ -f "${OUT}/library/ziti_enroll.c" ]] && mv "${OUT}/library/ziti_enroll.c" "${OUT}/library/zgate_enroll.c"

# ---- Includes zgate headers (ziti*.h -> zgate*.h, zitilib.h -> zgatelib.h) ----
for f in "${OUT}/includes/zgate"/ziti*.h; do
    [[ -e "$f" ]] || continue
    b="$(basename "$f")"
    mv "$f" "${OUT}/includes/zgate/zgate${b#ziti}"
done

# ---- inc_internal ----
[[ -f "${OUT}/inc_internal/ziti_ctrl.h" ]] && mv "${OUT}/inc_internal/ziti_ctrl.h" "${OUT}/inc_internal/zgate_ctrl.h"

# ---- Programs ----
[[ -f "${OUT}/programs/sample-bridge/ziti-fd-client.c" ]] && mv "${OUT}/programs/sample-bridge/ziti-fd-client.c" "${OUT}/programs/sample-bridge/zgate-fd-client.c"
[[ -f "${OUT}/programs/sample-bridge/ziti-ncat.c" ]] && mv "${OUT}/programs/sample-bridge/ziti-ncat.c" "${OUT}/programs/sample-bridge/zgate-ncat.c"
[[ -f "${OUT}/programs/wzcat/ziti_ws.c" ]] && mv "${OUT}/programs/wzcat/ziti_ws.c" "${OUT}/programs/wzcat/zgate_ws.c"
[[ -f "${OUT}/programs/zgatelib-samples/ziti-http-get.c" ]] && mv "${OUT}/programs/zgatelib-samples/ziti-http-get.c" "${OUT}/programs/zgatelib-samples/zgate-http-get.c"
[[ -f "${OUT}/programs/auth-samples/ziti_mfa.cpp" ]] && mv "${OUT}/programs/auth-samples/ziti_mfa.cpp" "${OUT}/programs/auth-samples/zgate_mfa.cpp"

# ---- Root ----
[[ -f "${OUT}/ziti.pc.in" ]] && mv "${OUT}/ziti.pc.in" "${OUT}/zgate.pc.in"

# ---- Tests ----
[[ -f "${OUT}/tests/test_ziti_model.cpp" ]] && mv "${OUT}/tests/test_ziti_model.cpp" "${OUT}/tests/test_zgate_model.cpp"
[[ -f "${OUT}/tests/zitilib-tests.cpp" ]] && mv "${OUT}/tests/zitilib-tests.cpp" "${OUT}/tests/zgatelib-tests.cpp"
[[ -f "${OUT}/tests/ziti_src_tests.cpp" ]] && mv "${OUT}/tests/ziti_src_tests.cpp" "${OUT}/tests/zgate_src_tests.cpp"

# ---- Content replacement (sed): ZITI_ -> ZGATE_, Ziti -> Zgate, ziti -> zgate, ZITI -> ZGATE, openziti -> openzgate ----
find "${OUT}" -type f \( \
    -name '*.c' -o -name '*.h' -o -name '*.cpp' -o -name '*.md' -o -name 'CMakeLists.txt' \
    -o -name '*.in' -o -name '*.cmake' -o -name '*.json' -o -name '*.pc.in' \
\) -exec sed -i -e 's/ZITI_/ZGATE_/g' -e 's/Ziti/Zgate/g' -e 's/ziti/zgate/g' -e 's/ZITI/ZGATE/g' -e 's/openziti/openzgate/g' {} \;

# Restore openziti URLs for deps (so FetchContent still works when not using local tlsuv)
sed -i 's|openzgate/tlsuv|openziti/tlsuv|g' "${OUT}/deps/CMakeLists.txt" 2>/dev/null || true
sed -i 's|openzgate/sdk-golang|openziti/sdk-golang|g' "${OUT}/library/CMakeLists.txt" 2>/dev/null || true

# ---- CMake: project, version, install path ----
sed -i 's/project(ziti-sdk/project(zgate-sdk/' "${OUT}/CMakeLists.txt"
sed -i 's/DESCRIPTION "OpenZiti C SDK"/DESCRIPTION "ZGate C SDK"/' "${OUT}/CMakeLists.txt"
sed -i 's|HOMEPAGE_URL "https://github.com/openziti/ziti-sdk-c"|HOMEPAGE_URL "https://github.com/ecloudseal/zgate-sdk-c"|' "${OUT}/CMakeLists.txt"
sed -i 's|/opt/openziti/ziti-sdk|/opt/zgate/zgate-sdk|g' "${OUT}/CMakeLists.txt"
sed -i 's|cmake_install/ziti-sdk|cmake_install/zgate-sdk|g' "${OUT}/CMakeLists.txt"
# Non-Windows else block: add CMAKE_INSTALL_LIBDIR and INCLUDEDIR so library install(DIRECTORY) has DESTINATION
if ! grep -A3 '^else()' "${OUT}/CMakeLists.txt" | grep -q 'CMAKE_INSTALL_LIBDIR'; then
    sed -i '/set(CMAKE_INSTALL_PREFIX \/opt\/zgate\/zgate-sdk/i\
    set(CMAKE_INSTALL_LIBDIR lib)\
    set(CMAKE_INSTALL_INCLUDEDIR include)' "${OUT}/CMakeLists.txt"
fi

# Version fallback in CMakeLists (when not from git) - insert BEFORE set(PROJECT_VERSION)
if ! grep -q 'GIT_VERSION MATCHES' "${OUT}/CMakeLists.txt"; then
    VBLOCK="$(mktemp)"
    cat << VEOF > "${VBLOCK}"
# Fallback when not from git
if(NOT GIT_VERSION OR GIT_VERSION MATCHES "\\\$Format")
    set(GIT_VERSION "${VER}")
    set(GIT_BRANCH "ref: (not a git repo)")
    set(GIT_COMMIT_HASH "none")
endif()

VEOF
    awk -v blockfile="${VBLOCK}" '
        BEGIN { while ((getline line < blockfile) > 0) block = block line "\n"; close(blockfile) }
        /set\(PROJECT_VERSION \$\{GIT_VERSION\}\)/ { printf "%s", block }
        { print }
    ' "${OUT}/CMakeLists.txt" > "${OUT}/CMakeLists.txt.tmp" && mv "${OUT}/CMakeLists.txt.tmp" "${OUT}/CMakeLists.txt"
    rm -f "${VBLOCK}"
fi

# version.txt
printf '%s\nref: (not a git repo)\nhash: (none)\n' "${VER}" > "${OUT}/version.txt"

# deps: use local tlsuv when available (from fetch-latest)
if [[ -n "${TLSUV_SRC:-}" ]] && [[ -d "${TLSUV_SRC}" ]]; then
    cat > "${OUT}/deps/CMakeLists.txt" << DEPS_CMAKE

include(FetchContent)

# allow downstream projects to pull tlsuv on their own
if (NOT TARGET tlsuv)
    if (tlsuv_DIR)
        add_subdirectory(\${tlsuv_DIR}
                \${CMAKE_CURRENT_BINARY_DIR}/tlsuv)
    else ()
        if(EXISTS "${TLSUV_SRC}")
            set(_TLSUV_LOCAL "${TLSUV_SRC}")
            add_subdirectory(\${_TLSUV_LOCAL}
                    \${CMAKE_CURRENT_BINARY_DIR}/tlsuv)
        else ()
            FetchContent_Declare(tlsuv
                    GIT_REPOSITORY https://github.com/openziti/tlsuv.git
                    GIT_TAG \${tlsuv_VERSION}
            )
            FetchContent_MakeAvailable(tlsuv)
        endif ()
    endif (tlsuv_DIR)
endif ()
DEPS_CMAKE
fi

# programs/CMakeLists: subdir names
sed -i 's/ziti-prox-c/zgate-prox-c/g' "${OUT}/programs/CMakeLists.txt"
sed -i 's/zitilib-samples/zgatelib-samples/g' "${OUT}/programs/CMakeLists.txt"

# sample-bridge: executable sources
sed -i 's/ziti-ncat\.c/zgate-ncat.c/g' "${OUT}/programs/sample-bridge/CMakeLists.txt"
sed -i 's/ziti-fd-client\.c/zgate-fd-client.c/g' "${OUT}/programs/sample-bridge/CMakeLists.txt"
sed -i 's/ziti-http-get/zgate-http-get/g' "${OUT}/programs/zgatelib-samples/CMakeLists.txt" 2>/dev/null || true
sed -i 's/ziti_ws\.c/zgate_ws.c/g' "${OUT}/programs/wzcat/CMakeLists.txt" 2>/dev/null || true
sed -i 's/ziti_mfa/zgate_mfa/g' "${OUT}/programs/auth-samples/CMakeLists.txt" 2>/dev/null || true

# library/CMakeLists: source list and zgate_* variable names (already done by sed if they were ziti_)
# tests/CMakeLists: test_zgate_model, zgatelib-tests, zgate_src_tests
sed -i 's/test_ziti_model/test_zgate_model/g' "${OUT}/tests/CMakeLists.txt"
sed -i 's/zitilib-tests/zgatelib-tests/g' "${OUT}/tests/CMakeLists.txt"
sed -i 's/ziti_src_tests/zgate_src_tests/g' "${OUT}/tests/CMakeLists.txt"
sed -i 's/ziti-sdk/zgate-sdk/g' "${OUT}/tests/CMakeLists.txt" 2>/dev/null || true

# configure_file zgate.pc.in
sed -i 's/ziti\.pc\.in/zgate.pc.in/g' "${OUT}/library/CMakeLists.txt" 2>/dev/null || true
sed -i 's/ziti\.pc/zgate.pc/g' "${OUT}/library/CMakeLists.txt" 2>/dev/null || true

export ZGATE_OUT="${OUT}"
echo "==> Patched output: ${OUT}"
