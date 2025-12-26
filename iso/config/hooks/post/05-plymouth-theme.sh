#!/bin/bash
set -e

echo "[plymouth-theme] Setting default theme and regenerating initramfs"

# Set the default Plymouth theme
sudo update-alternatives --install \
  /usr/share/plymouth/themes/text.plymouth \
  text.plymouth \
  /usr/share/plymouth/themes/tejas/tejas.plymouth \
  100

update-alternatives --set \
  text.plymouth \
  /usr/share/plymouth/themes/tejas/tejas.plymouth

# Regenerate initramfs for all installed kernels to include the theme
# This ensures the live system uses the custom theme
sudo update-initramfs -u -k all

echo "[plymouth-theme] Theme configured and initramfs regenerated"
