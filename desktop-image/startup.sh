#!/bin/bash
# Launches TigerVNC server and keeps the container running.
# Guacamole connects to this VNC server to stream the desktop to the browser.

set -e

# Create .vnc/passwd if VNC_PASSWORD is set (TigerVNC requires a password file for non-local connections)
if [ -n "${VNC_PASSWORD}" ]; then
  echo "${VNC_PASSWORD}" | vncpasswd -f > /home/${USER}/.vnc/passwd
  chmod 600 /home/${USER}/.vnc/passwd
else
  # Empty password (allow connection without auth - Guacamole handles auth)
  vncpasswd -f <<< "" > /home/${USER}/.vnc/passwd 2>/dev/null || true
  chmod 600 /home/${USER}/.vnc/passwd 2>/dev/null || true
fi

# Remove stale lock/pid from previous runs
rm -f /home/${USER}/.vnc/*.pid /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true

# Start TigerVNC on display :1 (port 5901)
# -I-KNOW-THIS-IS-INSECURE: required when binding to all interfaces without auth;
# only guacd on the Docker network can reach this, not the public internet.
vncserver :1 \
  -geometry "${VNC_GEOMETRY:-1280x720}" \
  -depth "${VNC_DEPTH:-24}" \
  -localhost no \
  -SecurityTypes none \
  -I-KNOW-THIS-IS-INSECURE \
  -fg
