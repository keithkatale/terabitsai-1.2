#!/usr/bin/env bash
# Cloud Desktop System - One-time VM setup script
# Run this on a fresh Ubuntu 22.04 Google Cloud VM (e.g. after cloning the project into /opt/cloud-desktop or home dir).
# Usage: sudo bash scripts/setup-vm.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
INIT_DIR="${PROJECT_ROOT}/init"
COMPOSE_FILE="${PROJECT_ROOT}/docker-compose.yml"
DESKTOP_IMAGE_NAME="cloud-desktop-xfce"

echo "[*] Cloud Desktop setup - starting from ${PROJECT_ROOT}"

# --- Install Docker if not present ---
if ! command -v docker &>/dev/null; then
  echo "[*] Installing Docker..."
  curl -fsSL https://get.docker.com -o /tmp/install-docker.sh
  sh /tmp/install-docker.sh
  rm -f /tmp/install-docker.sh
  systemctl enable docker
  systemctl start docker
else
  echo "[*] Docker already installed: $(docker --version)"
fi

# --- Ensure Docker Compose plugin is available ---
if ! docker compose version &>/dev/null; then
  echo "[*] Installing Docker Compose plugin..."
  apt-get update -qq
  apt-get install -y docker-compose-plugin
fi
echo "[*] Docker Compose: $(docker compose version)"

# --- Generate Guacamole PostgreSQL schema (init/initdb.sql) ---
mkdir -p "${INIT_DIR}"
if [ ! -f "${INIT_DIR}/initdb.sql" ] || [ ! -s "${INIT_DIR}/initdb.sql" ]; then
  echo "[*] Generating Guacamole database schema..."
  docker pull guacamole/guacamole:1.6.0
  docker run --rm guacamole/guacamole:1.6.0 /opt/guacamole/bin/initdb.sh --postgresql > "${INIT_DIR}/initdb.sql"
  echo "[*] Created ${INIT_DIR}/initdb.sql"
else
  echo "[*] Guacamole schema already present at ${INIT_DIR}/initdb.sql"
fi

# --- Build desktop image ---
echo "[*] Building desktop image (${DESKTOP_IMAGE_NAME})..."
docker build -t "${DESKTOP_IMAGE_NAME}" "${PROJECT_ROOT}/desktop-image"

# --- Start Guacamole stack ---
echo "[*] Starting Guacamole (postgres, guacd, guacamole)..."
cd "${PROJECT_ROOT}"
export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-guacamole_secure_password}"
docker compose -f "${COMPOSE_FILE}" up -d

echo ""
echo "[+] Setup complete."
echo "    Guacamole: http://$(curl -s -H 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip 2>/dev/null || echo 'YOUR_VM_IP'):8080/guacamole/"
echo "    Default login: guacadmin / guacadmin (change after first login)"
echo ""
echo "    To add a desktop connection in Guacamole: create a new connection, protocol VNC, hostname = the container IP or host that runs the desktop container (see manage_desktops.py)."
