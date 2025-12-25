#!/bin/bash
set -e

echo "[spotify] Setting up Spotify (stable)"

# Create keyrings directory if missing
install -d -m 0755 /etc/apt/trusted.gpg.d

# Add Spotify GPG key
curl -sS https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.asc \
  | gpg --dearmor --yes \
  | tee /etc/apt/trusted.gpg.d/spotify.gpg > /dev/null

chmod 644 /etc/apt/trusted.gpg.d/spotify.gpg

# Add Spotify APT repository
cat <<EOF > /etc/apt/sources.list.d/spotify.list
deb https://repository.spotify.com stable non-free
EOF
