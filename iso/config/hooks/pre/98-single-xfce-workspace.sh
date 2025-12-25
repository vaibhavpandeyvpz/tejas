#!/bin/bash
set -e

PROFILE=$(cat /etc/tejas-profile 2>/dev/null || echo user)

# Apply ONLY to User edition
if [ "$PROFILE" != "user" ]; then
  exit 0
fi

echo "[xfce] Configuring single workspace (User edition)"

XFCE_DIR="/etc/xdg/xfce4/xfconf/xfce-perchannel-xml"
install -d -m 0755 "$XFCE_DIR"

cat <<EOF > "$XFCE_DIR/xfwm4.xml"
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="workspace_count" type="int" value="1" />
  </property>
</channel>
EOF
