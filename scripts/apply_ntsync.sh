
#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Uso: $0 <directorio_kernel> <version_kernel>"
    exit 1
fi

KERNEL_DIR="$1"
KERNEL_VERSION="$2"

# Aceptar cualquier subnivel de Linux 5.10.
if [[ ! "$KERNEL_VERSION" =~ ^5\.10\.([0-9]+)([-+].*)?$ ]]; then
    echo "ERROR: NTSync solo está configurado para Linux 5.10.x."
    echo "Versión detectada: $KERNEL_VERSION"
    exit 1
fi

SUBLEVEL="${BASH_REMATCH[1]}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH_DIR="$SCRIPT_DIR/../patches/ntsync/android12-5.10"

if [[ ! -d "$KERNEL_DIR" ]]; then
    echo "ERROR: No existe el directorio del kernel: $KERNEL_DIR"
    exit 1
fi

if [[ ! -d "$PATCH_DIR" ]]; then
    echo "ERROR: No existe el directorio de parches: $PATCH_DIR"
    exit 1
fi

cd "$KERNEL_DIR"

# No modificar el kernel si no es un repositorio Git.
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "ERROR: El código del kernel no es un repositorio Git."
    exit 1
fi

# Comprueba si el parche encaja, ya está aplicado o es incompatible.
apply_checked() {
    local name="$1"
    local file="$PATCH_DIR/$name"

    if [[ ! -f "$file" ]]; then
        echo "ERROR: Falta el parche: $name"
        exit 1
    fi

    echo ""
    echo "Verificando: $name"

    if git apply --check "$file" >/dev/null 2>&1; then
        git apply "$file"
        echo "APLICADO: $name"
    elif git apply --reverse --check "$file" >/dev/null 2>&1; then
        echo "OMITIDO: $name ya parece estar aplicado."
    else
        echo "ERROR: $name no encaja con esta base."
        echo "No se ha intentado forzar el parche."
        exit 1
    fi
}

# Parches auxiliares según los límites usados por WildKernel.
if (( SUBLEVEL <= 66 )); then
    apply_checked "0001-lockdep-detect-recursive-read.patch"
fi

if (( SUBLEVEL <= 209 )); then
    apply_checked "0002-lockdep-assert-none-held.patch"
fi

# Parches principales de NTSync.
apply_checked "ntsync_compat_android12-5.10.patch"
apply_checked "ntsync_base.patch"

echo ""
echo "NTSync: todos los parches pasaron las comprobaciones."
