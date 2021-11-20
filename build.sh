export PATH="$HOME/aosp-clang/bin:$PATH"
GCC_64_DIR="$HOME/aarch64-linux-android-4.9"
GCC_32_DIR="$HOME/arm-linux-androideabi-4.9"
SECONDS=0
ZIPNAME="SurgeX-ginkgo-$(date '+%Y%m%d-%H%M').zip"

if ! [ -d "$HOME/aosp-clang" ]; then
echo "Aosp clang not found! Cloning..."
if ! git clone -q https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r437112.git --depth=1 --single-branch ~/aosp-clang; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

if ! [ -d "$HOME/aarch64-linux-android-4.9" ]; then
echo "aarch64-linux-android-4.9 not found! Cloning..."
if ! git clone -q https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git --depth=1 --single-branch ~/aarch64-linux-android-4.9; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

if ! [ -d "$HOME/arm-linux-androideabi-4.9" ]; then
echo "arm-linux-androideabi-4.9 not found! Cloning..."
if ! git clone -q https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git --depth=1 --single-branch ~/arm-linux-androideabi-4.9; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

mkdir -p out
make O=out ARCH=arm64 vendor/ginkgo-perf_defconfig

if [[ $1 == "-r" || $1 == "--regen" ]]; then
cp out/.config arch/arm64/configs/vendor/ginkgo-perf_defconfig
echo -e "\nRegened defconfig succesfully!"
exit 0
else
echo -e "\nStarting compilation...\n"
make -j$(nproc --all) O=out ARCH=arm64 CC=clang LD=ld.lld AS=llvm-as AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=$GCC_64_DIR/bin/aarch64-linux-android- CROSS_COMPILE_ARM32=$GCC_32_DIR/bin/arm-linux-androideabi- CLANG_TRIPLE=aarch64-linux-gnu- Image.gz-dtb dtbo.img
fi

if [ -f "out/arch/arm64/boot/Image.gz-dtb" ] && [ -f "out/arch/arm64/boot/dtbo.img" ]; then
echo -e "\nKernel compiled succesfully! Zipping up...\n"
git clone -q https://github.com/madmax7896/AnyKernel3
cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
cp out/arch/arm64/boot/dtbo.img AnyKernel3
cd AnyKernel3
zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
cd ..
rm -rf AnyKernel3
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
if command -v gdrive &> /dev/null; then
gdrive upload --share $ZIPNAME
else
echo "Zip: $ZIPNAME"
fi
rm -rf out/arch/arm64/boot
else
echo -e "\nCompilation failed!"
fi
