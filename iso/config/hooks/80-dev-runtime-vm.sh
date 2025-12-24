#!/bin/bash
set -e

PROFILE=$(cat /etc/tejas-profile 2>/dev/null || echo user)

# Pro edition only
if [ "$PROFILE" != "pro" ]; then
  exit 0
fi

echo "[dev-env] Installing pyenv, rbenv, nvm"

# Base dependencies
apt update
apt install -y \
  libssl-dev zlib1g-dev libbz2-dev \
  libreadline-dev libsqlite3-dev \
  libncursesw5-dev xz-utils tk-dev \
  libxml2-dev libxmlsec1-dev libffi-dev \
  libyaml-dev

# Install directories
install -d -m 0755 /opt/pyenv /opt/rbenv /opt/nvm

# ---- pyenv ----
if [ ! -d /opt/pyenv/.git ]; then
  git clone https://github.com/pyenv/pyenv.git /opt/pyenv
fi

# ---- rbenv ----
if [ ! -d /opt/rbenv/.git ]; then
  git clone https://github.com/rbenv/rbenv.git /opt/rbenv
  git clone https://github.com/rbenv/ruby-build.git /opt/rbenv/plugins/ruby-build
fi

# ---- nvm ----
if [ ! -f /opt/nvm/nvm.sh ]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh \
    | NVM_DIR=/opt/nvm bash
fi

# Pre-create required directories with safe permissions
install -d -m 0755 /opt/pyenv/{shims,versions}
install -d -m 0755 /opt/rbenv/{shims,versions}

# Allow users to write versions
chown -R root:root /opt/pyenv /opt/rbenv
chmod -R a+rX /opt/pyenv /opt/rbenv

# ---- profile integration ----
cat <<'EOF' > /etc/profile.d/tejas-dev-env.sh
# pyenv
export PYENV_ROOT="/opt/pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# rbenv
export RBENV_ROOT="/opt/rbenv"
export PATH="$RBENV_ROOT/bin:$PATH"

# nvm
export NVM_DIR="/opt/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
EOF

chmod 644 /etc/profile.d/tejas-dev-env.sh
