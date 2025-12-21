#!/usr/bin/env bash
set -e

DISTRO=noble
ARCH=amd64
VERSION=$(date +%Y.%m.%d)
MIRROR=http://archive.ubuntu.com/ubuntu

PROFILE=${PROFILE:-user}
echo "[INFO] Building Tejas profile: $PROFILE"
echo "PROFILE=$PROFILE" | sudo tee $ROOTFS/etc/tejas-profile

ROOTFS=iso/rootfs
IMAGE=iso/image
OUT=iso/out

echo "[1/10] Bootstrap root filesystem"
sudo debootstrap --arch=$ARCH --variant=minbase \
  $DISTRO $ROOTFS $MIRROR

echo "[2/10] Mount system directories"
sudo mount --bind /dev  $ROOTFS/dev
sudo mount --bind /proc $ROOTFS/proc
sudo mount --bind /sys  $ROOTFS/sys

echo "[3/10] Install base packages"
xargs -a iso/config/profiles/base.packages \
  sudo chroot $ROOTFS apt install -y

echo "[4/10] Apply $PROFILE packages"
xargs -a iso/config/profiles/$PROFILE.packages \
  sudo chroot $ROOTFS apt install -y

echo "[5/10] Generate filesystem manifest"
sudo chroot $ROOTFS dpkg-query -W \
  --showformat='${Package} ${Version}\n' \
  | sudo tee $IMAGE/casper/filesystem.manifest

echo "[6/10] Copy kernel and initrd"
sudo cp $ROOTFS/boot/vmlinuz-* $IMAGE/casper/vmlinuz
sudo cp $ROOTFS/boot/initrd.img-* $IMAGE/casper/initrd

echo "[7/10] Running chroot hooks"
for hook in iso/config/hooks/*.sh; do
  [ -f "$hook" ] || continue
  echo "→ Running $(basename "$hook")"
  sudo chroot $ROOTFS /bin/bash < "$hook"
done

echo "[8/10] Create squashfs"
sudo mksquashfs $ROOTFS \
  $IMAGE/casper/filesystem.squashfs \
  -e boot -comp zstd

echo "[9/10] Install Secure Boot EFI binaries"
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

echo "[10/10] Create ISO"
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

echo "[DONE] ISO created:"
ls -lh $OUT
