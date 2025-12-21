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
- **Secure Boot support** (amd64)
- **Two flavours**
  - **User** – smaller, clean, no docs/manpages
  - **Developer** – includes man pages, headers, and dev tools
- **English (US / UK) + Indian language support**
- **Signed ISOs with SHA256 + GPG verification**
- **Reproducible builds** via GitHub Actions

---

## 📦 Editions (Flavours)

| Flavour | Target users | Notes |
|------|-------------|------|
| **User** | General users | Smaller ISO, no docs/man pages |
| **Developer** | Developers, power users | Includes man pages, headers, debugging tools |

Both flavours share:
- Same base system
- Same installer
- Same Secure Boot chain
- Same branding

---

## 🏗️ Build locally

You must build on **Ubuntu**.

### 1️⃣ Install dependencies

```bash
sudo apt update
sudo apt install -y live-build debootstrap squashfs-tools xorriso
````

### 2️⃣ Clone the repository

```bash
git clone https://github.com/vaibhavpandeyvpz/tejas-linux.git
cd tejas-linux
```

### 3️⃣ Configure build (choose one)

**User flavour**

```bash
lb clean --purge
lb config --distribution noble --profiles user
sudo lb build
```

**Developer flavour**

```bash
lb clean --purge
lb config --distribution noble --profiles developer
sudo lb build
```

The ISO will be generated in the project root.

---

## 🤖 CI builds (GitHub Actions)

Tejas Linux ISOs are built automatically using GitHub Actions.

Each CI run produces:

* ISO image
* `.sha256` checksum
* `.sig` GPG signature

Artifacts are named like:

```
tejas-linux-noble-user-YYYY.MM.DD-g<sha>-amd64.iso
```

---

## 🔐 Verifying downloads

### 1️⃣ Import Tejas Linux public key

```bash
gpg --import tejas-linux-public.key
```

(or fetch from keyserver if published)

### 2️⃣ Verify GPG signature

```bash
gpg --verify tejas-linux.iso.sig tejas-linux.iso
```

### 3️⃣ Verify checksum

```bash
sha256sum -c tejas-linux.iso.sha256
```

Only use the ISO if **both checks succeed**.

---

## 💿 Writing ISO to USB

Recommended methods:

* **Linux**

  ```bash
  sudo dd if=tejas-linux.iso of=/dev/sdX bs=4M status=progress oflag=sync
  ```

* **Windows**

  * Rufus (DD mode)
  * Ventoy

* **macOS**

  ```bash
  sudo dd if=tejas-linux.iso of=/dev/diskN bs=4m
  ```

---

## 📁 Repository structure

```text
config/
├── package-lists/     # Base, user, developer packages
├── hooks/             # Build-time hooks (locales, stripping, branding)
├── includes.chroot/   # Files copied into live system
├── profiles/          # User / Developer profiles
.github/workflows/     # CI pipelines
```

---

## 🔐 Secure Boot & drivers

* Tejas Linux supports **Secure Boot on amd64**
* NVIDIA and Wi-Fi drivers use **DKMS + MOK enrollment**
* Users may be prompted **once** to enroll a key when installing proprietary drivers
* This is expected and documented behavior

---

## 📜 Licensing

Tejas Linux is licensed under the **GNU General Public License v3.0 (GPL-3.0)**.

- All Tejas-specific build scripts, configuration, and tooling in this repository are licensed under **GPL-3.0**, as described in the `LICENSE` file.
- Tejas Linux redistributes unmodified Ubuntu packages. These packages remain under their respective upstream licenses.
- Trademarks, logos, and brand names belong to their respective owners.

Tejas Linux is **not affiliated with or endorsed by Canonical**.

---

## 🤝 Contributing

Contributions are welcome:

* Bug reports
* Package suggestions
* Documentation improvements
* CI improvements

Please open an issue before large changes.

---

## 📣 Project status

Tejas Linux is under **active development**.

Current focus:

* Stability
* Hardware compatibility
* Clean user experience

---

## 🔗 Links

* GitHub Issues: [https://github.com/](https://github.com/)vaibhavpandeyvpz/tejas/issues
* Releases: [https://github.com/](https://github.com/)vaibhavpandeyvpz/tejas/releases
