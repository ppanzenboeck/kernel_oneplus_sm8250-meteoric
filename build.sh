#!/bin/bash

#aosp clang my beloved. everything else is just a meme!!!
function download_toolchain() {
  if [ ! -d aospclang ]; then
    PREBUILTS_URL="https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+/refs/heads/main"
    CDN_URL="https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/main/"
    EXTRACT_DIR="aospclang"
    TARBALL_NAME="aosp-clang-latest.tar.gz"
    LATEST_CLANG_DIR=$(curl -sL "$PREBUILTS_URL" | grep -oP 'clang-r[a-z0-9]+(?=/")' | sort -V | tail -n 1)

    if [ -z "$LATEST_CLANG_DIR" ]; then
        echo "Error: Could not determine the latest clang version from the AOSP repository."
        echo "Please check the URL: $PREBUILTS_URL"
        exit 1
    fi

    echo "Latest version found: $LATEST_CLANG_DIR"
    DOWNLOAD_URL="${CDN_URL}${LATEST_CLANG_DIR}.tar.gz"

    echo "Downloading from: $DOWNLOAD_URL"
    curl --progress-bar -L -o "$TARBALL_NAME" "$DOWNLOAD_URL"
    echo "Download complete. Extracting toolchain..."
    mkdir -p "$EXTRACT_DIR"
    rm -rf "${EXTRACT_DIR:?}"/*
    tar -xzf "$TARBALL_NAME" -C "$EXTRACT_DIR"
    rm "$TARBALL_NAME"
    ABS_EXTRACT_DIR=$(pwd)/$EXTRACT_DIR
    echo "job done!"

  else 
    echo "Toolchain already exists. Skipping download."
  fi
  }

function make_ak3_zip(){
  #i don't really use this but ig a lot of people do and its nice for distribution.
  BASE_OUT=$(pwd)/out/arch/arm64/boot
  #modify ak3 zip name to include device codename. we can check the current branch and check if it includes "kebab". if it does then we know it for 8t. otherwise 8/pro.
  #i don't know why but apparently sm8250 diverges now but whatever.
  if [[ $(git rev-parse --abbrev-ref HEAD) == *"kebab"* ]]; then
    DEVICE="kebab"
  else
    DEVICE="noodle"
  fi
  ZIP_NAME="AK3-pearl-$DEVICE-$(date +%Y%m%d-%H%M).zip"
  cp $BASE_OUT/Image $BASE_OUT/dtbo.img $BASE_OUT/dtb $(pwd)/anykernel
  cd anykernel 
  zip -r9 $ZIP_NAME * -x README $ZIP_NAME
  rm Image dtbo.img dtb
  mv $ZIP_NAME ..
}

download_toolchain

export KBUILD_BUILD_HOST=$(uname -a | awk '{print $2}')
export C_PATH="$(pwd)/aospclang"
export PATH="$COREUTILS_DIR/bin:$GZIP_DIR/bin:$C_PATH/bin:$PATH"
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_COMPAT=arm-linux-gnueabi-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-

BUILD_SETTINGS="LLVM=1 
                LLVM_IAS=1 
                CC=clang
                AR=llvm-ar 
                NM=llvm-nm 
                LD=ld.lld 
                STRIP=llvm-strip 
                OBJCOPY=llvm-objcopy 
                OBJDUMP=llvm-objdump 
                KCFLAGS=-O3 
                OBJSIZE=llvm-size 
                HOSTCC=clang 
                HOSTCXX=clang++ 
                HOSTAR=llvm-ar 
                HOSTLD=ld.lld  
                CROSS_COMPILE=aarch64-linux-gnu- 
                CROSS_COMPILE_COMPAT=arm-linux-gnueabi- 
                CROSS_COMPILE_ARM32=arm-linux-gnueabi-"

make O=out ARCH=arm64 PATH="$COREUTILS_DIR/bin:$GZIP_DIR/bin:$C_PATH/bin:$PATH" $BUILD_SETTINGS vendor/meteoric_defconfig
make O=out -j$(nproc --all) PATH="$COREUTILS_DIR/bin:$GZIP_DIR/bin:$C_PATH/bin:$PATH" $BUILD_SETTINGS

#check if anykernel exists and make a zip if it does
if [ -d "anykernel" ]; then
  make_ak3_zip
fi
