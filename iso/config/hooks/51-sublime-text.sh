#!/bin/bash
set -e

PROFILE=$(cat /etc/tejas-profile 2>/dev/null || echo user)

# Only install for Developer edition
if [ "$PROFILE" != "developer" ]; then
  exit 0
fi

echo "[sublime] Installing Sublime Text (stable channel)"

# Create keyrings directory if missing
install -d -m 0755 /etc/apt/keyrings

# Add Sublime HQ GPG key
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg \
  | tee /etc/apt/keyrings/sublimehq-pub.asc > /dev/null

# Add Sublime Text APT source (stable)
cat <<EOF > /etc/apt/sources.list.d/sublime-text.sources
Types: deb
URIs: https://download.sublimetext.com/
Suites: apt/stable/
Components:
Signed-By: /etc/apt/keyrings/sublimehq-pub.asc
EOF

# Update and install
apt update
apt install -y sublime-text
