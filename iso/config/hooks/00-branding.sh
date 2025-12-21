#!/bin/bash
set -e

echo "tejas" > /etc/hostname

cat <<EOF > /etc/issue
Tejas Linux
EOF
