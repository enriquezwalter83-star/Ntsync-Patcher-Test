
#!/bin/bash

set -euo pipefail

KERNEL_DIR="$1"
KERNEL_VERSION="$2"

echo "== NTSync Patch System =="

cd "$KERNEL_DIR"

case "$KERNEL_VERSION" in

    5.10*)
        PATCH_DIR="../../patches/ntsync/android12-5.10"
        ;;

    5.15*)
        PATCH_DIR="../../patches/ntsync/android14-5.15"
        ;;

    6.12*)
        PATCH_DIR="../../patches/ntsync/android16-6.12"
        ;;

    *)
        echo "Unsupported kernel version: $KERNEL_VERSION"
        exit 1
        ;;

esac


if [ ! -d "$PATCH_DIR" ]; then
    echo "No NTSync patch available for this kernel."
    exit 1
fi


for patch in "$PATCH_DIR"/*.patch; do

    echo "Applying:"
    echo "$patch"

    patch -p1 < "$patch"

done


echo "NTSync patch applied successfully"
