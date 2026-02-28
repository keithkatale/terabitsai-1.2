#!/usr/bin/env bash
# Generate init/initdb.sql from the official Guacamole image.
# Run from project root: bash scripts/generate_guacamole_initdb.sh
# Do NOT put this script inside init/ - Postgres runs every .sh in init/ at container start.

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
INIT_DIR="${PROJECT_ROOT}/init"
mkdir -p "${INIT_DIR}"
docker pull guacamole/guacamole:1.6.0
docker run --rm guacamole/guacamole:1.6.0 /opt/guacamole/bin/initdb.sh --postgresql > "${INIT_DIR}/initdb.sql"
echo "Created ${INIT_DIR}/initdb.sql"
