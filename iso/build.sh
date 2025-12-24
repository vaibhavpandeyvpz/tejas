#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Configuration
# -----------------------------
DISTRO=noble
ARCH=amd64
MIRROR=http://archive.ubuntu.com/ubuntu
VERSION=$(date +%Y.%m.%d)

PROFILE=${PROFILE:-user}
echo "[INFO] Building Tejas Linux ($PROFILE)"

ROOTFS=iso/rootfs
IMAGE=iso/image
OUT=iso/out

# -----------------------------
# Cleanup
# -----------------------------
echo "[DEBUG] Removing previous rootfs"
sudo rm -rf "$ROOTFS"

# Ensure directory exists with proper permissions
mkdir -p "$ROOTFS"
sudo chown root:root "$ROOTFS"

# Clean APT cache to free space
echo "[DEBUG] Cleaning APT cache"
sudo apt clean || true

# Check available disk space (warn if less than 5GB)
if command -v df >/dev/null 2>&1; then
  AVAILABLE=$(df -BG "$(dirname "$ROOTFS")" 2>/dev/null | tail -1 | awk '{print $4}' | sed 's/G//' || echo "0")
  if [ -n "$AVAILABLE" ] && [ "$AVAILABLE" -lt 5 ] 2>/dev/null; then
    echo "[WARN] Low disk space: ${AVAILABLE}GB available (recommended: 10GB+)" >&2
  fi
fi

# -----------------------------
# 1. Bootstrap root filesystem
# -----------------------------
echo "[1/20] Bootstrap root filesystem"
echo "[INFO] This may take several minutes..."
sudo debootstrap \
  --arch="$ARCH" \
  --variant=minbase \
  --verbose \
  "$DISTRO" "$ROOTFS" "$MIRROR"

# -----------------------------
# 2. Configure APT repositories
# -----------------------------
echo "[2/20] Configure APT repositories"
cat <<EOF | sudo tee "$ROOTFS/etc/apt/sources.list"
deb $MIRROR $DISTRO main restricted universe multiverse
deb $MIRROR $DISTRO-security main restricted universe multiverse
deb $MIRROR $DISTRO-updates main restricted universe multiverse
EOF

sudo chroot "$ROOTFS" apt update

# -----------------------------
# 3. Mount virtual filesystems
# -----------------------------
echo "[3/20] Mount system directories"
sudo mount --bind /dev "$ROOTFS/dev"
sudo mount --bind /dev/pts "$ROOTFS/dev/pts"
sudo mount --bind /proc "$ROOTFS/proc"
sudo mount --bind /sys "$ROOTFS/sys"

trap 'sudo umount -lf "$ROOTFS/dev/pts" "$ROOTFS/dev" "$ROOTFS/proc" "$ROOTFS/sys" 2>/dev/null || true' EXIT

# Configure debconf for non-interactive installation (temporary, for build only)
echo "[4/20] Configure debconf for non-interactive mode (build-time only)"
echo 'debconf debconf/frontend select Noninteractive' | sudo chroot "$ROOTFS" debconf-set-selections
echo 'console-setup console-setup/charmap47 select UTF-8' | sudo chroot "$ROOTFS" debconf-set-selections
echo 'console-setup console-setup/codeset47 select Lat15' | sudo chroot "$ROOTFS" debconf-set-selections
echo 'console-setup console-setup/fontsize-fb47 text 16' | sudo chroot "$ROOTFS" debconf-set-selections

# Clean APT cache to free space
echo "[DEBUG] Cleaning APT cache"
sudo chroot "$ROOTFS" apt clean || true

# -----------------------------
# 5. Install offline packages
# -----------------------------
echo "[5/20] Install offline packages"
sudo chroot "$ROOTFS" sh -c 'echo "APT::Keep-Downloaded-Packages \"true\";" > /etc/apt/apt.conf.d/99-keep-debs'
OFFLINE_PKGS=$(grep -Ev '^\s*#|^\s*$' iso/config/profiles/offline.packages)
sudo chroot "$ROOTFS" apt-get install -y $OFFLINE_PKGS
sudo chroot "$ROOTFS" rm -f /etc/apt/apt.conf.d/99-keep-debs

# -----------------------------
# 6. Create APT repository
# -----------------------------
echo "[6/20] Create local APT repository"
mkdir -p iso/image/pool/main
sudo cp $ROOTFS/var/cache/apt/archives/*.deb iso/image/pool/main/

PRWD=$(pwd)
cd "$IMAGE"

mkdir -p dists/$DISTRO/main/binary-amd64
apt-ftparchive \
  -o APT::FTPArchive::Packages::Compress=false \
  packages pool/main > dists/$DISTRO/main/binary-amd64/Packages
gzip -9 dists/$DISTRO/main/binary-amd64/Packages

# Generate GPG key for signing the release
gpg --batch --passphrase '' --quick-generate-key \
  "Tejas Linux ISO <tejas.linux@vaibhavpandey.com>" \
  rsa2048 sign 0

# Generate Release file
apt-ftparchive \
  -o APT::FTPArchive::Release::Origin="Tejas Linux" \
  -o APT::FTPArchive::Release::Label="Tejas Linux" \
  -o APT::FTPArchive::Release::Suite="$DISTRO" \
  -o APT::FTPArchive::Release::Codename="$DISTRO" \
  -o APT::FTPArchive::Release::Components="main" \
  -o APT::FTPArchive::Release::Architectures="amd64" \
  release . > dists/$DISTRO/Release

# Detached signature (Release.gpg)
gpg --batch --yes \
  -abs \
  -o dists/$DISTRO/Release.gpg \
  dists/$DISTRO/Release

# Inline signature (InRelease)
gpg --batch --yes \
  --clearsign \
  -o dists/$DISTRO/InRelease \
  dists/$DISTRO/Release

cd "$PRWD"

# -----------------------------
# 7. Create apt-cdrom metadata
# -----------------------------
echo "[7/20] Create CD-ROM metadata for apt-cdrom"
mkdir -p iso/image/.disk
echo "Tejas Linux $VERSION ($PROFILE edition)" > iso/image/.disk/info
echo "main" > iso/image/.disk/base_components
echo "install" > iso/image/.disk/cd_type

# -----------------------------
# 8. Install base packages
# -----------------------------
echo "[8/20] Install base packages"
BASE_PKGS=$(grep -Ev '^\s*#|^\s*$' iso/config/profiles/base.packages)
sudo chroot "$ROOTFS" apt-get install -y $BASE_PKGS
sudo chroot "$ROOTFS" systemctl enable snapd

# -----------------------------
# 9. Apply rootfs overlay
# -----------------------------
echo "[9/20] Copy rootfs overlay"
sudo rsync -a iso/config/rootfs/ "$ROOTFS/"

# -----------------------------
# 10. Install profile packages
# -----------------------------
echo "[10/20] Install $PROFILE packages"
PROFILE_PKGS=$(grep -Ev '^\s*#|^\s*$' "iso/config/profiles/$PROFILE.packages")
sudo chroot "$ROOTFS" apt-get install -y $PROFILE_PKGS

# -----------------------------
# 11. Run hooks
# -----------------------------
echo "[11/20] Run chroot hooks"
echo "$PROFILE" | sudo tee "$ROOTFS/etc/tejas-profile"

for hook in iso/config/hooks/*.sh; do
  [ -f "$hook" ] || continue
  echo "> Running $(basename "$hook")"
  sudo chroot "$ROOTFS" /bin/bash < "$hook"
done

# -----------------------------
# 12. Reset debconf settings
# -----------------------------
echo "[12/20] Clearing build-time debconf settings"
# Remove debconf cache - it will be recreated fresh when packages need it
# This ensures no build-time debconf settings persist to live/installed system
sudo rm -rf "$ROOTFS/var/cache/debconf" 2>/dev/null || true
sudo mkdir -p "$ROOTFS/var/cache/debconf" 2>/dev/null || true

# -----------------------------
# 13. Export GPG key
# -----------------------------
echo "[13/20] Export key to rootfs"
KEY_ID=$(gpg --batch --list-keys --with-colons "Tejas Linux ISO" | grep "^pub" | cut -d: -f5)
sudo mkdir -p "$ROOTFS/etc/apt/trusted.gpg.d"
gpg --batch --export "$KEY_ID" | sudo tee "$ROOTFS/etc/apt/trusted.gpg.d/tejas-iso.gpg" > /dev/null
sudo chmod 644 "$ROOTFS/etc/apt/trusted.gpg.d/tejas-iso.gpg"

# -----------------------------
# 14. Fix internet connectivity
# -----------------------------
echo "[14/20] Configure live networking"
sudo chroot "$ROOTFS" mkdir -p /etc/netplan
sudo chroot "$ROOTFS" tee /etc/netplan/01-network-manager.yaml >/dev/null <<'EOF'
network:
  version: 2
  renderer: NetworkManager
EOF
sudo chroot "$ROOTFS" rm -f /etc/resolv.conf
sudo chroot "$ROOTFS" ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
sudo chroot "$ROOTFS" systemctl mask systemd-networkd
sudo chroot "$ROOTFS" systemctl enable NetworkManager systemd-resolved

# -----------------------------
# 15. Generate filesystem manifest
# -----------------------------
echo "[15/20] Generate filesystem manifest"
sudo chroot "$ROOTFS" dpkg-query -W \
  --showformat='${Package} ${Version}\n' \
  | sudo tee "$IMAGE/casper/filesystem.manifest"

# -----------------------------
# 16. Copy kernel and initrd
# -----------------------------
echo "[16/20] Copy kernel and initrd"
KERNEL=$(ls "$ROOTFS"/boot/vmlinuz-* | sort | tail -1)
INITRD=$(ls "$ROOTFS"/boot/initrd.img-* | sort | tail -1)
sudo cp "$KERNEL" "$IMAGE/casper/vmlinuz"
sudo cp "$INITRD" "$IMAGE/casper/initrd"

# Clean APT cache to free space
echo "[DEBUG] Cleaning APT cache"
sudo chroot "$ROOTFS" apt clean || true
sudo chroot "$ROOTFS" rm -rf /var/lib/apt/lists/* || true

# -----------------------------
# 17. Unmount virtual filesystems
# -----------------------------
echo "[17/20] Unmount virtual filesystems"
sudo umount -lf "$ROOTFS/dev/pts" || true
sudo umount -lf "$ROOTFS/dev" || true
sudo umount -lf "$ROOTFS/proc" || true
sudo umount -lf "$ROOTFS/sys" || true

# -----------------------------
# 18. Create squashfs
# -----------------------------
echo "[18/20] Create squashfs"
sudo mksquashfs \
  "$ROOTFS" \
  "$IMAGE/casper/filesystem.squashfs" \
  -e boot \
  -comp zstd

# -----------------------------
# 19. Install Secure Boot EFI binaries
# -----------------------------
echo "[19/20] Install Secure Boot EFI binaries"

# Microsoft-signed shim
sudo cp /usr/lib/shim/shimx64.efi.signed \
  "$IMAGE/EFI/BOOT/BOOTX64.EFI"

# Canonical-signed GRUB
sudo cp /usr/lib/grub/x86_64-efi-signed/grubx64.efi.signed \
  "$IMAGE/EFI/BOOT/grubx64.efi"

# Optional MOK manager
if [ -f /usr/lib/shim/mmx64.efi ]; then
  sudo cp /usr/lib/shim/mmx64.efi "$IMAGE/EFI/BOOT/"
fi

# -----------------------------
# 20. Create ISO (BIOS + UEFI)
# -----------------------------
echo "[20/20] Create ISO"
mkdir -p "$OUT"
grub-mkrescue \
  -o "$OUT/tejas-linux-$VERSION-$PROFILE-amd64.iso" \
  "$IMAGE" \
  -volid TEJAS_LINUX

echo "[DONE] ISO created"
ls -lh "$OUT"
