# Android Kernel Debugging

> This repository provides a streamlined, containerized environment for researching and debugging vulnerabilities (CVEs) in the Android Generic Kernel Image (GKI).

## Directory Structure

| Directory         | Description                                                                              |
| ----------------- | ---------------------------------------------------------------------------------------- |
| `aosp-userspace/` | Prebuilt or custom AOSP images (Cuttlefish / Emulator / Physical device).                |
| `docker/`         | Dockerfiles for specific kernel versions to ensure reproducible builds.                  |
| `kernels/`        | GKI source code managed via `repo`. Follows `common-android<version>-<kernel>` naming.   |
| `scripts/`        | Automation for building kernels, merging `.fragment` configs, and generating `boot.img`. |
| `workspace/`      | Working directory for PoCs, `vmlinux`, symbols, exploit code, and debug logs.            |
| `config/`         | Kernel config fragments (`.fragment`) for enabling debug features and instrumentation.   |

## Build System Evolution

| Android Version   | GKI Kernel  | Android Clang Version                                                                                                       | Equivalent LLVM |
| ----------------- | ----------- | --------------------------------------------------------------------------------------------------------------------------- | --------------- |
| Android 16 (2025) | 6.12        | [clang-r547379](https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+/refs/heads/main/clang-r547379)   | LLVM 19.x       |
| Android 15 (2024) | 6.6         | [clang-r522817](https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+/refs/heads/master/clang-r522817) | LLVM 18.x       |
| Android 14 (2023) | 6.1         | [clang-r487747c](https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+/refs/heads/android14-release/clang-r487747c/)                                                                                                             | LLVM 17.x       |
| Android 13 (2022) | 5.10 / 5.15 | [clang-r450784d](https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+/a71fa4c09d7109d611ee63964fc9fca58fee38cd/clang-r450784d/)                                                                                                             | LLVM 14.x       |
| Android 12 (2021) | 5.10        | [clang-r416183b1](https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+/428d18d9732aa7ebfcaed87a582d86155db878d4/clang-r416183b/)                                                                                                             | LLVM 12.x       |

## Workflow

### 1. Download AOSP Userspace

> Prebuilt userspace images are sufficient for kernel-level debugging only. Debugging framework, system services, or SELinux requires a full AOSP build.

Download userspace from [Android CI](https://ci.android.com/builds/branches/aosp-android-latest-release/grid?legacy=1):

Steps:

- Select a branch matching your Android version
- Choose target: `aosp_cf_x86_64_only_phone`
- Select a build ID aligned with the vulnerable kernel timeframe
- Download `aosp_cf_x86_64_only_phone-img-*.zip`

Extract into: `aosp-userspace/`

### 2. Download and Build GKI Kernel

Initialize and sync kernel source:

```bash
repo init -u https://android.googlesource.com/kernel/manifest
repo sync
```

Checkout the appropriate branch:

```bash
cd kernels/common
git checkout <target-branch>
```

> Ensure the checkout is at a revision prior to the patch commit for the CVE under analysis.

Build using the appropriate Docker environment:

```bash
cd docker/<kernel-version>
docker build -t gki-builder .
docker run -it -v $(pwd)/../../kernels:/kernels gki-builder
```

Ensure the correct Clang version and GKI configuration are used.

### 3. Configure Kernel for Debugging

Typical configuration options:

- `CONFIG_KALLSYMS=y`
- `CONFIG_KALLSYMS_ALL=y`
- `CONFIG_DEBUG_INFO=y`
- `CONFIG_KPROBES=y`
- `CONFIG_BPF=y` (if required)

Merge configuration fragments:

```bash
./scripts/kconfig/merge_config.sh
```

### 4. Launch Using Cuttlefish

Launch the virtual device with the custom kernel:

```bash
launch_cvd \
  --kernel_path=./out/bzImage \
  --initramfs_path=./out/initramfs.img
```

Ensure KVM is enabled and host dependencies are satisfied.

### 5. Debugging Workflow

Common tools and methods:

- `dmesg` and `logcat` for logs
- `adb shell` for interaction
- `gdb` with `vmlinux` for symbolized debugging
- `kprobes` and `ftrace` for tracing

Workspace layout:

```
workspace/
 ├── poc/
 ├── logs/
 └── scripts/
```
