#!/usr/bin/env bash
# Build the RROS ARM64 kernel inside Docker.
# Usage: bash docker/build.sh [extra make args...]
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="rros-builder2"

echo "==> Building Docker image: $IMAGE (host network)"
DOCKER_BUILDKIT=0 docker build \
    --network host \
    -t "$IMAGE" \
    "$REPO_ROOT/docker"

echo "==> Compiling RROS kernel (ARCH=arm64)"
docker run --rm \
    -v "$REPO_ROOT:/src" \
    "$IMAGE" \
    bash -c "
        set -e
        # Load defconfig if .config is absent
        if [ ! -f /src/.config ]; then
            echo '--- Running defconfig ---'
            make -C /src ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 defconfig
            echo '--- Enabling RROS options ---'
            echo "CONFIG_RROS=y"         >> /src/.config
            echo "CONFIG_RROS_OOB_NET=y" >> /src/.config
            make -C /src ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 olddefconfig
        fi
        echo '--- Building kernel ---'
        make -C /src ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 -j\$(nproc) \"\$@\"
    " -- "$@"

echo ""
echo "==> Done. Kernel image: arch/arm64/boot/Image"
