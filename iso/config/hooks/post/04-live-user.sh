#!/bin/bash
set -e

echo "[live-user] Creating live session user"

LIVE_USER=tejas
LIVE_HOME="/home/$LIVE_USER"

# Create user if it doesn't exist
if ! id "$LIVE_USER" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "$LIVE_USER"
fi

# Set empty password (required for autologin)
passwd -d "$LIVE_USER"

# Required groups for desktop session
# Includes groups from users.conf plus desktop-specific groups (video, audio, netdev)
usermod -aG sudo,adm,video,audio,plugdev,netdev,cdrom,dip,lpadmin "$LIVE_USER"

# Add sambashare if it exists (optional group)
if getent group sambashare >/dev/null 2>&1; then
  usermod -aG sambashare "$LIVE_USER"
fi

# Set display name
usermod -c "Tejas Linux" tejas

# Ensure home permissions
chown -R "$LIVE_USER:$LIVE_USER" "$LIVE_HOME"
chmod 755 "$LIVE_HOME"

mkdir -p "$LIVE_HOME/.config"

cp -r /etc/skel/.config/* "$LIVE_HOME/.config/"
chown -R "$LIVE_USER:$LIVE_USER" "$LIVE_HOME/.config"
