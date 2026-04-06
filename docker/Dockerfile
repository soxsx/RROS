# RROS build + test environment
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Restrict default sources to amd64, add ports.ubuntu.com for arm64
RUN sed -i 's/^deb /deb [arch=amd64] /' /etc/apt/sources.list && \
    echo "deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports jammy main universe" >> /etc/apt/sources.list && \
    echo "deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports jammy-updates main universe" >> /etc/apt/sources.list && \
    dpkg --add-architecture arm64

RUN apt-get update && apt-get install -y \
    # ARM64 cross-compiler (aarch64-linux-gnu-)
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    binutils-aarch64-linux-gnu \
    # Kernel build essentials
    make bc flex bison \
    libssl-dev libelf-dev \
    # BTF/debug info (pahole >= 1.16 needed for CONFIG_DEBUG_INFO_BTF)
    dwarves \
    # Script tooling
    python3 perl \
    curl ca-certificates git \
    # LLVM/clang-14 (Ubuntu 22.04 default; < 15 per RROS docs)
    clang llvm lld \
    # QEMU build dependencies (QEMU 7.1.0 compiled from source below)
    ninja-build libglib2.0-dev libpixman-1-dev pkg-config zlib1g-dev \
    # initramfs packaging
    cpio gzip \
    # meson + ninja + rsync (required by libevl build system)
    meson ninja-build rsync \
    # ARM64 busybox for initramfs (static binary, no host deps)
    busybox-static:arm64 \
    && rm -rf /var/lib/apt/lists/*

# Build QEMU 7.1.0 from source (Ubuntu 22.04 apt only ships 6.2).
# Only aarch64-softmmu target to minimize build time.
ARG QEMU_VERSION=7.1.0
RUN curl -fsSL https://download.qemu.org/qemu-${QEMU_VERSION}.tar.xz | tar xJ && \
    cd qemu-${QEMU_VERSION} && \
    ./configure \
        --target-list=aarch64-softmmu \
        --prefix=/usr/local \
        --disable-docs \
        --disable-werror && \
    make -j$(nproc) && \
    make install && \
    cd / && rm -rf qemu-${QEMU_VERSION}

# Install Rust 1.73.0
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --default-toolchain 1.73.0 --profile minimal
ENV PATH="/root/.cargo/bin:$PATH"

# Add rust-src (required for kernel to compile core/alloc from source)
RUN rustup component add rust-src

# Install bindgen at the exact version the kernel expects (>= 0.65.1; keep locked)
RUN cargo install --locked bindgen-cli --version 0.65.1

WORKDIR /src
