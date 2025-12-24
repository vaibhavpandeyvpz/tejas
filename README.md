# Tejas Linux

**Tejas Linux** is a lightweight, secure, Ubuntu-based Linux distribution built using a **custom, fully transparent ISO build pipeline** based on **debootstrap, Casper, GRUB, and xorriso**.

Tejas intentionally avoids fragile legacy tooling in favor of an explicit, reproducible, and inspectable build system, while remaining fully compatible with the Ubuntu ecosystem.

---

## Overview

Tejas Linux is designed for users who value:

- A clean and fast desktop experience
- Strong Secure Boot guarantees without custom keys
- A modern installer
- Deterministic, auditable build processes
- Long-term maintainability over convenience tooling

---

## Key Highlights

- Lightweight XFCE desktop environment
- Single ISO supporting:
  - UEFI
  - Secure Boot
  - Legacy BIOS

- Secure Boot enabled by default (no custom keys or enrollment)
- Two editions: User and Pro
- Calamares graphical installer
- CI-built ISOs using GitHub Actions
- GPG-signed releases
- No `live-build`, no `syslinux`, no legacy boot hacks

---

## Editions

Tejas Linux is published in two editions built from the same base system.

| Edition | Intended for             | Differences                          |
| ------- | ------------------------ | ------------------------------------ |
| User    | General users            | Minimal system, no dev tools or docs |
| Pro     | Developers / power users | Compilers, headers, man pages        |

Both editions share:

- The same kernel
- The same Secure Boot chain
- The same installer
- The same branding and defaults

---

## Boot and Firmware Support

Tejas Linux supports modern and legacy boot environments from a **single ISO**.

| Boot mode     | Supported |
| ------------- | --------- |
| UEFI          | Yes       |
| Secure Boot   | Yes       |
| Legacy BIOS   | Yes       |
| VMware        | Yes       |
| QEMU          | Yes       |
| Ventoy        | Yes       |
| Real hardware | Yes       |

### Secure Boot Trust Chain

```
UEFI firmware
 └── shimx64.efi (Microsoft-signed)
       └── grubx64.efi (Canonical-signed)
             └── Linux kernel (Canonical-signed)
```

- No custom Secure Boot keys
- No user enrollment required
- Same trust chain used by Ubuntu Desktop

> Note: Legacy BIOS boot is supported via GRUB’s El Torito mechanism.
> UEFI (with or without Secure Boot) is the primary and recommended boot method.

---

## Installer

Tejas Linux uses **Calamares**, a modern graphical installer.

Installer features include:

- Guided and manual partitioning
- Dual-boot support
- Secure Boot-safe bootloader installation
- User, locale, and keyboard configuration
- Offline installation of Secure Boot packages (no internet required)

The installer can be launched:

- Automatically in the live session, or
- Manually via **"Install Tejas Linux"** on the desktop

**Note:** The default locale is set to Indian English (`en_IN.UTF-8`), with support for multiple Indian languages (Hindi, Bengali, Tamil, Telugu, Marathi, Gujarati, Kannada, Malayalam, Punjabi, Urdu).

---

## Secure Boot and Proprietary Drivers

- Secure Boot works out of the box
- Ubuntu’s signed kernel and bootloader are used
- Proprietary drivers (for example, NVIDIA) may trigger **MOK enrollment**
  - This is expected behavior
  - Required only once per system

---

## Verifying Downloads (Important)

All Tejas Linux releases are cryptographically signed.

### Release Signing Key

Tejas Linux releases are signed using the following GPG key:

- Key type: RSA 4096
- Key ID: `A3F982C55AD5DA0B`
- The full fingerprint is published in this repository

---

### Import the Public Key

From this repository:

```bash
gpg --import tejas-linux-public.key
```

Or from the Ubuntu keyserver:

```bash
gpg --keyserver keyserver.ubuntu.com --recv-keys A3F982C55AD5DA0B
```

Verify the fingerprint:

```bash
gpg --fingerprint A3F982C55AD5DA0B
```

---

### Verify the ISO Signature

```bash
gpg --verify tejas-linux.iso.sig tejas-linux.iso
```

Expected output:

```
Good signature from "Tejas Linux Release Signing Key"
```

---

### Verify the Checksum

```bash
sha256sum -c tejas-linux.iso.sha256
```

Expected result:

```
OK
```

Only use the ISO if **both checks succeed**.

---

## Quick Start

1. Download the latest ISO from:
   [https://github.com/vaibhavpandeyvpz/tejas/releases](https://github.com/vaibhavpandeyvpz/tejas/releases)

2. Verify the ISO (GPG signature and SHA256 checksum)

3. Write the ISO to a USB drive:

   ```bash
   sudo dd if=tejas-linux.iso of=/dev/sdX bs=4M status=progress oflag=sync
   ```

4. Boot on any modern UEFI system (Secure Boot supported)

---

## Build System (For Contributors)

Tejas Linux does **not** use `live-build`.

Instead, it uses a custom, deterministic pipeline:

```
debootstrap → casper → GRUB (BIOS + UEFI) → xorriso
```

### Build Process Overview

The build process consists of 19 steps:

1. **Bootstrap** - Create base root filesystem using debootstrap
2. **Configure APT** - Set up Ubuntu repositories
3. **Mount virtual filesystems** - Prepare chroot environment
4. **Configure debconf** - Set non-interactive defaults
5. **Install offline packages** - Install Secure Boot packages (grub-efi-amd64-signed, shim-signed)
6. **Create APT repository** - Build local repository in ISO with GPG signing
7. **Create apt-cdrom metadata** - Add `.disk/` directory for CD-ROM detection
8. **Install base packages** - Install core system packages
9. **Apply rootfs overlay** - Copy custom configuration files
10. **Install profile packages** - Install edition-specific packages
11. **Run hooks** - Execute customization scripts
12. **Reset debconf** - Clear build-time settings
13. **Configure networking** - Set up NetworkManager for live session
14. **Generate manifest** - Create package manifest
15. **Copy kernel/initrd** - Extract boot files
16. **Unmount filesystems** - Clean up chroot mounts
17. **Create squashfs** - Compress root filesystem
18. **Install EFI binaries** - Copy Secure Boot binaries
19. **Create ISO** - Generate final ISO image

### Rationale

`live-build` was intentionally avoided due to:

- Broken hybrid ISO support on modern Ubuntu
- Obsolete syslinux and gfxboot dependencies
- Poor VMware compatibility
- Fragile and opaque CI behavior

The custom pipeline provides:

- Full control over boot layout
- Reliable Secure Boot support
- Predictable, debuggable builds
- Offline package installation support

### Offline Package Installation

Tejas Linux includes an **embedded APT repository** in the ISO that enables offline installation of Secure Boot packages during system installation. This feature:

- **No internet required** - Secure Boot packages (GRUB, shim) are installed from the ISO
- **GPG-signed repository** - The repository is automatically signed during build
- **Automatic detection** - The installer uses `apt-cdrom` to detect and add the ISO as a repository source
- **Trusted by default** - The signing key is included in the installed system's trusted keyring

This ensures Secure Boot works even on systems without internet connectivity during installation.

---

## Hooks and System Customization

Tejas Linux uses explicit chroot hooks instead of live-build hooks.

Hooks are simple shell scripts that run **inside the root filesystem** during the build.

### Hook Location

```
iso/config/hooks/
```

Hooks are:

- Executed in lexical order
- Fully controlled by the project
- Easy to debug and audit

Typical responsibilities include:

- Locale and timezone configuration
- Branding (hostname, `/etc/issue`)
- Stripping documentation and man pages (User edition)
- Cleanup before squashfs creation

---

## Building Locally

Tejas Linux can be built either natively on Ubuntu or using Docker (recommended for non-Ubuntu systems).

### Option 1: Using Docker (Recommended)

Docker provides an isolated build environment that works on any Linux distribution, macOS, or Windows.

**How it works:** The project code is bundled into the Docker image, and the build runs entirely inside the container's filesystem. Only the `iso/out` directory is mounted to save the final ISO on your host system. This approach avoids filesystem compatibility issues, especially on Windows.

#### Prerequisites

- Docker installed and running
- At least 10GB free disk space

#### Build Steps

**Option A: Using the helper script (recommended):**

```bash
# Build User Edition
./docker-build.sh user

# Build Pro Edition
./docker-build.sh pro
```

**Option B: Manual Docker commands:**

1. **Build the Docker image (includes project code):**

   ```bash
   docker build -t tejas-builder .
   ```

2. **Build User Edition:**

   ```bash
   mkdir -p iso/out
   docker run --rm --privileged \
     -v "$(pwd)/iso/out:/workspace/iso/out" \
     -w /workspace \
     -e PROFILE=user \
     tejas-builder \
     sudo /workspace/iso/build.sh
   ```

3. **Build Pro Edition:**

   ```bash
   mkdir -p iso/out
   docker run --rm --privileged \
     -v "$(pwd)/iso/out:/workspace/iso/out" \
     -w /workspace \
     -e PROFILE=pro \
     tejas-builder \
     sudo /workspace/iso/build.sh
   ```

**Note:**

- The `--privileged` flag is required for mount operations during the build process.
- The Docker image is automatically rebuilt each time (Docker's layer caching makes this fast if nothing changed).
- Only `iso/out` is mounted, so the final ISO is saved on your host system.

**Output:**

The built ISO will be available in `iso/out/`:

```
iso/out/
├── tejas-linux-<version>-user-amd64.iso
└── tejas-linux-<version>-pro-amd64.iso
```

---

### Building on Windows

Windows users have two options for building Tejas Linux:

#### Option A: Using WSL2 (Recommended)

**WSL2** (Windows Subsystem for Linux) provides the best experience for building on Windows.

1. **Install WSL2:**
   - Open PowerShell as Administrator and run:
     ```powershell
     wsl --install
     ```
   - Or follow the [official WSL2 installation guide](https://learn.microsoft.com/en-us/windows/wsl/install)

2. **Install Docker in WSL2:**

   ```bash
   # In WSL2 (Ubuntu)
   sudo apt update
   sudo apt install -y docker.io
   sudo service docker start
   sudo usermod -aG docker $USER
   ```

   Then follow the Docker build instructions above.

3. **Alternative: Use native Ubuntu build in WSL2:**

   If you prefer not to use Docker, you can install the build dependencies directly in WSL2 and follow the "Native Ubuntu Build" instructions below.

#### Option B: Using Docker Desktop for Windows

1. **Install Docker Desktop:**
   - Download and install [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)
   - Ensure WSL2 backend is enabled in Docker Desktop settings

2. **Build using PowerShell or Command Prompt:**

   **Using the PowerShell helper script (recommended):**

   ```powershell
   # Build User Edition
   .\docker-build.ps1 user

   # Build Pro Edition
   .\docker-build.ps1 pro
   ```

   **Note:** If you encounter an execution policy error, run:

   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

   **Using the bash helper script (in Git Bash or WSL2):**

   ```bash
   ./docker-build.sh user
   ```

   **Using Docker commands directly (PowerShell):**

   ```powershell
   # Build the Docker image (includes project code)
   docker build -t tejas-builder .

   # Ensure output directory exists
   New-Item -ItemType Directory -Path "iso\out" -Force

   # Build User Edition
   docker run --rm --privileged `
     -v "${PWD}\iso\out:/workspace/iso/out" `
     -w /workspace `
     -e PROFILE=user `
     tejas-builder `
     sudo /workspace/iso/build.sh

   # Build Pro Edition
   docker run --rm --privileged `
     -v "${PWD}\iso\out:/workspace/iso/out" `
     -w /workspace `
     -e PROFILE=pro `
     tejas-builder `
     sudo /workspace/iso/build.sh
   ```

   **Note:**
   - In PowerShell, use backticks (`) for line continuation instead of backslashes.
   - The project code is bundled into the Docker image, avoiding Windows filesystem mount issues.
   - Only `iso/out` is mounted to save the final ISO on Windows.

**Windows-specific considerations:**

- **No filesystem issues:** Project code runs inside the container's filesystem, avoiding Windows mount compatibility problems
- **File permissions:** The built ISO will have appropriate permissions set by the container
- **Performance:** Build runs entirely in container filesystem for optimal performance
- **Disk space:** Ensure you have at least 15GB free space (build process + Docker images)
- **Automatic rebuild:** The Docker image is automatically rebuilt each run to ensure latest code is included (Docker's layer caching keeps it fast)

**Troubleshooting:**

- **Image rebuild:** The Docker image is automatically rebuilt each time you run the build script. Docker's layer caching makes this fast if your code hasn't changed.

- **Disk space issues:** If you encounter `debootstrap` errors, ensure you have at least 10GB free disk space and try `docker system prune -a` to free space.

- **Windows filesystem issues:** The current approach bundles code into the image, avoiding Windows mount issues. If problems persist, ensure Docker Desktop has sufficient resources allocated.

---

### Option 2: Native Ubuntu Build

#### Prerequisites

```bash
sudo apt install -y \
  apt-utils \
  debootstrap \
  gnupg \
  grub-efi-amd64-signed \
  mtools \
  rsync \
  shim-signed \
  squashfs-tools \
  xorriso
```

**Note:**

- `apt-utils` (includes `apt-ftparchive`) and `gnupg` are required for creating and signing the embedded APT repository in the ISO.
- `grub-efi-amd64-signed` and `shim-signed` are needed for Secure Boot EFI binaries.
- Other GRUB packages and Calamares are installed during the build process from the root filesystem.

#### Build User Edition

```bash
PROFILE=user sudo iso/build.sh
```

#### Build Pro Edition

```bash
PROFILE=pro sudo iso/build.sh
```

**Output:**

```
iso/out/
├── tejas-linux-<version>-user-amd64.iso
└── tejas-linux-<version>-pro-amd64.iso
```

---

## Testing with QEMU

You can test the built ISO locally using QEMU before deploying to real hardware.

### Prerequisites

Install QEMU and OVMF firmware:

**On Ubuntu/Debian:**

```bash
sudo apt install -y qemu-system-x86 ovmf
```

**On macOS (Homebrew):**

```bash
brew install qemu
```

**On Fedora/RHEL:**

```bash
sudo dnf install -y qemu-system-x86 edk2-ovmf
```

### Create a Virtual Disk

```bash
# Create a 10GB qcow2 disk image
qemu-img create -f qcow2 ~/QEMU/tejas.qcow2 10G
```

> **Note:** Adjust the path (`~/QEMU/`) to your preferred location.

### Run the ISO in QEMU

**On Linux:**

```bash
qemu-system-x86_64 \
  -machine q35 \
  -m 2048 \
  -smp 4 \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd \
  -drive if=pflash,format=raw,file=/usr/share/OVMF/OVMF_VARS.fd \
  -cdrom iso/out/tejas-linux-2025.12.23-user-amd64.iso \
  -drive file=~/QEMU/tejas.qcow2,if=virtio \
  -device virtio-vga \
  -device qemu-xhci \
  -device usb-tablet
```

**On macOS (Homebrew):**

```bash
qemu-system-x86_64 \
  -machine q35 \
  -m 2048 \
  -smp 4 \
  -drive if=pflash,format=raw,readonly=on,file=/opt/homebrew/share/qemu/edk2-x86_64-code.fd \
  -drive if=pflash,format=raw,file=/opt/homebrew/share/qemu/edk2-x86_64-vars.fd \
  -cdrom iso/out/tejas-linux-2025.12.23-user-amd64.iso \
  -drive file=~/QEMU/tejas.qcow2,if=virtio \
  -device virtio-vga \
  -device qemu-xhci \
  -device usb-tablet
```

**Finding OVMF firmware paths:**

- **Linux (Ubuntu/Debian):** `/usr/share/OVMF/OVMF_CODE.fd` and `/usr/share/OVMF/OVMF_VARS.fd`
- **Linux (Fedora/RHEL):** `/usr/share/edk2/ovmf/OVMF_CODE.fd` and `/usr/share/edk2/ovmf/OVMF_VARS.fd`
- **macOS (Homebrew):** `/opt/homebrew/share/qemu/edk2-x86_64-code.fd` and `/opt/homebrew/share/qemu/edk2-x86_64-vars.fd`
- **macOS (MacPorts):** `/opt/local/share/qemu/edk2-x86_64-code.fd` and `/opt/local/share/qemu/edk2-x86_64-vars.fd`

**Command options explained:**

- `-machine q35`: Modern Q35 chipset (better UEFI support)
- `-m 2048`: 2GB RAM (adjust as needed)
- `-smp 4`: 4 CPU cores (adjust as needed)
- `-drive if=pflash`: OVMF firmware for UEFI boot
- `-cdrom`: ISO file to boot from
- `-drive file=...`: Virtual disk for installation
- `-device virtio-vga`: VirtIO graphics (better performance)
- `-device qemu-xhci`: USB 3.0 controller
- `-device usb-tablet`: USB tablet for better mouse integration

**Note:** Replace `tejas-linux-2025.12.23-user-amd64.iso` with your actual ISO filename.

---

## Continuous Integration

Tejas Linux ISOs are built automatically using GitHub Actions.

Each CI run produces:

- User edition ISO
- Pro edition ISO
- SHA256 checksums
- GPG signatures

All artifacts are uploaded and verifiable.

### Build Features

The CI build process includes:

- **Automatic GPG key generation** - A signing key is generated for each build to sign the embedded APT repository
- **Repository signing** - The ISO's APT repository is signed with a clearsigned `InRelease` file
- **Key distribution** - The public key is automatically included in the installed system's trusted keyring
- **Offline support** - Secure Boot packages can be installed without internet connectivity

---

## Repository Structure

```text
iso/
├── build.sh
├── config/
│   ├── rootfs/          # overlay (committed)
│   │   └── etc/
│   │       ├── apt/trusted.gpg.d/  # GPG key for repository signing
│   │       └── calamares/          # Installer configuration
│   ├── hooks/           # Build-time customization scripts
│   └── profiles/        # Package lists (base, user, pro, offline)
├── image/
│   ├── EFI/BOOT/        # Secure Boot EFI binaries
│   ├── boot/grub/       # GRUB configuration
│   ├── casper/          # Live filesystem (generated)
│   ├── dists/           # APT repository metadata (generated)
│   ├── pool/            # Debian packages (generated)
│   └── .disk/           # apt-cdrom metadata (generated)
├── rootfs/              # Root filesystem (generated, ignored)
└── out/                 # Final ISO (generated, ignored)
```

---

## Known Limitations and Non-Goals

- Tejas Linux currently targets **amd64 (x86_64)** systems only
- ARM / aarch64 builds are not yet provided
- Secure Boot relies on Ubuntu's signed boot chain (no custom keys)

These are conscious design decisions.

---

## Security

For reporting security vulnerabilities, please see [`SECURITY.md`](SECURITY.md).

Do **not** report security issues via public GitHub issues.

Project security contact: **[tejas.linux@vaibhavpandey.com](mailto:tejas.linux@vaibhavpandey.com)**

---

## Licensing

Tejas Linux is licensed under the **GNU General Public License v3.0 (GPL-3.0)**.

- All Tejas-specific scripts, build logic, and configuration in this repository are licensed under GPL-3.0, as described in the `LICENSE` file.
- Tejas Linux redistributes unmodified Ubuntu packages, which remain under their respective upstream licenses.
- Trademarks, logos, and brand names belong to their respective owners.

Tejas Linux is **not affiliated with or endorsed by Canonical**.

---

## Contributing

Contributions are welcome, including:

- Bug reports
- Documentation improvements
- Package suggestions
- CI improvements
- UX and branding enhancements

Please open an issue before making large or breaking changes.

---

## Project Status

Tejas Linux is under active development.

Current focus areas:

- Stability
- Hardware compatibility
- Clean user experience
- First stable public release

---

## Links

- Repository: [https://github.com/vaibhavpandeyvpz/tejas](https://github.com/vaibhavpandeyvpz/tejas)
- Issues: [https://github.com/vaibhavpandeyvpz/tejas/issues](https://github.com/vaibhavpandeyvpz/tejas/issues)
- Releases: [https://github.com/vaibhavpandeyvpz/tejas/releases](https://github.com/vaibhavpandeyvpz/tejas/releases)

---

## Philosophy

Tejas Linux is built deliberately and transparently.

- No fragile tooling
- No legacy bootloaders
- No hidden magic

Just a clean, modern, Ubuntu-based distribution that can be inspected, verified, and trusted.
