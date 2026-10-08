
#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Uso: $0 <directorio_kernel> <version_kernel>"
    exit 1
fi

KERNEL_DIR="$1"
KERNEL_VERSION="$2"
NTSYNC_ENABLED="${NTSYNC_ENABLED:-true}"

echo "== NTSync para Android/Linux 5.10 =="

if [[ "$NTSYNC_ENABLED" != "true" ]]; then
    echo "NTSync desactivado. No se aplicarán parches."
    exit 0
fi

if [[ "$KERNEL_VERSION" != 5.10* ]]; then
    echo "ERROR: Este builder solo admite parches NTSync para kernel 5.10."
    echo "Versión detectada: $KERNEL_VERSION"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILDER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PATCH_DIR="$BUILDER_DIR/patches/ntsync/android12-5.10"

if [[ ! -d "$KERNEL_DIR" ]]; then
    echo "ERROR: No existe el directorio del kernel: $KERNEL_DIR"
    exit 1
fi

if [[ ! -d "$PATCH_DIR" ]]; then
    echo "ERROR: No existe el directorio de parches: $PATCH_DIR"
    exit 1
fi

shopt -s nullglob
PATCHES=("$PATCH_DIR"/*.patch)

if [[ ${#PATCHES[@]} -eq 0 ]]; then
    echo "ERROR: No hay parches NTSync en $PATCH_DIR"
    echo "Añade primero los parches verificados para kernel 5.10."
    exit 1
fi

cd "$KERNEL_DIR"

for patch_file in "${PATCHES[@]}"; do
    echo "Aplicando: $(basename "$patch_file")"

    if ! patch --batch --forward -p1 < "$patch_file"; then
        echo "ERROR: No se pudo aplicar $(basename "$patch_file")."
        echo "Comprueba si ya está aplicado o si es incompatible."
        exit 1
    fi
done

echo "Parches NTSync aplicados correctamente."
