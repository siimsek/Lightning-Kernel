# Lightning Kernel

[![Linux](https://img.shields.io/badge/Linux-4.14.339--openela-FCC624?logo=linux&logoColor=black)](https://www.kernel.org/)
[![Architecture](https://img.shields.io/badge/architecture-ARM64-0091BD)](https://www.arm.com/)
[![Target](https://img.shields.io/badge/target-ginkgo-FF6900)](https://en.wikipedia.org/wiki/Codename)
[![KernelSU](https://img.shields.io/badge/integrates-KernelSU-6E45E2)](https://github.com/tiann/KernelSU)
[![License](https://img.shields.io/badge/license-GPL--2.0-blue.svg)](COPYING)

Lightning Kernel is an ARM64 Android kernel source tree for the `ginkgo` target configuration. The default `thirteen` branch is based on Linux `4.14.339-openela`, includes Android kernel build configuration, and tracks KernelSU as a Git submodule.

> [!WARNING]
> This repository contains **kernel source code**, not a ready-to-flash end-user ZIP. A kernel built from it must match the target device, boot image format, firmware, ROM, and partition layout. Flashing an incompatible image can cause boot failure or data loss.

## Scope

The project provides a maintainable source base for building and modifying a device-targeted Android kernel. It is intended for developers who need to inspect, patch, configure, compile, test, and package the kernel for the supported target.

## Highlights

- Linux `4.14.339-openela` kernel base on the default `thirteen` branch.
- ARM64 build configuration through `build.config.aarch64`.
- Device-specific `ginkgo-stock_defconfig` and `ginkgo-perf_defconfig` configurations.
- KernelSU included as a Git submodule.
- Standard Android kernel build files, Kbuild/Kconfig metadata, and Android build integration files.
- Upstream Linux stable and OpenELA maintenance commits in the branch history.

## Requirements

- Linux build host; a recent Ubuntu or Debian-based distribution is a practical choice.
- Git with submodule support.
- Android-kernel-compatible Clang/LLVM toolchain.
- Required build tools: `bc`, `bison`, `flex`, `make`, `pahole`, OpenSSL headers, ELF headers, Python 3, and a C/C++ build environment.
- A target-specific boot-image packaging and flashing workflow.

On Ubuntu/Debian, install common build dependencies with:

```bash
sudo apt update
sudo apt install -y bc bison build-essential ccache clang flex git   libelf-dev libssl-dev make pahole python3
```

> [!NOTE]
> Toolchain versions and boot-image packaging vary across Android kernel projects. Keep the same compiler family and packaging workflow used by the ROM or device tree that the resulting kernel will target.

## Clone the source

Clone the default branch together with KernelSU:

```bash
git clone --recurse-submodules --branch thirteen   https://github.com/siimsek/Lightning-Kernel.git
cd Lightning-Kernel
```

If the repository was already cloned without submodules:

```bash
git submodule update --init --recursive
```

## Build

The following is the repository-aligned baseline for an out-of-tree ARM64 build using `ginkgo-stock_defconfig`.

1. Make the chosen Android kernel Clang toolchain available on `PATH`.

   ```bash
   export PATH="/path/to/clang/bin:$PATH"
   ```

2. Configure the build.

   ```bash
   export ARCH=arm64
   export LLVM=1
   export LLVM_IAS=1
   export CLANG_TRIPLE=aarch64-linux-gnu-
   export CROSS_COMPILE=aarch64-linux-androidkernel-

   make O=out ginkgo-stock_defconfig
   ```

3. Compile the kernel.

   ```bash
   make -j"$(nproc)" O=out
   ```

Expected output artifacts include:

```text
out/arch/arm64/boot/Image
out/arch/arm64/boot/Image.gz
out/vmlinux
out/System.map
```

### Alternative configuration

The tree also contains `ginkgo-perf_defconfig`. Use it only if it is part of the target device's known-good build configuration:

```bash
make O=out ginkgo-perf_defconfig
make -j"$(nproc)" O=out
```

## Packaging and flashing

Packaging is intentionally separate from compilation. Do not flash a raw `Image` or `Image.gz` unless the device-specific boot-image process explicitly requires it.

Before packaging or flashing:

1. Verify the target codename, Android release, ROM, and firmware compatibility.
2. Preserve a known-good boot image and a recovery method.
3. Confirm the expected boot/vendor_boot partition layout.
4. Test locally built artifacts before distributing them.
5. Keep a rollback path available.

## Project structure

```text
Lightning-Kernel/
├── arch/arm64/                   # ARM64 architecture code and defconfigs
│   └── configs/
│       ├── ginkgo-stock_defconfig
│       └── vendor/ginkgo-perf_defconfig
├── drivers/                      # Kernel driver implementations
├── fs/                           # Filesystem code
├── include/                      # Shared kernel headers
├── kernel/                       # Core kernel subsystems
├── mm/                           # Memory-management subsystem
├── net/                          # Networking subsystem
├── security/                     # LSM and security code
├── techpack/                     # Platform-specific technology packages
├── KernelSU/                     # KernelSU Git submodule
├── build.config.aarch64          # ARM64 build settings and artifacts
├── build.config.common           # Shared build settings
├── Android.bp                    # Android build integration
├── AndroidKernel.mk              # Android kernel make integration
├── Kbuild / Kconfig / Makefile   # Kernel build system
├── Documentation/                # Upstream kernel documentation
├── scripts/                      # Build and maintenance scripts
└── COPYING                       # GNU GPL v2.0
```

## Contributing

1. Create a branch from `thirteen`.
2. Keep commits focused and explain the target, intent, and test environment.
3. Build the affected configuration before opening a pull request.
4. Do not submit generated artifacts such as `out/`, `Image`, or `vmlinux`.
5. Preserve upstream licensing and attribution.

## License

This project is licensed under the [GNU General Public License v2.0](COPYING), consistent with the Linux kernel source base.

## Disclaimer

Kernel development and flashing are inherently device-sensitive. You are responsible for validating any build before use. The maintainers are not responsible for boot failure, data loss, hardware malfunction, or incompatibility caused by locally built or modified kernels.
