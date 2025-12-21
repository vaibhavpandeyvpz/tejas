# Tejas Linux

**Tejas Linux** is a lightweight, fast, and secure Linux distribution based on **Ubuntu**, built using a **custom ISO pipeline** with **debootstrap, Casper, GRUB, and xorriso**.

Tejas intentionally avoids fragile legacy tooling in favor of an explicit, reproducible, and inspectable build system — while remaining fully compatible with the Ubuntu ecosystem.

---

## ✨ Key Highlights

- ⚡ Lightweight **XFCE** desktop
- 💿 **Single ISO** supporting:
  - UEFI
  - Secure Boot
  - Legacy BIOS

- 🔐 Secure Boot enabled by default (no custom keys)
- 🧑‍💻 **Two editions**: User & Developer
- 🖥️ **Calamares** graphical installer
- 🤖 CI-built ISOs via GitHub Actions
- 🔏 **GPG-signed releases**
- 🧼 No `live-build`, no `syslinux`, no legacy hacks

---

## 📦 Editions

Tejas Linux is published in two editions built from the same base system.

| Edition       | Intended for             | Differences                          |
| ------------- | ------------------------ | ------------------------------------ |
| **User**      | General users            | Minimal system, no dev tools or docs |
| **Developer** | Developers / power users | Compilers, headers, man pages        |

Both editions share:

- Same kernel
- Same Secure Boot chain
- Same installer
- Same branding and defaults

---

## 💿 Boot & Firmware Support

Tejas Linux supports **all modern boot environments** from a **single ISO**.

| Boot mode     | Supported |
| ------------- | --------- |
| UEFI          | ✅        |
| Secure Boot   | ✅        |
| Legacy BIOS   | ✅        |
| VMware        | ✅        |
| QEMU          | ✅        |
| Ventoy        | ✅        |
| Real hardware | ✅        |

### Secure Boot Trust Chain

```
UEFI firmware
 └── shimx64.efi (Microsoft-signed)
       └── grubx64.efi (Canonical-signed)
             └── Linux kernel (Canonical-signed)
```

- No custom keys
- No user enrollment required
- Same trust chain as Ubuntu Desktop

---

## 🖥️ Installer

Tejas Linux uses **Calamares**, a modern graphical installer.

Installer features:

- Guided & manual partitioning
- Dual-boot support
- Secure Boot-safe bootloader installation
- User, locale, and keyboard configuration

The installer can be launched:

- Automatically in the live session, or
- Manually via **“Install Tejas Linux”** on the desktop

---

## 🔐 Secure Boot & Drivers

- Secure Boot works out of the box
- Ubuntu’s signed kernel and bootloader are used
- Proprietary drivers (e.g. NVIDIA) may trigger **MOK enrollment**
  - This is expected behavior
  - Required only once per system

---

## 🔎 Verifying Downloads (IMPORTANT)

All Tejas Linux releases are **cryptographically signed**.

### 🔑 Release Signing Key

Tejas Linux releases are signed using the following GPG key:

- **Key type:** RSA 4096
- **Key ID:** `A3F982C55AD5DA0B`
- **Fingerprint:**

```
XXXX XXXX XXXX XXXX XXXX  XXXX A3F9 82C5 5AD5 DA0B
```

(The full fingerprint is published in this repository.)

---

### 1️⃣ Import the public key

From this repository:

```bash
gpg --import tejas-linux-public.key
```

Or from Ubuntu keyserver:

```bash
gpg --keyserver keyserver.ubuntu.com --recv-keys A3F982C55AD5DA0B
```

Verify fingerprint:

```bash
gpg --fingerprint A3F982C55AD5DA0B
```

---

### 2️⃣ Verify the ISO signature

```bash
gpg --verify tejas-linux.iso.sig tejas-linux.iso
```

Expected output:

```
Good signature from "Tejas Linux Release Signing Key"
```

---

### 3️⃣ Verify the checksum

```bash
sha256sum -c tejas-linux.iso.sha256
```

Expected:

```
OK
```

> **Only use the ISO if both checks succeed.**

---

## 🏗️ Build System (for contributors)

Tejas Linux does **not** use `live-build`.

Instead, it uses a **custom, deterministic pipeline**:

```
debootstrap → casper → GRUB (BIOS + UEFI) → xorriso
```

### Why not live-build?

- Broken hybrid ISO support on modern Ubuntu
- Obsolete syslinux / gfxboot dependencies
- Poor VMware compatibility
- Fragile CI behavior

This custom pipeline provides:

- Full control over boot layout
- Reliable Secure Boot support
- Predictable, debuggable builds

---

## 🪝 Hooks (System Customization)

Tejas Linux uses **explicit chroot hooks** instead of live-build hooks.

Hooks are simple shell scripts that run **inside the root filesystem** during the build.

### Hook location

```
iso/config/hooks/
```

Hooks are:

- Executed in lexical order
- Fully controlled by the project
- Easy to debug and audit

Typical hook responsibilities include:

- Locale & timezone setup
- Branding (hostname, `/etc/issue`)
- Stripping docs/man pages (User edition)
- Cleanup before squashfs creation

---

## 🛠️ Build Locally (Ubuntu only)

### Prerequisites

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
  rsync
```

---

### Build User Edition

```bash
PROFILE=user sudo iso/build.sh
```

### Build Developer Edition

```bash
PROFILE=developer sudo iso/build.sh
```

Output:

```
iso/out/
├── tejas-linux-<version>-user-amd64.iso
└── tejas-linux-<version>-developer-amd64.iso
```

---

## 🤖 Continuous Integration

Tejas Linux ISOs are built automatically using **GitHub Actions**.

Each CI run produces:

- User ISO
- Developer ISO
- SHA256 checksums
- GPG signatures

All artifacts are uploaded and verifiable.

---

## 📁 Repository Structure

```text
iso/
├── build.sh                # Main build script
├── config/
│   ├── profiles/           # User / Developer package profiles
│   └── hooks/              # Chroot hooks
├── rootfs/                 # Temporary root filesystem
├── image/
│   ├── casper/             # Live system
│   ├── EFI/BOOT/           # Secure Boot (shim + GRUB)
│   ├── boot/grub/          # GRUB configs (BIOS + UEFI)
│   └── .disk/
└── out/                    # Final ISOs
```

---

## 📜 Licensing

Tejas Linux is licensed under the **GNU General Public License v3.0 (GPL-3.0)**.

- All Tejas-specific scripts, build logic, and configuration in this repository are licensed under **GPL-3.0**, as described in the [`LICENSE`](LICENSE) file.
- Tejas Linux redistributes **unmodified Ubuntu packages**, which remain under their respective upstream licenses.
- Trademarks, logos, and brand names belong to their respective owners.

Tejas Linux is **not affiliated with or endorsed by Canonical**.

---

## 🤝 Contributing

Contributions are welcome:

- Bug reports
- Documentation improvements
- Package suggestions
- CI improvements
- Branding & UX enhancements

Please open an issue before large or breaking changes.

---

## 📣 Project Status

Tejas Linux is under **active development**.

Current focus:

- Stability
- Hardware compatibility
- Clean user experience
- First stable public release

---

## 🔗 Links

- Repository: [https://github.com/vaibhavpandeyvpz/tejas](https://github.com/vaibhavpandeyvpz/tejas)
- Issues: [https://github.com/vaibhavpandeyvpz/tejas/issues](https://github.com/vaibhavpandeyvpz/tejas/issues)
- Releases: [https://github.com/vaibhavpandeyvpz/tejas/releases](https://github.com/vaibhavpandeyvpz/tejas/releases)

---

## 🧠 Philosophy

Tejas Linux is built **the hard way — on purpose**.

- No fragile tooling
- No legacy bootloaders
- No hidden magic

Just a **clean, modern Ubuntu-based distro** you can inspect, verify, and trust.
