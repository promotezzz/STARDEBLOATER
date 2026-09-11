# Deploying the STARDEBLOAT Showcase Website to Your Domain

The **stardebloat** showcase website is a high-performance, single-binary Rust web server built with **Axum** and **Tokio**. All HTML, styles, and assets are embedded directly into the binary at compile time.

---

## 1. Running Locally or on Windows

### Quick Start:
Inside the `website` directory:
```bash
cargo run --release
```
Or run the pre-compiled binary:
```bash
.\target\release\stardebloat-website.exe
```

By default, it listens on port `8080` (accessible at `http://localhost:8080`).

To specify a custom port:
```powershell
$env:PORT = "80"
.\target\release\stardebloat-website.exe
```

---

## 2. Pointing Your Domain to the Website

### Option A: Cloudflare Tunnel (Recommended — Free & No Port Forwarding Required)
If you are running the server from a local PC or home server:
1. Install [Cloudflare `cloudflared`](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/get-started/create-remote-tunnel/).
2. Log in and route your domain (e.g. `stardebloat.com`) to `http://localhost:8080`.
3. Cloudflare automatically provides free SSL/HTTPS, DDoS protection, and routes your domain without opening router ports.

### Option B: Linux VPS (Ubuntu / Debian / DigitalOcean / Hetzner)
1. **Cross-compile or compile on VPS**:
   ```bash
   git clone https://github.com/promotezzz/STARDEBLOATER.git
   cd STARDEBLOATER/website
   cargo build --release
   ```
2. **Setup Systemd Service** (`/etc/systemd/system/stardebloat.service`):
   ```ini
   [Unit]
   Description=STARDEBLOAT Website
   After=network.target

   [Service]
   Type=simple
   User=root
   WorkingDirectory=/var/www/stardebloat/website
   ExecStart=/var/www/stardebloat/website/target/release/stardebloat-website
   Restart=always
   Environment=PORT=8080

   [Install]
   WantedBy=multi-user.target
   ```
   Enable and start:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable --now stardebloat
   ```

3. **Reverse Proxy with Caddy (Automatic HTTPS)**:
   Install [Caddy](https://caddyserver.com/):
   Edit `/etc/caddy/Caddyfile`:
   ```caddy
   yourdomain.com {
       reverse_proxy localhost:8080
   }
   ```
   Restart Caddy:
   ```bash
   sudo systemctl restart caddy
   ```
   Caddy automatically provisions and renews a free Let's Encrypt SSL certificate for your domain.

4. **DNS Settings**:
   In your domain registrar (Namecheap, GoDaddy, Cloudflare, Porkbun, etc.):
   - **Type**: `A`
   - **Name**: `@` (or `www`)
   - **Value**: Your VPS Public IPv4 address

---

## 3. Supported Endpoints

- `GET /` — Responsive Star Wars Death Star black & red landing page.
  - Automatically detects `curl` or `PowerShell` User-Agent and serves the CLI script directly!
- `GET /run` or `GET /install` — Direct PowerShell one-liner endpoint:
  ```powershell
  irm https://yourdomain.com/run | iex
  ```
- `GET /download` — Direct redirect to GitHub `.zip` source archive.
- `GET /health` — Health check endpoint (`200 OK`).
- `GET /assets/deathstar.png` — Embedded Death Star logo asset.
