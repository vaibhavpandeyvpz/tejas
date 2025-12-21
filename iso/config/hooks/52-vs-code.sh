#!/bin/bash
set -e

PROFILE=$(cat /etc/tejas-profile 2>/dev/null || echo user)

# Only install for Developer edition
if [ "$PROFILE" != "developer" ]; then
  exit 0
fi

echo "[vscode] Installing Visual Studio Code (stable)"

# Create keyrings directory
install -d -m 0755 /usr/share/keyrings

# Install Microsoft GPG key
wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
  | gpg --dearmor \
  | tee /usr/share/keyrings/microsoft.gpg > /dev/null

chmod 644 /usr/share/keyrings/microsoft.gpg

# Add VS Code APT source
cat <<EOF > /etc/apt/sources.list.d/vscode.sources
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF

# Update and install VS Code
apt update
apt install -y code
