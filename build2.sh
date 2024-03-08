#!/bin/bash
#
# Compile script for MoeKernel🐇
# Copyright (C) 2020-2021 Adithya R.

SECONDS=0
ZIPNAME="Surgex-ginkgo-$(date '+%Y%m%d').zip"
TC_DIR="$HOME/tc/google-18"
GCC_64_DIR="$HOME/tc/aarch64-linux-android-14.0"
GCC_32_DIR="$HOME/tc/arm-linux-androideabi-14.0"
AK3_DIR="$HOME/android/AnyKernel3"
DEFCONFIG="vendor/ginkgo-perf_defconfig"

export PATH=$TC_DIR/$PATH

export KBUILD_BUILD_USER=ShaawkTeam
export KBUILD_BUILD_HOST=Builders

if ! [ -d "${TC_DIR}" ]; then
    echo "Clang not found! Cloning to ${TC_DIR}..."
    if ! git clone --depth=1 https://gitlab.com/vermouth/android_prebuilts_clang_host_linux-x86_clang-r510928.git ${TC_DIR}; then
        echo "Cloning failed! Aborting..."
        exit 1
    fi
fi

if ! [ -d "${GCC_64_DIR}" ]; then
    echo "GCC_64 not found! Cloning to ${GCC_64_DIR}..."
    if ! git clone --depth=1 https://github.com/mvaisakh/gcc-arm64 ${GCC_64_DIR}; then
        echo "Cloning failed! Aborting..."
        exit 1
    fi
fi

if ! [ -d "${GCC_32_DIR}" ]; then
    echo "GCC_32 not found! Cloning to ${GCC_32_DIR}..."
    if ! git clone --depth=1 https://github.com/mvaisakh/gcc-arm ${GCC_32_DIR}; then
        echo "Cloning failed! Aborting..."
        exit 1
    fi
fi

curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -s main

if [[ $1 = "-r" || $1 = "--regen" ]]; then
    make O=out ARCH=arm64 $DEFCONFIG savedefconfig
    cp out/defconfig arch/arm64/configs/$DEFCONFIG
    exit
fi

if [[ $1 = "-c" || $1 = "--clean" ]]; then
    rm -rf out
fi

if [[ $1 = "-m" || $1 = "--menu" ]]; then
    mkdir -p out
    make O=out ARCH=arm64 $DEFCONFIG menuconfig
elif [[ $1 = "menu" ]]; then
    mkdir -p out
    make O=out ARCH=arm64 $DEFCONFIG menuconfig
else
    mkdir -p out
    make O=out ARCH=arm64 $DEFCONFIG
fi

echo -e "\nStarting compilation... wait\n"
make -j$(nproc --all) \
    O=out \
    ARCH=arm64 \
    CC=clang \
    HOSTCC=clang \
    LD=ld.lld \
    AR=llvm-ar \
    AS=llvm-as \
    NM=llvm-nm \
    OBJCOPY=llvm-objcopy \
    OBJDUMP=llvm-objdump \
    STRIP=llvm-strip \
    CROSS_COMPILE=$GCC_64_DIR/usr/bin/aarch64-linux-android- \
    CROSS_COMPILE_ARM32=$GCC_32_DIR/usr/bin/arm-linux-androideabi- \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    Image.gz-dtb dtbo.img

if [ -f "out/arch/arm64/boot/Image.gz-dtb" ] && \
   [ -f "out/arch/arm64/boot/dtbo.img" ]; then
    echo -e "\nKernel compiled successfully! Zipping up...\n"
    if [ -d "$AK3_DIR" ]; then
        cp -r $AK3_DIR AnyKernel3
    elif ! git clone -b ginkgo -q https://github.com/DeliUstaTR/AnyKernel3; then
        echo -e "\nAnyKernel3 repo not found locally and cloning failed! Aborting..."
        exit 1
    fi
    cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
    cp out/arch/arm64/boot/dtbo.img AnyKernel3
    rm -f *zip
    cd AnyKernel3
    git checkout master &> /dev/null
    zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
    cd ..
    rm -rf AnyKernel3
    rm -rf out/arch/arm64/boot
    echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
    echo "Zip: $ZIPNAME"
    curl -T $ZIPNAME https://transfer.sh
else
    echo -e "\nCompilation failed!"
    exit 1
fi
