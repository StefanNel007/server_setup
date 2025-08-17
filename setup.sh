#!/usr/bin/env bash
# Ubuntu Server Setup – hardened & idempotent
set -euo pipefail

###############################################################################
# Configuration
###############################################################################
PYTHON_VERSION="3.12.7"
NODE_LTS="lts/*"
LOGFILE="/tmp/server_setup.log"
###############################################################################

log() {
  echo "[$(date '+%F %T')] $*" | tee -a "$LOGFILE"
}
log "Starting server setup…"

###############################################################################
# 1. Base packages
###############################################################################
sudo apt-get update -qq
sudo apt-get install -yqq \
  build-essential curl git gnupg lsb-release ca-certificates \
  apt-transport-https software-properties-common jq \
  python-is-python3 pip3

###############################################################################
# 2. uv (user-local)
###############################################################################
if ! command -v uv >/dev/null 2>&1; then
  log "Installing uv"
  curl --proto '=https' --tlsv1.2 -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
else
  log "uv already installed – skipping"
fi

###############################################################################
# 3. Python 3.12.7 (system-wide, safe)
###############################################################################
INSTALL_DIR="/opt/python/${PYTHON_VERSION}"
if [[ ! -d "${INSTALL_DIR}/bin" ]]; then
  log "Installing Python ${PYTHON_VERSION} under ${INSTALL_DIR}"
  sudo mkdir -p /opt/python
  sudo env "PATH=$PATH" UV_PYTHON_INSTALL_DIR=/opt/python \
       uv python install "${PYTHON_VERSION}"
else
  log "Python ${PYTHON_VERSION} already installed"
fi

###############################################################################
# 4. Nginx (latest stable from official repo)
###############################################################################
NGINX_KEY="/usr/share/keyrings/nginx-archive-keyring.gpg"
if [[ ! -f "$NGINX_KEY" ]]; then
  curl -fsSL https://nginx.org/keys/nginx_signing.key | \
    sudo gpg --dearmor -o "$NGINX_KEY"
  echo "deb [signed-by=$NGINX_KEY] \
http://nginx.org/packages/ubuntu $(lsb_release -cs) nginx" | \
    sudo tee /etc/apt/sources.list.d/nginx.list >/dev/null
fi
sudo apt-get update -qq
sudo apt-get install -yqq nginx
sudo systemctl enable --now nginx

###############################################################################
# 5. Node LTS via NVM
###############################################################################
if [[ ! -d "$HOME/.nvm" ]]; then
  NVM_VERSION="$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | jq -r .tag_name)"
  curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
fi
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm install "${NODE_LTS}" >/dev/null
nvm alias default "${NODE_LTS}" >/dev/null
npm install -g npm@latest >/dev/null

###############################################################################
# 6. Docker Engine + Compose plugin
###############################################################################
DOCKER_KEY="/usr/share/keyrings/docker-archive-keyring.gpg"
if [[ ! -f "$DOCKER_KEY" ]]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o "$DOCKER_KEY"
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=$DOCKER_KEY] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
fi
sudo apt-get update -qq
sudo apt-get install -yqq \
  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER" 2>/dev/null || true

###############################################################################
# 7. Final verification
###############################################################################
log "--- Versions ---"
uv --version
/opt/python/3.12.7/bin/python3 --version
nginx -v
node --version
npm --version
docker --version
docker compose version
log "Setup complete. Log saved to $LOGFILE"
log "You may need to log out/in or run 'newgrp docker' to use Docker without sudo."
