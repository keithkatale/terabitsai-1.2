#!/usr/bin/env bash
# Terabits Cloud Desktop (ByteBot stack) - One-time VM setup
# Run on Ubuntu 22.04 (e.g. Google Cloud VM). Usage: sudo bash scripts/setup-vm.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_FILE="${PROJECT_ROOT}/docker-compose.yml"

echo "[*] Terabits Cloud Desktop (ByteBot) setup - starting from ${PROJECT_ROOT}"

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

# --- Docker Compose plugin ---
if ! docker compose version &>/dev/null; then
  echo "[*] Installing Docker Compose plugin..."
  apt-get update -qq
  apt-get install -y docker-compose-plugin
fi
echo "[*] Docker Compose: $(docker compose version)"

# --- Ensure .env exists ---
if [ ! -f "${PROJECT_ROOT}/.env" ]; then
  if [ -f "${PROJECT_ROOT}/.env.example" ]; then
    cp "${PROJECT_ROOT}/.env.example" "${PROJECT_ROOT}/.env"
    echo "[*] Created .env from .env.example — set GEMINI_API_KEY in .env for AI tasks."
  fi
fi

# --- Pull ByteBot images ---
echo "[*] Pulling ByteBot images..."
docker pull ghcr.io/bytebot-ai/bytebot-desktop:edge
docker pull ghcr.io/bytebot-ai/bytebot-agent:edge
docker pull ghcr.io/bytebot-ai/bytebot-ui:edge
docker pull postgres:16-alpine

# --- Start stack ---
echo "[*] Starting Terabits stack (desktop, postgres, agent, UI)..."
cd "${PROJECT_ROOT}"
docker compose -f "${COMPOSE_FILE}" up -d

VM_IP="$(curl -s -H 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip 2>/dev/null || echo 'YOUR_VM_IP')"

echo ""
echo "[+] Setup complete."
echo "    Task UI (create AI tasks, view desktop): http://${VM_IP}:9992"
echo "    Desktop / noVNC only:                    http://${VM_IP}:9990"
echo ""
echo "    Set GEMINI_API_KEY in .env and run 'docker compose up -d' again to enable AI tasks."
echo "    Allow TCP ports 9992 and 9990 in your firewall if needed."
echo ""
