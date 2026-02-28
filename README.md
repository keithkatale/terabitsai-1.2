# Terabits Cloud Desktop

A Linux desktop in the cloud with an **AI task layer** (ByteBot). Open your browser to create tasks in natural language; the AI controls the desktop to complete them. Built on [ByteBot](https://github.com/bytebot-ai/bytebot).

## Quick start (Google Cloud VM)

1. **Create a VM**: Ubuntu 22.04, e2-standard-2 (or larger), 80 GB disk. Allow **TCP ports 9992 and 9990** in the firewall.
2. **Clone and run**:
   ```bash
   git clone https://github.com/keithkatale/terabitsai-1.2.git ~/terabitsai-1.2
   cd ~/terabitsai-1.2
   sudo bash scripts/setup-vm.sh
   ```
3. Open **http://YOUR_VM_IP:9992** — Task UI (create tasks, watch the desktop).
4. Open **http://YOUR_VM_IP:9990** — Desktop / noVNC only.
5. **Enable AI**: set `GEMINI_API_KEY=your_key` in `.env`, then run `docker compose up -d` again.

Full steps: [docs/SETUP.md](docs/SETUP.md).

## Project layout

- `docker-compose.yml` — ByteBot stack (desktop, postgres, agent, UI)
- `scripts/setup-vm.sh` — One-time VM setup (Docker, pull images, start stack)
- `.env.example` — Copy to `.env` and set `GEMINI_API_KEY` for AI tasks
- `docs/SETUP.md` — Google Cloud deployment and troubleshooting

## What you get

- **Task UI (port 9992)**: Create tasks in natural language; watch the AI use the desktop to complete them. Live desktop view, takeover mode.
- **Desktop (port 9990)**: Ubuntu XFCE with Firefox, terminal, file manager. Same desktop the AI controls.
- **AI**: Uses Google Gemini (set `GEMINI_API_KEY` in `.env`).

## Optional: Postgres password

Set `POSTGRES_PASSWORD` in `.env` to change the database password (default: `postgres`).
