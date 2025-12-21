# Tejas Linux

**Tejas Linux** is a lightweight, fast, and secure Linux distribution based on **Ubuntu** and **XFCE**.

It is designed to be:

- ⚡ Fast and minimal by default
- 🧑‍💻 Friendly for developers and power users
- 🔐 Secure Boot–ready (signed GRUB & kernel)
- 🔁 Fully reproducible using `live-build`
- 🤖 CI-driven with automated ISO builds, checksums, and signatures

Tejas is built and maintained as a **clean Ubuntu derivative**, without modifying Ubuntu core packages.

---

## ✨ Features

- **XFCE desktop** (lightweight, responsive)
- **Calamares installer**
- **Secure Boot support (amd64)**
- **Two editions**
  - **User** – minimal system, smaller ISO
  - **Developer** – includes documentation, headers, and developer tools

- **English (US / UK) + Indian language support**
- **Signed ISOs** with SHA256 + GPG signatures
- **Reproducible builds** via GitHub Actions

---

## 📦 Editions

| Edition       | Target users            | Notes                                        |
| ------------- | ----------------------- | -------------------------------------------- |
| **User**      | General users           | Minimal, smaller ISO                         |
| **Developer** | Developers, power users | Includes man pages, headers, debugging tools |

Both editions share:

- Same base system
- Same installer
- Same Secure Boot chain
- Same branding

---

## 🏗️ Build locally

You must build on **Ubuntu** (22.04 or newer recommended).

### 1️⃣ Install dependencies

```bash
sudo apt update
sudo apt install -y \
  live-build \
  debootstrap \
  squashfs-tools \
  xorriso \
  grub-efi-amd64-bin \
  grub-efi-amd64-signed \
  shim-signed \
  rsync
```

---

### 2️⃣ Clone the repository

```bash
git clone https://github.com/vaibhavpandeyvpz/tejas-linux.git
cd tejas-linux
```

---

### 3️⃣ Select an edition (profile)

Tejas uses **directory-based profiles** (this is the only supported method in Ubuntu live-build).

Available profiles:

```
profiles/user/
profiles/developer/
```

Apply a profile by copying it into `config/`.

#### **User edition**

```bash
lb clean --purge
rsync -a profiles/user/ config/
lb config --distribution noble
sudo lb build
```

#### **Developer edition**

```bash
lb clean --purge
rsync -a profiles/developer/ config/
lb config --distribution noble
sudo lb build
```

The ISO will be generated in the project root.

---

## 🤖 CI builds (GitHub Actions)

Tejas Linux ISOs are built automatically using **GitHub Actions**.

Each CI run produces:

- ISO image
- `.sha256` checksum
- `.sig` GPG signature

Artifact naming format:

```
tejas-linux-<ubuntu>-<edition>-YYYY.MM.DD-<git-sha>-amd64.iso
```

Example:

```
tejas-linux-noble-developer-2025.12.21-a1b2c3d-amd64.iso
```

---

## 🔐 Verifying downloads

### 1️⃣ Import the Tejas Linux public key

```bash
gpg --import tejas-linux-public.key
```

(Or fetch from a keyserver if published.)

---

### 2️⃣ Verify the GPG signature

```bash
gpg --verify tejas-linux.iso.sig tejas-linux.iso
```

---

### 3️⃣ Verify the checksum

```bash
sha256sum -c tejas-linux.iso.sha256
```

Only use the ISO if **both checks succeed**.

---

## 💿 Using the ISO

Tejas Linux produces a **pure ISO (non-hybrid)** image.

### Recommended usage

- VirtualBox / VMware
- Optical media
- UEFI boot via firmware ISO selection
- Ventoy (recommended for USB)

### ⚠️ USB note

Because the ISO is **not hybrid**, raw `dd`-to-USB may not boot on all systems.

If creating a USB installer, use:

- **Ventoy**
- **Rufus (ISO mode)**

---

## 📁 Repository structure

```text
profiles/
├── user/
│   ├── package-lists/
│   ├── includes.chroot/
│   └── hooks/
├── developer/
│   ├── package-lists/
│   ├── includes.chroot/
│   └── hooks/

config/                 # live-build working config (generated)
.github/workflows/      # CI pipelines
```

> `profiles/` contain **only differences** between editions.
> `config/` is populated during local or CI builds.

---

## 🔐 Secure Boot & drivers

- Tejas Linux supports **Secure Boot on amd64**
- Proprietary drivers (e.g. NVIDIA, Wi-Fi) use **DKMS + MOK**
- Users may be prompted **once** to enroll a key when installing such drivers
- This is expected, standard Secure Boot behavior

---

## 📜 Licensing

Tejas Linux is licensed under the **GNU General Public License v3.0 (GPL-3.0)**.

- All Tejas-specific build scripts, configuration, and tooling in this repository are licensed under **GPL-3.0**, as described in the `LICENSE` file
- Tejas Linux redistributes **unmodified Ubuntu packages**, which remain under their respective upstream licenses
- Trademarks, logos, and brand names belong to their respective owners

Tejas Linux is **not affiliated with or endorsed by Canonical**.

---

## 🤝 Contributing

Contributions are welcome:

- Bug reports
- Package suggestions
- Documentation improvements
- CI improvements

Please open an issue before large changes.

---

## 📣 Project status

Tejas Linux is under **active development**.

Current focus areas:

- Stability
- Hardware compatibility
- Clean, predictable user experience

---

## 🔗 Links

- Issues: [https://github.com/vaibhavpandeyvpz/tejas/issues](https://github.com/vaibhavpandeyvpz/tejas/issues)
- Releases: [https://github.com/vaibhavpandeyvpz/tejas/releases](https://github.com/vaibhavpandeyvpz/tejas/releases)
