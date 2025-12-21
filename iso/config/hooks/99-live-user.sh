#!/bin/bash
set -e

LIVE_USER=tejas

echo "[live-user] Creating live session user: $LIVE_USER"

# Create user if it doesn't exist
if ! id "$LIVE_USER" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "$LIVE_USER"
fi

# Set empty password (required for autologin)
passwd -d "$LIVE_USER"

# Required groups for desktop session
usermod -aG sudo,adm,video,audio,plugdev,netdev "$LIVE_USER"

# Set display name
usermod -c "Tejas Linux" tejas

# Ensure home permissions
chown -R "$LIVE_USER:$LIVE_USER" "/home/$LIVE_USER"
chmod 755 "/home/$LIVE_USER"
