#!/bin/bash
set -e

cat > /etc/locale.gen <<EOF
en_IN.UTF-8 UTF-8
en_US.UTF-8 UTF-8
en_GB.UTF-8 UTF-8

hi_IN.UTF-8 UTF-8
bn_IN.UTF-8 UTF-8
ta_IN.UTF-8 UTF-8
te_IN.UTF-8 UTF-8
mr_IN.UTF-8 UTF-8
gu_IN.UTF-8 UTF-8
kn_IN.UTF-8 UTF-8
ml_IN.UTF-8 UTF-8
pa_IN.UTF-8 UTF-8
ur_IN.UTF-8 UTF-8
EOF

locale-gen
update-locale LANG=en_IN.UTF-8

apt purge -y \
  language-pack-* \
  hunspell-* \
  mythes-* \
  aspell-* || true
