# Terabits Cloud Desktop

A Linux desktop in the cloud: one container, one command. Open your browser and use a full Ubuntu XFCE desktop with Selkies streaming (no Guacamole, no VNC).

## Quick start (on Google Cloud VM)

1. **Create a VM** on Google Cloud: Ubuntu 22.04, e2-standard-2 (or larger), 80 GB disk. Allow **HTTP** and **HTTPS** (or at least allow TCP port **3001** in the firewall).
2. **Copy this project** to the VM (e.g. `git clone` or `scp`).
3. **SSH** into the VM and run:
   ```bash
   cd ~/terabitsai-1.2
   sudo bash scripts/setup-vm.sh
   ```
4. Open **https://YOUR_VM_IP:3001** in your browser.
5. Log in with **admin** / **changeme** (or the password you set via `DESKTOP_PASSWORD`).

You get a full XFCE desktop: file manager, terminal, Chromium, clipboard, file upload/download via the sidebar. Change the password after first login if you expose the VM to the internet.

Full steps and troubleshooting: [docs/SETUP.md](docs/SETUP.md).

## Project layout

- `docker-compose.yml` — Single webtop service (Ubuntu XFCE in the browser)
- `scripts/setup-vm.sh` — One-time VM setup (Docker, pull image, start service)
- `docs/SETUP.md` — Google Cloud deployment and troubleshooting

## Optional: custom password

Before running the setup script:

```bash
export DESKTOP_PASSWORD=your_secure_password
sudo -E bash scripts/setup-vm.sh
```

Or set `DESKTOP_PASSWORD` in a `.env` file in the project root before `docker compose up`.

## What's next

Phase 2 (planned) adds an AI layer so a model (e.g. Gemini) can perform tasks on this desktop. Phase 3 adds multi-user support (one desktop per user).
