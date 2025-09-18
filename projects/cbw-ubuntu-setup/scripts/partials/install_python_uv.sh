#!/usr/bin/env bash
set -euo pipefail

# pyenv for Python 3.10 on modern Ubuntu
apt-get update -y
apt-get install -y make build-essential libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncursesw5-dev xz-utils tk-dev \
  libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev git

if [[ ! -d "/usr/local/pyenv" ]]; then
  git clone https://github.com/pyenv/pyenv.git /usr/local/pyenv
fi

export PYENV_ROOT="/usr/local/pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
pyenv install -s 3.10.14
pyenv global 3.10.14

# uv (Astral) — fast Python package manager
curl -fsSL https://astral.sh/uv/install.sh | sh

# Make pyenv available for all shells
if ! grep -q 'pyenv init' /etc/profile; then
  cat >> /etc/profile <<'EOF'
export PYENV_ROOT="/usr/local/pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
EOF
fi

echo "[✓] Python 3.10 via pyenv and uv installed."
