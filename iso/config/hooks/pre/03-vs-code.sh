#!/bin/bash
set -e

echo "[vs-code] Setting up Visual Studio Code (stable)"

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

# Update APT repositories
apt update
