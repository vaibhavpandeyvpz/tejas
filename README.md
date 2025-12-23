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
- Two editions: User and Developer
- Calamares graphical installer
- CI-built ISOs using GitHub Actions
- GPG-signed releases
- No `live-build`, no `syslinux`, no legacy boot hacks

---

## Editions

Tejas Linux is published in two editions built from the same base system.

| Edition   | Intended for             | Differences                          |
| --------- | ------------------------ | ------------------------------------ |
| User      | General users            | Minimal system, no dev tools or docs |
| Developer | Developers / power users | Compilers, headers, man pages        |

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

The installer can be launched:

- Automatically in the live session, or
- Manually via **“Install Tejas Linux”** on the desktop

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

# Build Developer Edition
./docker-build.sh developer
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

3. **Build Developer Edition:**

   ```bash
   mkdir -p iso/out
   docker run --rm --privileged \
     -v "$(pwd)/iso/out:/workspace/iso/out" \
     -w /workspace \
     -e PROFILE=developer \
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
└── tejas-linux-<version>-developer-amd64.iso
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

   # Build Developer Edition
   .\docker-build.ps1 developer
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

   # Build Developer Edition
   docker run --rm --privileged `
     -v "${PWD}\iso\out:/workspace/iso/out" `
     -w /workspace `
     -e PROFILE=developer `
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
  debootstrap \
  squashfs-tools \
  xorriso \
  grub-efi-amd64-bin \
  grub-efi-amd64-signed \
  grub-pc-bin \
  grub-common \
  shim-signed \
  casper \
  calamares \
  mtools \
  rsync
```

#### Build User Edition

```bash
PROFILE=user sudo iso/build.sh
```

#### Build Developer Edition

```bash
PROFILE=developer sudo iso/build.sh
```

**Output:**

```
iso/out/
├── tejas-linux-<version>-user-amd64.iso
└── tejas-linux-<version>-developer-amd64.iso
```

---

## Continuous Integration

Tejas Linux ISOs are built automatically using GitHub Actions.

Each CI run produces:

- User edition ISO
- Developer edition ISO
- SHA256 checksums
- GPG signatures

All artifacts are uploaded and verifiable.

---

## Repository Structure

```text
iso/
├── build.sh
├── config/
│   ├── rootfs/          # overlay (committed)
│   ├── hooks/
│   └── profiles/
├── image/
│   ├── EFI/BOOT/
│   ├── boot/grub/
│   ├── casper/          # generated
│   └── .disk/
├── rootfs/              # generated (ignored)
└── out/                 # generated (ignored)
```

---

## Known Limitations and Non-Goals

- Tejas Linux currently targets **amd64 (x86_64)** systems only
- ARM / aarch64 builds are not yet provided
- Secure Boot relies on Ubuntu’s signed boot chain (no custom keys)
- Snap is not enabled by default

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
