#!/usr/bin/env bash
set -euo pipefail

# Build script for emacs-portable
# Produces a clean .emacs.d/ directory with only .el files.
# Run by CI or locally to produce the deployable zip.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
OUT_DIR="${BUILD_DIR}/.emacs.d"
VENDOR_SRC="${SCRIPT_DIR}/vendor"

echo "==> Cleaning build directory..."
rm -rf "${BUILD_DIR}"
mkdir -p "${OUT_DIR}/vendor"

echo "==> Copying config files..."
cp "${SCRIPT_DIR}/init.el" "${OUT_DIR}/init.el"
cp "${SCRIPT_DIR}/early-init.el" "${OUT_DIR}/early-init.el"

echo "==> Processing vendor packages..."
for pkg_dir in "${VENDOR_SRC}"/*/; do
    pkg_name="$(basename "${pkg_dir}")"
    dest="${OUT_DIR}/vendor/${pkg_name}"
    mkdir -p "${dest}"

    echo "    ${pkg_name}"

    # Copy only .el files, preserving subdirectory structure (e.g. lisp/)
    find "${pkg_dir}" -name "*.el" \
        ! -name "*-test.el" \
        ! -name "*-tests.el" \
        ! -name "test-*.el" \
        ! -path "*/test/*" \
        ! -path "*/tests/*" \
        ! -path "*/.git/*" \
        -print0 | while IFS= read -r -d '' file; do
            # Get relative path from package dir
            rel="${file#${pkg_dir}}"
            # Create parent dir in dest
            mkdir -p "${dest}/$(dirname "${rel}")"
            cp "${file}" "${dest}/${rel}"
        done
done

echo "==> Generating VERSIONS.lock..."
(
    echo "# Vendored Package Versions"
    echo "# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "# Format: package | commit"
    echo ""
    cd "${SCRIPT_DIR}"
    git submodule foreach --quiet 'echo "$(basename "$sm_path")|$(git rev-parse HEAD)"' | \
        sort | while IFS='|' read -r name hash; do
            printf "%-15s | %s\n" "${name}" "${hash}"
        done
) > "${OUT_DIR}/vendor/VERSIONS.lock"

echo "==> Build stats:"
echo "    Packages: $(ls -d "${OUT_DIR}/vendor"/*/ 2>/dev/null | wc -l)"
echo "    .el files: $(find "${OUT_DIR}" -name "*.el" | wc -l)"
echo "    Total size: $(du -sh "${OUT_DIR}" | cut -f1)"

echo "==> Done! Output in: ${BUILD_DIR}/"
