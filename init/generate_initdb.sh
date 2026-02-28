#!/usr/bin/env bash
# Generate init/initdb.sql from the official Guacamole image.
# Run from project root: bash init/generate_initdb.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
docker pull guacamole/guacamole:1.6.0
docker run --rm guacamole/guacamole:1.6.0 /opt/guacamole/bin/initdb.sh --postgresql > "${SCRIPT_DIR}/initdb.sql"
echo "Created ${SCRIPT_DIR}/initdb.sql"
