#!/bin/bash
set -e

echo "[set-default-locale] Setting default locale to en_IN"

# Add en_IN.UTF-8 to locale.gen
echo "en_IN.UTF-8 UTF-8" >> /etc/locale.gen

# Generate locales
locale-gen

# Set default locale to en_IN
update-locale LANG=en_IN.UTF-8
