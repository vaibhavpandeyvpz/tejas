#!/bin/bash
set -e

echo "[remove-pro-launchers] Removing pro-specific launchers"
  
PANEL_XML="/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
PANEL_DIR="/etc/skel/.config/xfce4/panel"

PROFILE=$(cat /etc/tejas-profile 2>/dev/null || echo user)

# Only remove pro launchers if we're building the user profile
if [ "$PROFILE" != "user" ]; then
  exit 0
fi

echo "[post-hook] Removing pro-specific launchers for user profile"

if [ -f "$PANEL_XML" ]; then
python3 << 'PYTHON_SCRIPT'
import xml.etree.ElementTree as ET
import sys

xml_file = "/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"

try:
tree = ET.parse(xml_file)
root = tree.getroot()

# Find panel-2 and remove plugin IDs 32, 33, 34, 35, 36 from plugin-ids array
for panel in root.findall(".//property[@name='panel-2']"):
    plugin_ids = panel.find(".//property[@name='plugin-ids']")
    if plugin_ids is not None:
        for value in plugin_ids.findall("value"):
            plugin_id = value.get("value")
            if plugin_id in ["32", "33", "34", "35", "36"]:
                plugin_ids.remove(value)

# Remove plugin definitions (plugin-32 through plugin-36)
plugins = root.find(".//property[@name='plugins']")
if plugins is not None:
    for plugin_num in ["32", "33", "34", "35", "36"]:
        plugin = plugins.find(f".//property[@name='plugin-{plugin_num}']")
        if plugin is not None:
            plugins.remove(plugin)

# Write back to file
tree.write(xml_file, encoding="UTF-8", xml_declaration=True)
print(f"Successfully removed pro launchers from {xml_file}")
except Exception as e:
print(f"Error processing XML: {e}", file=sys.stderr)
sys.exit(1)
PYTHON_SCRIPT
fi

# Remove launcher folders
if [ -d "$PANEL_DIR" ]; then
  rm -rf "$PANEL_DIR/launcher-33" 2>/dev/null || true
  rm -rf "$PANEL_DIR/launcher-34" 2>/dev/null || true
  rm -rf "$PANEL_DIR/launcher-35" 2>/dev/null || true
  rm -rf "$PANEL_DIR/launcher-36" 2>/dev/null || true
fi
