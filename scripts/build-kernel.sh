#!/bin/bash
# This script generates the .config from defconfig and builds the kernel.

# Set environment variables for KSU and CLEAN_BUILD
KSU_ENABLED=${KSU_ENABLED:-false}
CLEAN_BUILD=${CLEAN_BUILD:-false}

# Generate .config from defconfig
make defconfig

# Check if CLEAN_BUILD is set to true
if [ "$CLEAN_BUILD" = true ]; then
    make clean
fi

# Start kernel build without interactive prompts
make -s -j$(nproc) all

# Handle KSU if enabled
if [ "$KSU_ENABLED" = true ]; then
    echo "KSU is enabled!"
fi
