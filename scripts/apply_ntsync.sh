
#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <kernel_directory> <kernel_version>"
    exit 1
fi

KERNEL_DIR="$1"
KERNEL_VERSION="$2"
NTSYNC_ENABLED="${NTSYNC_ENABLED:-true}"

echo "== NTSync Patch System =="

if [[ "$NTSYNC_ENABLED" != "true" ]]; then
    echo "NTSync is disabled. Skipping patches."
    exit 0
fi

case "$KERNEL_VERSION" in
    5.10*)
        PATCH_DIR="patches/ntsync/android12-5.10"
        ;;
    5.15*)
        PATCH_DIR="patches/ntsync/android14-5.15"
        ;;
    6.12*)
        PATCH_DIR="patches/ntsync/android16-6.12"
        ;;
    *)
        echo "ERROR: Unsupported kernel version: $KERNEL_VERSION"
        exit 1
        ;;
esac

# Resolve the patch directory relative to the builder repository.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILDER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PATCH_DIR="$BUILDER_DIR/$PATCH_DIR"

if [[ ! -d "$PATCH_DIR" ]]; then
    echo "ERROR: NTSync patch directory not found:"
    echo "$PATCH_DIR"
    exit 1
fi

shopt -s nullglob
PATCHES=("$PATCH_DIR"/*.patch)

if [[ ${#PATCHES[@]} -eq 0 ]]; then
    echo "ERROR: No .patch files found in:"
    echo "$PATCH_DIR"
    exit 1
fi

if [[ ! -d "$KERNEL_DIR" ]]; then
    echo "ERROR: Kernel directory not found: $KERNEL_DIR"
    exit 1
fi

cd "$KERNEL_DIR"

for patch_file in "${PATCHES[@]}"; do
    echo
    echo "Checking and applying: $(basename "$patch_file")"

    if ! patch --batch --forward -p1 < "$patch_file"; then
        echo "ERROR: Patch failed: $(basename "$patch_file")"
        echo "The patch may be incompatible or already applied."
        exit 1
    fi
done

echo
echo "NTSync patches applied successfully."
