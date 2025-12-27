#!/bin/bash
set -e

echo "[fix-dns] Forcing static resolv.conf"

rm -f /etc/resolv.conf

cat > /etc/resolv.conf <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF

# Prevent systemd-resolved from touching it again
apt-mark hold systemd-resolved || true

echo "[fix-dns] DNS configured"
