# Cloud Desktop - Ubuntu 22.04 + XFCE + TigerVNC
# Used by Guacamole to provide a browser-accessible Linux desktop per user.

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV USER=desktopuser
ENV UID=1000
ENV GID=1000
ENV VNC_PASSWORD=

# Install XFCE, TigerVNC, and basic applications
RUN apt-get update && apt-get install -y --no-install-recommends \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    tigervnc-common \
    dbus-x11 \
    firefox \
    thunar \
    mousepad \
    xfce4-terminal \
    sudo \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for the desktop session
RUN groupadd -g ${GID} ${USER} \
    && useradd -m -u ${UID} -g ${GID} -G sudo -s /bin/bash ${USER} \
    && echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# VNC directory and xstartup for XFCE
RUN mkdir -p /home/${USER}/.vnc

COPY xstartup /home/${USER}/.vnc/xstartup
RUN chmod +x /home/${USER}/.vnc/xstartup \
    && chown -R ${USER}:${USER} /home/${USER}/.vnc

# Default VNC resolution
ENV VNC_GEOMETRY=1280x720
ENV VNC_DEPTH=24

EXPOSE 5901

USER ${USER}
WORKDIR /home/${USER}

COPY startup.sh /startup.sh
USER root
RUN chmod +x /startup.sh
USER ${USER}

ENTRYPOINT ["/startup.sh"]
