#!/usr/bin/env bash
set -e

echo "=== Applying CI-friendly KernelSU & SELinux patches ==="

# Disable SELinux in kernel config
scripts/config --disable SECURITY_SELINUX
scripts/config --disable SECURITY

# Comment out problematic KernelSU macro to avoid MODULE_IMPORT_NS errors
sed -i 's/MODULE_IMPORT_NS(VFS_internal_I_am_really_a_filesystem_and_am_NOT_a_driver);/\/\* MODULE_IMPORT_NS disabled for CI \*\//' kernel/ksu.c

# Optional: comment out any other SELinux includes that cause missing header errors
find security/selinux/include -name "*.h" -exec sed -i 's/#include "flask.h"/\/\/ #include "flask.h"/' {} +

echo "=== Patches applied successfully ==="
