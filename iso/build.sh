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

# -----------------------------
# 1. Bootstrap root filesystem
# -----------------------------
echo "[1/13] Bootstrap root filesystem"
sudo debootstrap \
  --arch="$ARCH" \
  --variant=minbase \
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
# 3. Apply rootfs overlay
# -----------------------------
echo "[3/13] Copy rootfs overlay"
sudo rsync -a iso/config/rootfs/ "$ROOTFS/"

# -----------------------------
# 4. Mount virtual filesystems
# -----------------------------
echo "[4/13] Mount system directories"
sudo mount --bind /dev       "$ROOTFS/dev"
sudo mount --bind /dev/pts   "$ROOTFS/dev/pts"
sudo mount --bind /proc      "$ROOTFS/proc"
sudo mount --bind /sys       "$ROOTFS/sys"

trap 'sudo umount -lf "$ROOTFS/dev/pts" "$ROOTFS/dev" "$ROOTFS/proc" "$ROOTFS/sys" 2>/dev/null || true' EXIT

# -----------------------------
# 5. Install base packages
# -----------------------------
echo "[5/13] Install base packages"
BASE_PKGS=$(grep -Ev '^\s*#|^\s*$' iso/config/profiles/base.packages)
sudo chroot "$ROOTFS" apt install -y $BASE_PKGS

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
sudo chown -R $USER:$USER iso/out

echo "[DONE] ISO created"
ls -lh "$OUT"
