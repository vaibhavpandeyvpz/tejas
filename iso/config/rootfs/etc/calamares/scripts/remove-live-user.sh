#!/bin/bash
set -e

LIVE_USER="tejas"

if id "$LIVE_USER" &>/dev/null; then
  userdel -r -f "$LIVE_USER" || true
fi

# Clean leftover groups
getent group "$LIVE_USER" && groupdel "$LIVE_USER" || true

# Remove autologin config
rm -f /etc/lightdm/lightdm.conf.d/20-live-autologin.conf
