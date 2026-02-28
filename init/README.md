# Guacamole database initialization

The file `initdb.sql` is **generated** by `scripts/setup-vm.sh` when you run the setup. It contains the PostgreSQL schema for Apache Guacamole (user accounts, connections, etc.).

To generate it manually without running the full setup:

```bash
docker run --rm guacamole/guacamole:1.6.0 /opt/guacamole/bin/initdb.sh --postgresql > init/initdb.sql
```

The PostgreSQL container runs this script on first start via the `docker-entrypoint-initdb.d` volume mount in `docker-compose.yml`.
