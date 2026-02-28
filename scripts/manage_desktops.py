#!/usr/bin/env python3
"""
Create and delete desktop containers and register them in Apache Guacamole.
Each desktop is a VNC-serving container; Guacamole connects to it so users can
see the desktop in their browser.

Usage:
  python manage_desktops.py create <guacamole_username> [--connection-name NAME]
  python manage_desktops.py delete <container_name>
  python manage_desktops.py list

Requires: Docker socket access, PostgreSQL reachable at GUACAMOLE_DB_* env vars or defaults.
"""

import argparse
import os
import sys

try:
    import docker
    import psycopg2
except ImportError:
    print("Install dependencies: pip install docker psycopg2-binary", file=sys.stderr)
    sys.exit(1)

# Guacamole DB connection (defaults match docker-compose)
GUACAMOLE_DB_HOST = os.environ.get("GUACAMOLE_DB_HOST", "127.0.0.1")
GUACAMOLE_DB_PORT = int(os.environ.get("GUACAMOLE_DB_PORT", "5432"))
GUACAMOLE_DB_NAME = os.environ.get("GUACAMOLE_DB_NAME", "guacamole_db")
GUACAMOLE_DB_USER = os.environ.get("GUACAMOLE_DB_USER", "guacamole_user")
GUACAMOLE_DB_PASSWORD = os.environ.get("GUACAMOLE_DB_PASSWORD", "guacamole_secure_password")

DESKTOP_IMAGE = os.environ.get("DESKTOP_IMAGE", "cloud-desktop-xfce")
GUACAMOLE_NETWORK = os.environ.get("GUACAMOLE_NETWORK", "clouddesktop_guacamole")
VNC_PORT = 5901


def get_db_connection():
    return psycopg2.connect(
        host=GUACAMOLE_DB_HOST,
        port=GUACAMOLE_DB_PORT,
        dbname=GUACAMOLE_DB_NAME,
        user=GUACAMOLE_DB_USER,
        password=GUACAMOLE_DB_PASSWORD,
    )


def get_entity_id(cursor, username: str):
    """Return entity_id for a Guacamole user (guacamole_entity.name = username, type = 'USER')."""
    cursor.execute(
        "SELECT entity_id FROM guacamole_entity WHERE name = %s AND type = 'USER'",
        (username,),
    )
    row = cursor.fetchone()
    if not row:
        return None
    return row[0]


def create_desktop(guacamole_username: str, connection_name: str | None = None) -> None:
    client = docker.from_env()
    container_name = ("desktop-" + guacamole_username + "-" + os.urandom(4).hex())[:30]
    connection_display_name = connection_name or ("Desktop (" + guacamole_username + ")")

    # Ensure network exists
    try:
        client.networks.get(GUACAMOLE_NETWORK)
    except docker.errors.NotFound:
        print(
            "Network {} not found. Start Guacamole first: docker compose up -d".format(GUACAMOLE_NETWORK),
            file=sys.stderr,
        )
        sys.exit(1)

    # Run desktop container on the Guacamole network so guacd can reach it
    container = client.containers.run(
        DESKTOP_IMAGE,
        name=container_name,
        detach=True,
        network=GUACAMOLE_NETWORK,
        remove=False,
    )
    if hasattr(container, "reload"):
        container.reload()
    else:
        container = client.containers.get(container_name)

    # Resolve container IP on the Guacamole network
    container.reload()
    net_settings = container.attrs.get("NetworkSettings", {}).get("Networks", {})
    container_ip = net_settings.get(GUACAMOLE_NETWORK, {}).get("IPAddress")
    if not container_ip:
        container.stop()
        container.remove()
        print("Could not get container IP. Desktop container removed.", file=sys.stderr)
        sys.exit(1)

    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO guacamole_connection (connection_name, protocol) VALUES (%s, 'vnc') RETURNING connection_id",
                (connection_display_name,),
            )
            connection_id = cur.fetchone()[0]
            cur.execute(
                "INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value) VALUES (%s, 'hostname', %s), (%s, 'port', %s)",
                (connection_id, container_ip, connection_id, str(VNC_PORT)),
            )
            entity_id = get_entity_id(cur, guacamole_username)
            if entity_id is not None:
                cur.execute(
                    "INSERT INTO guacamole_connection_permission (entity_id, connection_id, permission) VALUES (%s, %s, 'READ')",
                    (entity_id, connection_id),
                )
        conn.commit()
    except Exception as e:
        conn.rollback()
        container.stop()
        container.remove()
        print("Database error: {}".format(e), file=sys.stderr)
        sys.exit(1)
    finally:
        conn.close()

    print("Desktop container: {}".format(container_name))
    print("VNC endpoint: {}:{}".format(container_ip, VNC_PORT))
    print("In Guacamole, open the connection named:", connection_display_name)
    print("(If the user does not see it, grant them READ permission on this connection in Guacamole Settings.)")


def delete_desktop(container_name: str) -> None:
    client = docker.from_env()
    try:
        container = client.containers.get(container_name)
    except docker.errors.NotFound:
        print("Container not found: {}".format(container_name), file=sys.stderr)
        sys.exit(1)
    container.stop()
    container.remove()
    print("Stopped and removed container: {}".format(container_name))


def list_desktops() -> None:
    client = docker.from_env()
    for c in client.containers.list(all=True):
        name = c.name or ""
        image_name = (c.image.tags[0] if c.image.tags else str(c.image)) if c.image else ""
        if name.startswith("desktop-") or DESKTOP_IMAGE in image_name:
            print(name, c.status)


def main():
    parser = argparse.ArgumentParser(description="Manage desktop containers and Guacamole connections")
    sub = parser.add_subparsers(dest="command", required=True)
    create_parser = sub.add_parser("create", help="Create a new desktop container and register in Guacamole")
    create_parser.add_argument("username", help="Guacamole username that will get access to this desktop")
    create_parser.add_argument("--connection-name", default=None, help="Display name for the connection in Guacamole")
    del_parser = sub.add_parser("delete", help="Stop and remove a desktop container")
    del_parser.add_argument("container_name", help="Container name (e.g. from list)")
    sub.add_parser("list", help="List desktop containers")
    args = parser.parse_args()

    if args.command == "create":
        create_desktop(args.username, args.connection_name)
    elif args.command == "delete":
        delete_desktop(args.container_name)
    elif args.command == "list":
        list_desktops()


if __name__ == "__main__":
    main()
