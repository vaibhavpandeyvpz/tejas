#!/bin/bash
set -e

echo "[chrome] Setting up Google Chrome (stable)"

# Create keyrings directory if missing
install -d -m 0755 /usr/share/keyrings

# Add Google signing key
curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
  | gpg --dearmor \
  | tee /usr/share/keyrings/google-chrome.gpg > /dev/null

chmod 644 /usr/share/keyrings/google-chrome.gpg

# Add Google Chrome APT repository
cat <<EOF > /etc/apt/sources.list.d/google-chrome.list
deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main
EOF
