# Terabits Cloud Desktop — Setup Guide

This guide walks you through running the Terabits cloud desktop (ByteBot stack) on Google Cloud. You get a web Task UI where you create AI tasks and watch a Linux desktop complete them, plus direct desktop access via noVNC.

---

## Prerequisites

- A Google Cloud Platform account (with free credits or billing enabled).
- A **Gemini API key** (for AI tasks): [Google AI Studio](https://aistudio.google.com/apikey).

---

## Step 1: Create the Google Cloud VM

1. Go to [Google Cloud Console](https://console.cloud.google.com/) and select or create a project.
2. Open **Compute Engine** → **VM instances** → **Create instance**.
3. Set:
   - **Name:** e.g. `terabits-desktop`
   - **Region:** e.g. `us-central1` (pick one near you).
   - **Machine type:** `e2-standard-2` (2 vCPUs, 8 GB RAM). Use a larger type for smoother desktop and AI.
   - **Boot disk:** **Change** → **Ubuntu 22.04 LTS** → **80 GB** (or more) → **Select**.
   - **Firewall:** Allow **HTTP** and **HTTPS** (or add custom rules in Step 2).
4. Click **Create**.
5. Note the **External IP** of the VM.

---

## Step 2: Open firewall for ports 9992 and 9990

- **9992** — Task UI (create tasks, view desktop).
- **9990** — Desktop / noVNC (optional if you only use the Task UI).

In **VPC network** → **Firewall** → **Create firewall rule**:

- **Name:** e.g. `allow-terabits`
- **Targets:** All instances (or a specific tag)
- **Source IP ranges:** `0.0.0.0/0` (or restrict to your IPs)
- **Protocols and ports:** **tcp** → **9992,9990**

Save.

---

## Step 3: Copy the project to the VM

**Option A — Git (on the VM):**

```bash
git clone https://github.com/keithkatale/terabitsai-1.2.git ~/terabitsai-1.2
cd ~/terabitsai-1.2
```

**Option B — From your machine (scp):**

```bash
scp -r /path/to/terabits-1.2 VM_USER@VM_EXTERNAL_IP:~/terabitsai-1.2
```

---

## Step 4: SSH into the VM

1. In Cloud Console: **Compute Engine** → **VM instances**.
2. Click **SSH** next to your VM (or use `gcloud compute ssh INSTANCE_NAME`).

---

## Step 5: Run the setup script

From the project root on the VM:

```bash
cd ~/terabitsai-1.2
sudo bash scripts/setup-vm.sh
```

The script will:

- Install Docker and Docker Compose (if not already installed).
- Create `.env` from `.env.example` if missing.
- Pull ByteBot images (desktop, agent, UI, postgres).
- Start all four containers.

At the end it prints:

```
[+] Setup complete.
    Task UI (create AI tasks, view desktop): http://YOUR_VM_IP:9992
    Desktop / noVNC only:                    http://YOUR_VM_IP:9990

    Set GEMINI_API_KEY in .env and run 'docker compose up -d' again to enable AI tasks.
```

---

## Step 6: Enable AI (Gemini)

1. On the VM, edit `.env` in the project root:
   ```bash
   nano ~/terabitsai-1.2/.env
   ```
2. Set your Gemini API key:
   ```
   GEMINI_API_KEY=your_actual_key_here
   ```
3. Restart the agent so it picks up the key:
   ```bash
   cd ~/terabitsai-1.2
   sudo docker compose up -d
   ```

---

## Step 7: Open the Task UI and use the desktop

1. In your browser, open: **http://YOUR_VM_IP:9992**
2. You should see the ByteBot Task UI. Create a task (e.g. “Open Firefox and go to Wikipedia”) and watch the desktop execute it.
3. Optionally open **http://YOUR_VM_IP:9990** for direct noVNC desktop access.

No sign-in is required by default; the Task UI and desktop are open to anyone who can reach the VM. For production, put the stack behind a reverse proxy with authentication.

---

## Useful commands

```bash
# From project root on the VM

# Show container status
docker compose ps

# View logs (desktop, agent, or ui)
docker compose logs -f desktop
docker compose logs -f agent
docker compose logs -f ui

# Stop everything
docker compose down

# Start again (data in postgres volume is preserved)
docker compose up -d
```

---

## Troubleshooting

- **Task UI or desktop does not load:**  
  Ensure the firewall allows **tcp:9992** and **tcp:9990**. From another machine: `curl -s -o /dev/null -w "%{http_code}" http://VM_IP:9992`.

- **AI tasks do nothing / “no provider”:**  
  Set `GEMINI_API_KEY` in `.env` and run `docker compose up -d`. Check agent logs: `docker compose logs agent`.

- **Agent or UI keeps restarting:**  
  Ensure postgres is healthy: `docker compose ps`. Agent runs Prisma migrations on start; if postgres was not ready, restart: `docker compose restart agent`.

- **Desktop is slow:**  
  Use a larger machine type (e.g. e2-standard-4) and a region close to you.

---

## Summary

| Step | Action |
|------|--------|
| 1 | Create Ubuntu 22.04 VM on Google Cloud (e2-standard-2, 80 GB). |
| 2 | Add firewall rule for **tcp:9992** and **tcp:9990**. |
| 3 | Copy this project to the VM. |
| 4 | SSH into the VM. |
| 5 | Run `sudo bash scripts/setup-vm.sh` from the project root. |
| 6 | Set `GEMINI_API_KEY` in `.env` and run `docker compose up -d` again. |
| 7 | Open **http://VM_IP:9992** for the Task UI; **http://VM_IP:9990** for desktop only. |

You now have a cloud desktop with an AI task layer (ByteBot + Gemini).
