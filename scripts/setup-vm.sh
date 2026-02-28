#!/usr/bin/env bash
# Terabits Cloud Desktop - One-time VM setup script
# Run this on a fresh Ubuntu 22.04 Google Cloud VM (e.g. after cloning the project).
# Usage: sudo bash scripts/setup-vm.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_FILE="${PROJECT_ROOT}/docker-compose.yml"

echo "[*] Terabits Cloud Desktop setup - starting from ${PROJECT_ROOT}"

# --- Install Docker if not present ---
if ! command -v docker &>/dev/null; then
  echo "[*] Installing Docker..."
  curl -fsSL https://get.docker.com -o /tmp/install-docker.sh
  sh /tmp/install-docker.sh
  rm -f /tmp/install-docker.sh
  systemctl enable docker
  systemctl start docker
  if [ -n "${SUDO_USER}" ]; then
    usermod -aG docker "${SUDO_USER}"
  fi
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

# --- Pull webtop image ---
echo "[*] Pulling webtop image..."
docker pull lscr.io/linuxserver/webtop:ubuntu-xfce

# --- Start desktop service ---
echo "[*] Starting Terabits desktop..."
cd "${PROJECT_ROOT}"
docker compose -f "${COMPOSE_FILE}" up -d

VM_IP="$(curl -s -H 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip 2>/dev/null || echo 'YOUR_VM_IP')"

echo ""
echo "[+] Setup complete."
echo "    Desktop: https://${VM_IP}:3001"
echo "    Login: admin / changeme (or set DESKTOP_PASSWORD before running)"
echo ""
echo "    Allow TCP port 3001 in your firewall (e.g. Google Cloud VPC firewall) if needed."
echo "    For first visit, your browser may warn about the self-signed certificate; accept to continue."
echo ""
