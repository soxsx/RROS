#!/bin/bash
set -e

INITRAMFS_DIR=/tmp/initramfs
OUTPUT=/tmp/initramfs.cpio.gz

rm -rf "$INITRAMFS_DIR"
mkdir -p "$INITRAMFS_DIR"/{bin,sbin,dev,proc,sys,tmp}

cp /usr/bin/busybox "$INITRAMFS_DIR/bin/"
for cmd in sh ash ls cat echo mount dmesg mdev mkdir mknod grep sleep ps; do
    ln -sf busybox "$INITRAMFS_DIR/bin/$cmd"
done

# Include EVL test binaries if available
EVL_INSTALL=/tmp/evl-install/usr
if [ -d "$EVL_INSTALL/bin" ]; then
    echo "==> Bundling EVL test binaries..."
    mkdir -p "$INITRAMFS_DIR/evl/bin" "$INITRAMFS_DIR/evl/lib"
    cp "$EVL_INSTALL/bin/"* "$INITRAMFS_DIR/evl/bin/" 2>/dev/null || true
    # Copy libevl shared library if present
    if [ -d "$EVL_INSTALL/lib" ]; then
        cp "$EVL_INSTALL/lib/"*.so* "$INITRAMFS_DIR/evl/lib/" 2>/dev/null || true
    fi
    echo "    EVL binaries: $(ls $INITRAMFS_DIR/evl/bin/)"
fi

cat > "$INITRAMFS_DIR/init" << 'EOF'
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev 2>/dev/null || mdev -s
echo "=== RROS kernel booted ==="
dmesg | grep -iE "rros|dovetail|oob" | head -30
export PATH="/evl/bin:$PATH"
export LD_LIBRARY_PATH="/evl/lib"
exec setsid sh -c 'exec sh </dev/ttyAMA0 >/dev/ttyAMA0 2>&1'
EOF
chmod +x "$INITRAMFS_DIR/init"

cd "$INITRAMFS_DIR" && find . | cpio -H newc -o | gzip > "$OUTPUT"
echo "done: $(ls -lh $OUTPUT)"
