#!/usr/bin/env bash
set -e

DISTRO=noble
ARCH=amd64
VERSION=$(date +%Y.%m.%d)
MIRROR=http://archive.ubuntu.com/ubuntu

PROFILE=${PROFILE:-user}
echo "[INFO] Building Tejas profile: $PROFILE"

ROOTFS=iso/rootfs
IMAGE=iso/image
OUT=iso/out

echo "[1/12] Bootstrap root filesystem"
sudo debootstrap --arch=$ARCH --variant=minbase \
  $DISTRO $ROOTFS $MIRROR

echo "[2/12] Configuring additional repositories"
cat <<EOF | sudo tee $ROOTFS/etc/apt/sources.list
deb http://archive.ubuntu.com/ubuntu $DISTRO main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu $DISTRO-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu $DISTRO-security main restricted universe multiverse
EOF
sudo chroot $ROOTFS apt update

echo "[3/12] Copying rootfs overlay"
sudo rsync -a iso/config/rootfs/ $ROOTFS/

echo "[4/12] Mount system directories"
sudo mount --bind /dev  $ROOTFS/dev
sudo mount --bind /proc $ROOTFS/proc
sudo mount --bind /sys  $ROOTFS/sys

echo "[5/12] Install base packages"
PKGS=$(grep -Ev '^\s*#|^\s*$' iso/config/profiles/base.packages)
sudo chroot $ROOTFS apt install -y $PKGS

echo "[6/12] Install $PROFILE packages"
PKGS=$(grep -Ev '^\s*#|^\s*$' iso/config/profiles/$PROFILE.packages)

echo "[7/12] Generate filesystem manifest"
sudo chroot $ROOTFS dpkg-query -W \
  --showformat='${Package} ${Version}\n' \
  | sudo tee $IMAGE/casper/filesystem.manifest

echo "[8/12] Copy kernel and initrd"
sudo cp $ROOTFS/boot/vmlinuz-* $IMAGE/casper/vmlinuz
sudo cp $ROOTFS/boot/initrd.img-* $IMAGE/casper/initrd

echo "[9/12] Running chroot hooks"
echo "PROFILE=$PROFILE" | sudo tee $ROOTFS/etc/tejas-profile
for hook in iso/config/hooks/*.sh; do
  [ -f "$hook" ] || continue
  echo "Running $(basename "$hook")"
  sudo chroot $ROOTFS /bin/bash < "$hook"
done

echo "[10/12] Create squashfs"
sudo mksquashfs $ROOTFS \
  $IMAGE/casper/filesystem.squashfs \
  -e boot -comp zstd

echo "[11/12] Install Secure Boot EFI binaries"
# Shim (Microsoft signed)
sudo cp /usr/lib/shim/shimx64.efi.signed \
  iso/image/EFI/BOOT/BOOTX64.EFI

# GRUB (Canonical signed)
sudo cp /usr/lib/grub/x86_64-efi-signed/grubx64.efi.signed \
  iso/image/EFI/BOOT/grubx64.efi

grub-mkimage \
  -O i386-pc \
  -o iso/image/boot/grub/i386-pc/core.img \
  -p /boot/grub \
  biosdisk iso9660 part_msdos part_gpt \
  normal linux configfile search search_fs_file

echo "[12/12] Create ISO"
xorriso -as mkisofs \
  -r \
  -V "TEJAS_LINUX" \
  -o iso/out/tejas-linux-$VERSION-$PROFILE-amd64.iso \
  -J -joliet-long -l \
  -b boot/grub/i386-pc/core.img \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  -eltorito-alt-boot \
  -e EFI/BOOT/BOOTX64.EFI \
  -no-emul-boot \
  iso/image

echo "[DONE] ISO created"
ls -lh $OUT
