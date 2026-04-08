# RROS Docker 构建与测试

## 环境要求

- Docker（宿主机）
- 8 GB 以上磁盘空间（镜像约 3–4 GB）

镜像内置：Ubuntu 22.04、aarch64 交叉编译链、Rust 1.73.0、QEMU 7.1.0。

## 快速开始

### 1. 编译内核

```bash
bash docker/build.sh
```

首次运行会构建 Docker 镜像（约 10–20 分钟）。编译完成后输出：

```
arch/arm64/boot/Image
```

### 2. 在 QEMU 中测试

```bash
bash docker/test.sh
```

脚本会打包 initramfs 并启动 QEMU，进入 shell 后可查看内核日志。

退出 QEMU：`Ctrl+A` 然后按 `X`