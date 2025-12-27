#!/bin/bash
set -e

echo "[sublime-text] Setting up Sublime Text (stable channel)"

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

# Update APT repositories
apt-get update
