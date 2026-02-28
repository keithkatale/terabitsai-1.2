# Terabits Cloud Desktop — Setup Guide

This guide walks you through running the Terabits cloud desktop on Google Cloud. When done, you open a link in your browser, log in with a username and password, and get a full Ubuntu XFCE desktop. One container, no Guacamole or VNC.

---

## Prerequisites

- A Google Cloud Platform account (with free credits or billing enabled).
- A domain name is optional for initial testing; you can use the VM’s external IP.

---

## Step 1: Create the Google Cloud VM

1. Go to [Google Cloud Console](https://console.cloud.google.com/) and select or create a project.
2. Open **Compute Engine** → **VM instances** → **Create instance**.
3. Set:
   - **Name:** e.g. `terabits-desktop`
   - **Region:** e.g. `us-central1` (pick one near you).
   - **Machine type:** `e2-standard-2` (2 vCPUs, 8 GB RAM). Use a larger type for smoother desktop use.
   - **Boot disk:** **Change** → **Ubuntu 22.04 LTS** → **80 GB** (or more) → **Select**.
   - **Firewall:** Allow **HTTP** and **HTTPS** (or create a custom rule allowing **tcp:3001**).
4. Click **Create**.
5. Note the **External IP** of the VM. You will use it to open the desktop in your browser.

---

## Step 2: Open firewall for port 3001

The desktop is served over HTTPS on port **3001**. Ensure the VM can receive traffic on that port.

- If you allowed **HTTPS** in Step 1, note that GCP’s “HTTPS” tag usually means port 443. For port 3001 you need an explicit rule.
- In **VPC network** → **Firewall** → **Create firewall rule**:
  - **Name:** e.g. `allow-desktop`
  - **Targets:** All instances (or a specific tag)
  - **Source IP ranges:** `0.0.0.0/0` (or restrict to your IPs)
  - **Protocols and ports:** **tcp** → **3001**
- Save.

---

## Step 3: Copy the project to the VM

**Option A — Git (on the VM):**

```bash
# SSH into the VM first (Step 4), then:
git clone https://github.com/keithkatale/terabitsai-1.2.git ~/terabitsai-1.2
cd ~/terabitsai-1.2
```

**Option B — From your machine (scp):**

```bash
scp -r /path/to/terabits-1.2 VM_USER@VM_EXTERNAL_IP:~/
```

**Option C — Upload a zip** via Cloud Console SSH “Upload file” and unzip on the VM.

---

## Step 4: SSH into the VM

1. In Cloud Console: **Compute Engine** → **VM instances**.
2. Click **SSH** next to your VM (or use `gcloud compute ssh INSTANCE_NAME` from your laptop).

You should be in a shell on the VM.

---

## Step 5: Run the setup script

From the project root on the VM:

```bash
cd ~/terabitsai-1.2
sudo bash scripts/setup-vm.sh
```

The script will:

- Install Docker and Docker Compose (if not already installed).
- Pull the webtop image (`lscr.io/linuxserver/webtop:ubuntu-xfce`).
- Start the desktop container.

At the end it prints something like:

```
[+] Setup complete.
    Desktop: https://34.x.x.x:3001
    Login: admin / changeme
```

---

## Step 6: Open the desktop in your browser

1. In your browser, open: **https://YOUR_VM_IP:3001**
2. Your browser will likely warn about the certificate (the container uses a self-signed cert). Choose “Advanced” → “Proceed to …” to continue.
3. Log in with:
   - **Username:** `admin`
   - **Password:** `changeme`
4. You should see the full XFCE desktop (panel, icons, file manager, terminal, Chromium, etc.).

Change the password by setting `DESKTOP_PASSWORD` and recreating the container, or in a later version via the UI.

---

## Optional: Custom password

To set a different password before the first run:

```bash
cd ~/terabitsai-1.2
export DESKTOP_PASSWORD=your_secure_password
sudo -E bash scripts/setup-vm.sh
```

Or create a `.env` file in the project root:

```
DESKTOP_PASSWORD=your_secure_password
```

Then run `sudo docker compose up -d` so Compose reads `.env`.

---

## Optional: Domain and reverse proxy (HTTPS with Let’s Encrypt)

To use a hostname like `desktop.yourdomain.com` with a valid certificate:

1. Point your domain’s **A** record to the VM’s external IP.
2. Install a reverse proxy (e.g. Nginx or Caddy) on the VM.
3. Proxy `https://desktop.yourdomain.com` to `http://127.0.0.1:3001` (or use the HTTP port 3000 if the webtop image exposes it for proxying). The webtop container uses HTTPS internally; your proxy can terminate SSL with Let’s Encrypt and forward to the container.
4. Add a firewall rule for **tcp:443** if you use standard HTTPS on the proxy.

Detailed Nginx/Caddy steps depend on your choice; the main idea is: proxy to `localhost:3001` (or `3000`) and keep the desktop container bound to localhost or a private network if you want only the proxy to be public.

---

## Useful commands

```bash
# From project root on the VM

# Show container status
docker compose ps

# View desktop container logs
docker compose logs -f desktop

# Stop the desktop
docker compose down

# Start again (data in volume is preserved)
docker compose up -d
```

---

## Troubleshooting

- **Page does not load / connection refused:**  
  Ensure the firewall allows **tcp:3001** to the VM (see Step 2). Check from another machine: `curl -k https://VM_IP:3001` (you should get an HTTP response or redirect).

- **Certificate warning:**  
  Expected. The container uses a self-signed certificate. Use “Advanced” → “Proceed” for testing, or put the desktop behind a reverse proxy with Let’s Encrypt (see optional section above).

- **Container exits or keeps restarting:**  
  Run `docker compose logs desktop` and check for errors. Ensure the VM has at least 2 GB RAM and sufficient disk. The image requires `shm_size: 1gb`; the provided `docker-compose.yml` already sets this.

- **Desktop is slow:**  
  Use a larger machine type (e.g. e2-standard-4). Choose a region close to you. Selkies streaming is generally more efficient than VNC/Guacamole.

- **Forgot password:**  
  Set a new password by setting `DESKTOP_PASSWORD` in the environment, then run `docker compose down` and `docker compose up -d` so the container restarts with the new password.

---

## Summary

| Step | Action |
|------|--------|
| 1 | Create Ubuntu 22.04 VM on Google Cloud (e2-standard-2, 80 GB, allow HTTP/HTTPS or tcp:3001). |
| 2 | Add firewall rule for **tcp:3001** (and 443 if using a reverse proxy). |
| 3 | Copy this project to the VM. |
| 4 | SSH into the VM. |
| 5 | Run `sudo bash scripts/setup-vm.sh` from the project root. |
| 6 | Open **https://VM_IP:3001** in the browser, log in as **admin** / **changeme**. |

After this, you have a single-container cloud desktop. Phase 2 will add AI control; Phase 3 will add multi-user desktops.
