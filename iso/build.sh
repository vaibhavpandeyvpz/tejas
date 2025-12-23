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
echo "[CLEAN] Removing previous rootfs"
sudo rm -rf "$ROOTFS"

# Ensure directory exists with proper permissions
mkdir -p "$ROOTFS"
sudo chown root:root "$ROOTFS"

# Clean APT cache to free space
echo "[CLEAN] Cleaning APT cache"
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
echo "[1/13] Bootstrap root filesystem"
echo "[INFO] This may take several minutes..."
sudo debootstrap \
  --arch="$ARCH" \
  --variant=minbase \
  --verbose \
  "$DISTRO" "$ROOTFS" "$MIRROR"

# -----------------------------
# 2. Configure APT repositories
# -----------------------------
echo "[2/13] Configure APT repositories"
cat <<EOF | sudo tee "$ROOTFS/etc/apt/sources.list"
deb $MIRROR $DISTRO main restricted universe multiverse
deb $MIRROR $DISTRO-updates main restricted universe multiverse
deb $MIRROR $DISTRO-security main restricted universe multiverse
EOF

sudo chroot "$ROOTFS" apt update

# -----------------------------
# 3. Mount virtual filesystems
# -----------------------------
echo "[3/13] Mount system directories"
sudo mount --bind /dev       "$ROOTFS/dev"
sudo mount --bind /dev/pts   "$ROOTFS/dev/pts"
sudo mount --bind /proc      "$ROOTFS/proc"
sudo mount --bind /sys       "$ROOTFS/sys"

trap 'sudo umount -lf "$ROOTFS/dev/pts" "$ROOTFS/dev" "$ROOTFS/proc" "$ROOTFS/sys" 2>/dev/null || true' EXIT

# Configure debconf for non-interactive installation (temporary, for build only)
echo "[3.5/13] Configure debconf for non-interactive mode (build-time only)"
echo 'debconf debconf/frontend select Noninteractive' | sudo chroot "$ROOTFS" debconf-set-selections
echo 'console-setup console-setup/charmap47 select UTF-8' | sudo chroot "$ROOTFS" debconf-set-selections
echo 'console-setup console-setup/codeset47 select Lat15' | sudo chroot "$ROOTFS" debconf-set-selections
echo 'console-setup console-setup/fontsize-fb47 text 16' | sudo chroot "$ROOTFS" debconf-set-selections

# -----------------------------
# 4. Install base packages
# -----------------------------
echo "[4/13] Install base packages"
BASE_PKGS=$(grep -Ev '^\s*#|^\s*$' iso/config/profiles/base.packages)
sudo chroot "$ROOTFS" apt install -y $BASE_PKGS

# -----------------------------
# 5. Apply rootfs overlay
# -----------------------------
echo "[5/13] Copy rootfs overlay"
sudo rsync -a iso/config/rootfs/ "$ROOTFS/"

# -----------------------------
# 6. Install profile packages
# -----------------------------
echo "[6/13] Install $PROFILE packages"
PROFILE_PKGS=$(grep -Ev '^\s*#|^\s*$' "iso/config/profiles/$PROFILE.packages")
sudo chroot "$ROOTFS" apt install -y $PROFILE_PKGS

# -----------------------------
# 7. Run hooks
# -----------------------------
echo "[7/13] Run chroot hooks"
echo "$PROFILE" | sudo tee "$ROOTFS/etc/tejas-profile"

for hook in iso/config/hooks/*.sh; do
  [ -f "$hook" ] || continue
  echo "→ Running $(basename "$hook")"
  sudo chroot "$ROOTFS" /bin/bash < "$hook"
done

# Clear build-time debconf settings so they don't propagate to live/installed system
echo "[7.5/13] Clearing build-time debconf settings"
# Remove debconf cache - it will be recreated fresh when packages need it
# This ensures no build-time debconf settings persist to live/installed system
sudo rm -rf "$ROOTFS/var/cache/debconf" 2>/dev/null || true
sudo mkdir -p "$ROOTFS/var/cache/debconf" 2>/dev/null || true

# -----------------------------
# 8. Generate filesystem manifest
# -----------------------------
echo "[8/13] Generate filesystem manifest"
sudo chroot "$ROOTFS" dpkg-query -W \
  --showformat='${Package} ${Version}\n' \
  | sudo tee "$IMAGE/casper/filesystem.manifest"

# -----------------------------
# 9. Copy kernel and initrd
# -----------------------------
echo "[9/13] Copy kernel and initrd"
sudo cp "$ROOTFS"/boot/vmlinuz-*    "$IMAGE/casper/vmlinuz"
sudo cp "$ROOTFS"/boot/initrd.img-* "$IMAGE/casper/initrd"

# -----------------------------
# 10. Unmount virtual filesystems
# -----------------------------
echo "[10/13] Unmount virtual filesystems"
sudo umount -lf "$ROOTFS/dev/pts" || true
sudo umount -lf "$ROOTFS/dev"     || true
sudo umount -lf "$ROOTFS/proc"    || true
sudo umount -lf "$ROOTFS/sys"     || true

# -----------------------------
# 11. Create squashfs
# -----------------------------
echo "[11/13] Create squashfs"
sudo mksquashfs \
  "$ROOTFS" \
  "$IMAGE/casper/filesystem.squashfs" \
  -e boot \
  -comp zstd

# -----------------------------
# 12. Install Secure Boot EFI binaries
# -----------------------------
echo "[12/13] Install Secure Boot EFI binaries"

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
# 13. Create ISO (BIOS + UEFI)
# -----------------------------
echo "[13/13] Create ISO"
mkdir -p "$OUT"
grub-mkrescue \
  -o "$OUT/tejas-linux-$VERSION-$PROFILE-amd64.iso" \
  "$IMAGE"

echo "[DONE] ISO created"
ls -lh "$OUT"
