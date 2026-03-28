#!/bin/bash

#
# This script automates the build process for Android legacy kernels
# (versions prior to Android 13) that rely on the build/build.sh system.
#

KERNEL_DIR=$1

if [ -z "$KERNEL_DIR" ]; then
    echo "Usage: $0 <kernel_dir>"
    exit 1
fi

cd "$KERNEL_DIR"

BUILD_CONFIG=common/build.config.gki.aarch64
OUT_DIR=out/$(basename "$KERNEL_DIR")

echo "[*] Kernel dir: $KERNEL_DIR"

echo "[*] Generating base config..."
OUT_DIR=$OUT_DIR BUILD_CONFIG=$BUILD_CONFIG build/build.sh

CONFIG_FILE=$OUT_DIR/.config

if [ ! -f "$CONFIG_FILE" ]; then
    echo "[!] .config not found"
    exit 1
fi

echo "[*] Applying config..."

# enable for cuttlefish emulator
./scripts/config --file "$CONFIG_FILE" --enable SERIAL_AMBA_PL011
./scripts/config --file "$CONFIG_FILE" --enable VIRTIO
./scripts/config --file "$CONFIG_FILE" --enable VIRTIO_BLK
./scripts/config --file "$CONFIG_FILE" --enable VIRTIO_NET
./scripts/config --file "$CONFIG_FILE" --enable VIRTIO_CONSOLE

./scripts/config --file "$CONFIG_FILE" --enable DEVTMPFS
./scripts/config --file "$CONFIG_FILE" --enable DEVTMPFS_MOUNT
./scripts/config --file "$CONFIG_FILE" --enable BLK_DEV_INITRD

./scripts/config --file "$CONFIG_FILE" --enable DEBUG_INFO

# kasan (memory error detection)
./scripts/config --file "$CONFIG_FILE" --enable KASAN
./scripts/config --file "$CONFIG_FILE" --enable KASAN_GENERIC
./scripts/config --file "$CONFIG_FILE" --enable KASAN_INLINE
./scripts/config --file "$CONFIG_FILE" --enable STACKTRACE

# ubsan (undefined behavior detection)
./scripts/config --file "$CONFIG_FILE" --enable UBSAN
./scripts/config --file "$CONFIG_FILE" --enable UBSAN_TRAP
./scripts/config --file "$CONFIG_FILE" --enable UBSAN_BOUNDS

# kcsan (data race detection)
./scripts/config --file "$CONFIG_FILE" --enable KCSAN
./scripts/config --file "$CONFIG_FILE" --enable KCSAN_VERBOSE

# kgdb / gdb (kernel debugging)
./scripts/config --file "$CONFIG_FILE" --enable KGDB
./scripts/config --file "$CONFIG_FILE" --enable KGDB_SERIAL_CONSOLE
./scripts/config --file "$CONFIG_FILE" --enable KGDB_KDB
./scripts/config --file "$CONFIG_FILE" --enable DEBUG_INFO
./scripts/config --file "$CONFIG_FILE" --enable GDB_SCRIPTS

# ftrace (function tracing)
./scripts/config --file "$CONFIG_FILE" --enable FTRACE
./scripts/config --file "$CONFIG_FILE" --enable FUNCTION_TRACER
./scripts/config --file "$CONFIG_FILE" --enable FUNCTION_GRAPH_TRACER
./scripts/config --file "$CONFIG_FILE" --enable DYNAMIC_FTRACE
./scripts/config --file "$CONFIG_FILE" --enable TRACING

# kprobes (dynamic instrumentation)
./scripts/config --file "$CONFIG_FILE" --enable KPROBES
./scripts/config --file "$CONFIG_FILE" --enable KPROBE_EVENTS

# ebpf (in-kernel programs)
./scripts/config --file "$CONFIG_FILE" --enable BPF
./scripts/config --file "$CONFIG_FILE" --enable BPF_SYSCALL
./scripts/config --file "$CONFIG_FILE" --enable BPF_JIT
./scripts/config --file "$CONFIG_FILE" --enable BPF_EVENTS

# printk (logging)
./scripts/config --file "$CONFIG_FILE" --enable PRINTK
./scripts/config --file "$CONFIG_FILE" --enable PRINTK_TIME
./scripts/config --file "$CONFIG_FILE" --enable EARLY_PRINTK

# slub / slab debugging (allocator checks)
./scripts/config --file "$CONFIG_FILE" --enable SLUB_DEBUG
./scripts/config --file "$CONFIG_FILE" --enable SLUB_DEBUG_ON
./scripts/config --file "$CONFIG_FILE" --enable SLAB_FREELIST_HARDENED
./scripts/config --file "$CONFIG_FILE" --enable SLAB_FREELIST_RANDOM

# general debug infrastructure
./scripts/config --file "$CONFIG_FILE" --enable DEBUG_KERNEL
./scripts/config --file "$CONFIG_FILE" --enable DEBUG_FS
./scripts/config --file "$CONFIG_FILE" --enable MAGIC_SYSRQ
./scripts/config --file "$CONFIG_FILE" --enable LOCKDEP
./scripts/config --file "$CONFIG_FILE" --enable PROVE_LOCKING

# finalize config
make O=$OUT_DIR olddefconfig

# Step 2: rebuild
echo "[*] Rebuilding..."
make O=$OUT_DIR -j$(nproc)

echo "[✓] Done"

echo "Kernel: $OUT_DIR/arch/arm64/boot/Image"
echo "vmlinux: $OUT_DIR/vmlinux"