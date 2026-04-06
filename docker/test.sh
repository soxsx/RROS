#!/usr/bin/env bash
# Build initramfs and boot RROS in QEMU ARM64.
# Usage: bash docker/test.sh
# Exit QEMU: Ctrl+A X
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="rros-builder2"
KERNEL="$REPO_ROOT/arch/arm64/boot/Image"

if [ ! -f "$KERNEL" ]; then
    echo "ERROR: Kernel not found at $KERNEL"
    echo "       Run bash docker/build.sh first."
    exit 1
fi

docker run --rm -it \
    -v "$REPO_ROOT:/src" \
    "$IMAGE" \
    bash -c "
        set -e
        bash /src/docker/mk-initramfs.sh
        echo '--- Booting RROS in QEMU (Ctrl+A X to quit) ---'
        qemu-system-aarch64 \
            -machine virt \
            -cpu cortex-a57 \
            -smp 2 \
            -m 512M \
            -kernel /src/arch/arm64/boot/Image \
            -initrd /tmp/initramfs.cpio.gz \
            -append 'console=ttyAMA0 rdinit=/init' \
            -nographic \
            -no-reboot
    "
