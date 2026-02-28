# Guacamole database initialization

The file `initdb.sql` is **generated** by `scripts/setup-vm.sh` when you run the setup. It contains the PostgreSQL schema for Apache Guacamole (user accounts, connections, etc.).

To generate it manually without running the full setup (run from project root):

```bash
bash scripts/generate_guacamole_initdb.sh
```

Or with Docker only:

```bash
docker run --rm guacamole/guacamole:1.6.0 /opt/guacamole/bin/initdb.sh --postgresql > init/initdb.sql
```

The PostgreSQL container runs `.sql` and `.sh` files in this directory on first start. Do not put helper scripts (like `generate_guacamole_initdb.sh`) here—they belong in `scripts/`.
