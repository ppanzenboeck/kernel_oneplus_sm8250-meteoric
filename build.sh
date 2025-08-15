#!/usr/bin/env bash
set -e

# ===== CONFIGURATION =====
KERNEL_NAME="Meteoric-KSU"
DEVICE="kebab"
DEFCONFIG="vendor/kebab_defconfig"
TOOLCHAIN_PATH="$HOME/toolchains/neutron-clang"
ANYKERNEL_PATH="$GITHUB_WORKSPACE/AnyKernel3"
OUT_DIR="$GITHUB_WORKSPACE/out"

# ===== ENVIRONMENT =====
export PATH="$TOOLCHAIN_PATH/bin:$PATH"
export ARCH=arm64
export SUBARCH=arm64
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
export KBUILD_BUILD_USER="github-actions"
export KBUILD_BUILD_HOST="CI"

# ===== CLEAN =====
echo "[*] Cleaning output directory..."
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

# ===== DEFCONFIG =====
echo "[*] Generating defconfig..."
make O="$OUT_DIR" "$DEFCONFIG" CC=clang

# ===== BUILD KERNEL =====
echo "[*] Building kernel..."
make -j"$(nproc --all)" O="$OUT_DIR" CC=clang \
    LD=ld.lld AR=llvm-ar NM=llvm-nm STRIP=llvm-strip \
    OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump READELF=llvm-readelf

# ===== CHECK OUTPUT =====
if [ ! -f "$OUT_DIR/arch/arm64/boot/Image.gz-dtb" ]; then
    echo "[!] Build failed — Image.gz-dtb not found!"
    exit 1
fi
echo "[+] Kernel build completed successfully."

# ===== PACKAGE =====
if [ -d "$ANYKERNEL_PATH" ]; then
    echo "[*] Packaging with AnyKernel3..."
    cp "$OUT_DIR/arch/arm64/boot/Image.gz-dtb" "$ANYKERNEL_PATH"
    cd "$ANYKERNEL_PATH"
    zip -r9 "${KERNEL_NAME}-${DEVICE}.zip" . -x "*.git*" README.md *placeholder
    mv "${KERNEL_NAME}-${DEVICE}.zip" "$GITHUB_WORKSPACE/"
    echo "[+] AnyKernel3 ZIP created: ${KERNEL_NAME}-${DEVICE}.zip"
else
    echo "[!] AnyKernel3 folder not found — skipping packaging."
fi
