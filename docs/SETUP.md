# Cloud Desktop System — Setup Guide

This guide walks you through getting the cloud desktop running on Google Cloud. When done, users can open a link in their browser, log in to Apache Guacamole, and use a full Linux desktop.

---

## Prerequisites

- A Google Cloud Platform account (with free credits or billing enabled).
- A domain name (optional for testing; required for HTTPS with your own hostname).

---

## Step 1: Create the Google Cloud VM

1. Go to [Google Cloud Console](https://console.cloud.google.com/) and select or create a project.
2. Open **Compute Engine** → **VM instances** → **Create instance**.
3. Set:
   - **Name:** e.g. `cloud-desktop`
   - **Region:** e.g. `us-central1` (pick one near your users).
   - **Machine type:** `e2-standard-2` (2 vCPUs, 8 GB RAM). Use a larger type if you expect many simultaneous desktops.
   - **Boot disk:** Click **Change** → **Ubuntu 22.04 LTS** → **80 GB** (or more) → **Select**.
   - **Firewall:** Allow **HTTP** and **HTTPS** (check both under "Firewall").
4. Click **Create**.

5. Note the **External IP** of the VM (e.g. `34.x.x.x`). You will use this to open Guacamole and, if you use a domain, point the domain to this IP.

---

## Step 2: Copy the Project to the VM

Copy this project onto the VM so the setup script and Docker files are available.

**Option A — From your machine (if the project is in a git repo or you have the files):**

```bash
# From your laptop (replace VM_EXTERNAL_IP and path to your project)
scp -r /path/to/terabits-1.2 VM_EXTERNAL_IP:~/
```

**Option B — On the VM (if you have the repo in Git):**

```bash
# SSH into the VM first (see Step 3), then:
git clone <your-repo-url> ~/terabits-1.2
cd ~/terabits-1.2
```

**Option C — Manual upload:** Zip the project on your computer, upload the zip to the VM (e.g. via Cloud Console “Upload file” in the SSH session), and unzip it on the VM.

---

## Step 3: SSH Into the VM

1. In Cloud Console, go to **Compute Engine** → **VM instances**.
2. Click **SSH** next to your VM to open a browser-based SSH session (or use `gcloud compute ssh INSTANCE_NAME` from your laptop).

You should be in a shell on the VM (e.g. `username@cloud-desktop:~$`).

---

## Step 4: Run the Setup Script

On the VM, from the project root:

```bash
cd ~/terabits-1.2   # or the path where you copied the project
sudo bash scripts/setup-vm.sh
```

The script will:

- Install Docker and Docker Compose (if not already installed).
- Generate the Guacamole PostgreSQL schema into `init/initdb.sql`.
- Build the desktop image (`cloud-desktop-xfce`).
- Start the Guacamole stack (PostgreSQL, guacd, Guacamole web app).

When it finishes, it will print a URL like:

`http://YOUR_VM_IP:8080/guacamole/`

---

## Step 5: Open Guacamole and Log In

1. In your browser, open: `http://YOUR_VM_IP:8080/guacamole/`
2. Log in with the default admin account:
   - **Username:** `guacadmin`
   - **Password:** `guacadmin`
3. Change the password when prompted (recommended).

You should see the Guacamole home screen. There are no desktop connections yet; you add them in the next step.

---

## Step 6: Create a Desktop for a User

Each user needs a Guacamole user account and a desktop container. The script `scripts/manage_desktops.py` creates a new desktop container and registers it in Guacamole.

**6.1 Create a Guacamole user (if needed)**  
In Guacamole: **Settings** (gear) → **Users** → **New User**. Create a user (e.g. `alice`) and set a password. Save.

**6.2 Install Python dependencies and run the manager:**

On the VM:

```bash
cd ~/terabits-1.2
pip install --user -r scripts/requirements.txt
# Or: sudo pip3 install -r scripts/requirements.txt

# Create a desktop for user "alice" and register it in Guacamole
python3 scripts/manage_desktops.py create alice
```

The script will print the new container name and the connection name in Guacamole.

**6.3 Open the desktop:**  
Log in to Guacamole as `alice` (or refresh if already logged in). The new connection (e.g. "Desktop (alice)") should appear. Click it to open the Linux desktop in the browser.

**Useful commands:**

```bash
# List desktop containers
python3 scripts/manage_desktops.py list

# Remove a desktop container (replace with actual container name from list)
python3 scripts/manage_desktops.py delete desktop-alice-a1b2c3d4
```

---

## Step 7 (Optional): Use Your Domain and HTTPS

To use a hostname like `desktop.yourdomain.com` and HTTPS:

**7.1 Point the domain to the VM**  
In your domain registrar or DNS provider, add an **A** record:

- **Name/host:** `desktop` (or `@` for root domain).
- **Value:** The VM’s external IP (e.g. `34.x.x.x`).
- **TTL:** 300 or default.

Wait until DNS propagates (e.g. `dig desktop.yourdomain.com` or an online checker).

**7.2 Install Nginx and Certbot on the VM**

```bash
sudo apt-get update
sudo apt-get install -y nginx certbot python3-certbot-nginx
```

**7.3 Configure Nginx**

Copy the project’s Nginx config and replace the placeholder hostname:

```bash
sudo cp ~/terabits-1.2/nginx/nginx.conf /etc/nginx/sites-available/guacamole
sudo sed -i 's/desktop.yourdomain.com/YOUR_ACTUAL_DOMAIN/g' /etc/nginx/sites-available/guacamole
sudo ln -sf /etc/nginx/sites-available/guacamole /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

**7.4 Get an HTTPS certificate**

```bash
sudo certbot --nginx -d desktop.yourdomain.com
```

Follow the prompts. Certbot will configure SSL in Nginx.

**7.5 Access Guacamole via domain**  
Open `https://desktop.yourdomain.com` in your browser. You should see the Guacamole login page over HTTPS.

---

## Troubleshooting

- **Guacamole page does not load:** Ensure the VM firewall allows **tcp:8080** (and **tcp:80** / **tcp:443** if using Nginx). In Google Cloud, check **VPC network** → **Firewall** and add an ingress rule for these ports if needed.
- **Desktop connection stays “Connecting…”:** The desktop container must be on the same Docker network as Guacamole. The setup uses the network `clouddesktop_guacamole`. If you changed the Compose project name, set `GUACAMOLE_NETWORK` when running `manage_desktops.py` (e.g. `GUACAMOLE_NETWORK=yourproject_guacamole python3 scripts/manage_desktops.py create alice`).
- **“Connection refused” to PostgreSQL from `manage_desktops.py`:** Ensure the Guacamole stack is running (`docker compose ps`) and that the Postgres container exposes port 5432 to localhost (as in the provided `docker-compose.yml`). Use `GUACAMOLE_DB_HOST=127.0.0.1` (default) when running the script on the same host.
- **Desktop container exits immediately:** Check logs: `docker logs CONTAINER_NAME`. Ensure the desktop image was built successfully (`docker images | grep cloud-desktop-xfce`) and that `scripts/setup-vm.sh` completed without errors.

---

## Summary

| Step | Action |
|------|--------|
| 1 | Create Ubuntu 22.04 VM on Google Cloud (e2-standard-2, 80 GB, HTTP/HTTPS allowed). |
| 2 | Copy this project to the VM. |
| 3 | SSH into the VM. |
| 4 | Run `sudo bash scripts/setup-vm.sh` from the project root. |
| 5 | Open `http://VM_IP:8080/guacamole/` and log in as `guacadmin` / `guacadmin`; change password. |
| 6 | Create a Guacamole user, then run `python3 scripts/manage_desktops.py create USERNAME` to give that user a desktop. |
| 7 | (Optional) Point your domain to the VM, install Nginx + Certbot, and use the provided Nginx config to serve Guacamole over HTTPS. |

After this, users log in to Guacamole and open their assigned desktop connection to use the Linux desktop in the browser.
