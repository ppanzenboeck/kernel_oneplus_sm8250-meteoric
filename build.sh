#!/usr/bin/env bash
set -e

# ===== 1. CONFIGURATION & PATHS =====
KERNEL_NAME="Meteoric"
DEVICE="kebab"
DEFCONFIG="vendor/kebab_defconfig"
OUT_DIR="$GITHUB_WORKSPACE/out"
ANYKERNEL_DIR="$GITHUB_WORKSPACE/AnyKernel3"

# Environment (Fallback values if not set by GitHub Actions)
export ARCH=${ARCH:-arm64}
export SUBARCH=${SUBARCH:-arm64}
export KBUILD_BUILD_USER=${KBUILD_BUILD_USER:-"Gemini-CI"}
export KBUILD_BUILD_HOST=${KBUILD_BUILD_HOST:-"BuildServer"}

# ===== 2. PREPARE DIRECTORIES =====
echo "[*] Cleaning up..."
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

# ===== 3. KERNELSU LOGIC =====
# Use the environment variable from the YAML
if [ "$KSU_ENABLED" = "Y" ]; then
    echo "[*] Enabling KernelSU..."
    KERNEL_NAME="${KERNEL_NAME}-KSU"
    # Append KSU config if your kernel tree uses a fragment, 
    # otherwise we assume KSU is integrated into the source.
    # make O="$OUT_DIR" ksu_defconfig 
fi

# ===== 4. GENERATE DEFCONFIG =====
echo "[*] Generating defconfig..."
make O="$OUT_DIR" ARCH="$ARCH" "$DEFCONFIG"

# ===== 5. START COMPILATION =====
echo "[*] Starting build for $DEVICE..."
make -j"$(nproc --all)" O="$OUT_DIR" \
    ARCH="$ARCH" \
    CC=clang \
    LLVM=1 \
    LLVM_IAS=1 \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
    V=0

# ===== 6. VERIFY & PACKAGE =====
# Check for the expected output file (OnePlus 8T usually uses Image or Image.gz)
if [ -f "$OUT_DIR/arch/arm64/boot/Image" ]; then
    echo "[+] Build successful! Packaging..."
    
    if [ -d "$ANYKERNEL_DIR" ]; then
        cp "$OUT_DIR/arch/arm64/boot/Image" "$ANYKERNEL_DIR/"
        # Also copy DTBO or DTB if your device needs them
        [ -f "$OUT_DIR/arch/arm64/boot/dtbo.img" ] && cp "$OUT_DIR/arch/arm64/boot/dtbo.img" "$ANYKERNEL_DIR/"
        
        cd "$ANYKERNEL_DIR"
        ZIP_FINAL="${KERNEL_NAME}-${DEVICE}-$(date +%Y%m%d).zip"
        zip -r9 "$OUT_DIR/$ZIP_FINAL" * -x .git* README.md
        echo "[+] Package created: $OUT_DIR/$ZIP_FINAL"
    else
        echo "[!] AnyKernel3 directory not found at $ANYKERNEL_DIR"
        exit 1
    fi
else
    echo "[!] Build failed: Image not found in $OUT_DIR/arch/arm64/boot/"
    exit 1
fi
