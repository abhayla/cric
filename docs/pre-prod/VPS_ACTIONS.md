# Pre-Production: VPS Actions (Server Deployment)

These actions are performed on the VPS (`103.118.16.189`) running Windows Server 2022. They set up the production server environment for friend testing.

**Domain:** `cricscores.in` → Cloudflare DNS → `103.118.16.189` (Proxied)

**VPS Infrastructure:** This VPS already runs 4 production sites using **Nginx + Cloudflare + PM2**. CricApp follows the same conventions documented in `C:\Apps\shared\docs\`. See `C:\Apps\shared\docs\README.md` for full VPS documentation.

---

## Prerequisites (Manual — Before Claude Code Session on VPS)

- [ ] Point Cloudflare DNS A record for `cricscores.in` to `103.118.16.189` (Proxied / orange cloud)
- [ ] Point Cloudflare DNS A record for `www.cricscores.in` to `103.118.16.189` (Proxied / orange cloud)
- [ ] Verify DNS propagation: `nslookup cricscores.in` returns Cloudflare edge IP (not VPS IP — that's expected with Proxied mode)
- [ ] Ensure PostgreSQL 16 is installed and running as Windows Service
- [ ] Ensure Bun is installed (`bun --version`)
- [ ] Ensure Git is installed (`git --version`)
- [ ] Ensure PM2 is installed (`pm2 --version`) — already present for other hosted apps
- [ ] Ensure Nginx is running (`C:\Apps\nginx\nginx.exe -t`)
- [ ] Have `firebase-service-account.json` ready to copy to VPS

---

## Phase 1: Server Setup

### V1. Create Directory Structure

Following the standard `C:\Apps\<appname>\` convention used by all VPS-hosted apps:

```
C:\Apps\cricapp\
├── current\         # Server code (git clone of apps/server/ or full repo)
├── uploads\         # User-uploaded images
├── backups\         # pg_dump files
├── logs\            # PM2 logs + deploy logs
└── scripts\         # deploy.ps1, backup-db.bat
```

```powershell
mkdir C:\Apps\cricapp\current, C:\Apps\cricapp\uploads, C:\Apps\cricapp\backups, C:\Apps\cricapp\logs, C:\Apps\cricapp\scripts
```

### V2. Clone Repository and Install Dependencies

```powershell
cd C:\Apps\cricapp
git clone <repo-url> current   # Or copy apps/server/ content into current/
cd current
bun install
```

### V3. Configure Production Environment

Create `C:\Apps\cricapp\current\.env`:
```dotenv
DATABASE_URL=postgresql://cricapp_user:<password>@127.0.0.1:5432/cricapp
FIREBASE_SERVICE_ACCOUNT_PATH=C:\Apps\cricapp\current\firebase-service-account.json
PORT=3005
CORS_ORIGIN=https://cricscores.in
NODE_ENV=production
LOG_LEVEL=info
UPLOADS_DIR=C:\Apps\cricapp\uploads
MAX_UPLOAD_SIZE_MB=5
SYNC_BATCH_SIZE=50
WS_HEARTBEAT_INTERVAL_MS=30000
```

> **Note:** No separate `WS_PORT` — Bun/ElysiaJS handles WebSocket upgrade on the same HTTP port (3005). Port 3005 is the first available port per the VPS port allocation table in `C:\Apps\shared\docs\setup\NEW-WEBSITE-SETUP-GUIDE.md`.

Copy `firebase-service-account.json` to `C:\Apps\cricapp\current\`.

### V4. PostgreSQL Setup

```sql
-- Connect as postgres superuser
CREATE USER cricapp_user WITH PASSWORD '<strong_random_password>';
CREATE DATABASE cricapp;
GRANT ALL PRIVILEGES ON DATABASE cricapp TO cricapp_user;
```

Verify `postgresql.conf` (should already be configured for other apps):
```
listen_addresses = 'localhost'
```

Verify `pg_hba.conf` — only local connections:
```
host  all  all  127.0.0.1/32  scram-sha-256
```

### V5. Run Database Migrations and Seed

```powershell
cd C:\Apps\cricapp\current
bun run db:migrate
bun run db:seed
```

### V6. Verify Server Starts

```powershell
cd C:\Apps\cricapp\current
$env:NODE_ENV="production"; bun run start
# Check: http://localhost:3005/api/v1/health should return {"status":"ok","database":"connected"}
# Ctrl+C to stop
```

---

## Phase 2: Process Management (PM2)

All VPS-hosted apps use PM2 for process management. CricApp follows the same pattern.

### V7. Create PM2 Ecosystem Config

Create `C:\Apps\cricapp\current\ecosystem.config.js`:
```javascript
module.exports = {
  apps: [{
    name: 'cricapp',
    script: 'C:\\Users\\Administrator\\.bun\\bin\\bun.exe',
    args: 'run start',
    cwd: 'C:\\Apps\\cricapp\\current',
    interpreter: 'none',
    instances: 1,
    exec_mode: 'fork',
    max_memory_restart: '500M',
    env: {
      NODE_ENV: 'production',
      PORT: 3005
    },
    error_file: 'C:\\Apps\\cricapp\\logs\\error.log',
    out_file: 'C:\\Apps\\cricapp\\logs\\out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    autorestart: true,
    watch: false,
    max_restarts: 10,
    min_uptime: '10s',
    kill_timeout: 5000,
    windowsHide: true
  }]
};
```

> **Pattern:** Uses `interpreter: 'none'` with direct path to `bun.exe` — same approach as AlgoChanakya's Python/FastAPI backend. See `C:\Apps\shared\docs\pm2\PM2-ECOSYSTEM-TEMPLATES.md` Template 8.

### V8. Start CricApp with PM2

```powershell
cd C:\Apps\cricapp\current
pm2 start ecosystem.config.js
pm2 save   # CRITICAL — ensures PM2 resurrects the app on reboot
```

### V9. Verify Process Running

```powershell
pm2 describe cricapp
# Should show: status = online, restarts = 0

Invoke-WebRequest -Uri "http://localhost:3005/api/v1/health" -UseBasicParsing
# Should return 200 OK with {"status":"ok","database":"connected"}
```

---

## Phase 3: Reverse Proxy (Nginx + Cloudflare SSL)

The VPS uses **Nginx** as reverse proxy with **Cloudflare** handling SSL termination (Flexible mode). Nginx listens on port 80 only — Cloudflare terminates HTTPS on their edge and forwards HTTP to Nginx.

### V10. Create Nginx Site Config

Create `C:\Apps\nginx\conf\sites\cricscores.conf`:
```nginx
# CricApp - Cricket Scoring API + WebSocket
server {
    listen 80;
    server_name cricscores.in www.cricscores.in;

    access_log logs/cricscores-access.log;
    error_log logs/cricscores-error.log;

    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;

    # API requests
    location /api/ {
        proxy_pass http://127.0.0.1:3005/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # WebSocket
    location /ws {
        proxy_pass http://127.0.0.1:3005/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }

    # Uploaded images
    location /uploads/ {
        alias C:/Apps/cricapp/uploads/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # Health check (no access log noise)
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
```

> **WebSocket config** modeled on `algochanakya.conf` lines 36-48 (proven WS proxy with 86400s timeouts for long-lived connections).

### V11. Test and Reload Nginx

```powershell
# Validate config syntax
C:\Apps\nginx\nginx.exe -t

# Reload (zero-downtime — does NOT restart existing connections for other sites)
C:\Apps\nginx\nginx.exe -s reload
```

### V12. Configure Cloudflare

In the Cloudflare dashboard for `cricscores.in` (same setup as existing VPS sites):

1. **DNS Records:**
   - Type `A`, Name `@`, Content `103.118.16.189`, Proxy status: **Proxied** (orange cloud)
   - Type `A`, Name `www`, Content `103.118.16.189`, Proxy status: **Proxied** (orange cloud)

2. **SSL/TLS Settings:**
   - Encryption mode: **Flexible** (Cloudflare terminates SSL, sends HTTP to Nginx on port 80)
   - Always Use HTTPS: **ON**
   - Automatic HTTPS Rewrites: **ON**
   - Minimum TLS Version: **TLS 1.2**

3. **Firewall/Security:**
   - See `C:\Apps\shared\docs\cloudflare\CLOUDFLARE-FIREWALL-SETUP.md` for standard rules

### V13. Verify HTTPS Access

```powershell
# From the VPS (tests Nginx directly)
Invoke-WebRequest "http://localhost/api/v1/health" -Headers @{Host="cricscores.in"} -UseBasicParsing
# Expected: 200 OK

# From any machine (tests full Cloudflare → Nginx → Bun chain)
# curl https://cricscores.in/api/v1/health
# Expected: {"status":"ok","database":"connected"}
```

---

## Phase 4: Firewall

### V14. Configure Windows Firewall

```powershell
# Block direct access to CricApp Bun server from outside
# (all traffic must go through Nginx)
New-NetFirewallRule -DisplayName "Block CricApp Direct" `
  -Direction Inbound -Protocol TCP -LocalPort 3005 -Action Block

# Block PostgreSQL from outside (may already exist for other apps)
New-NetFirewallRule -DisplayName "Block PostgreSQL External" `
  -Direction Inbound -Protocol TCP -LocalPort 5432 -Action Block
```

> **Note:** Port 80 is already open for Nginx (serving 4 other sites). Port 443 is NOT needed on the VPS — Cloudflare terminates SSL at their edge and forwards HTTP to port 80. No changes needed for existing firewall rules.

---

## Phase 5: Database Backups

### V15. Create Backup Script

Create `C:\Apps\cricapp\scripts\backup-db.bat`:
```batch
@echo off
setlocal
set PGPASSWORD=<password>
set DB_USER=cricapp_user
set DB_NAME=cricapp
set BACKUP_DIR=C:\Apps\cricapp\backups
set PG_BIN="C:\Program Files\PostgreSQL\16\bin"

for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set TIMESTAMP=%datetime:~0,8%_%datetime:~8,4%
set BACKUP_FILE=%BACKUP_DIR%\cricapp_%TIMESTAMP%.dump

if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

%PG_BIN%\pg_dump.exe -h 127.0.0.1 -p 5432 -U %DB_USER% -F c -f "%BACKUP_FILE%" %DB_NAME%

:: Delete backups older than 7 days
forfiles /p "%BACKUP_DIR%" /s /m *.dump /d -7 /c "cmd /c del @path" 2>nul
endlocal
```

### V16. Schedule Daily Backup

```powershell
$action = New-ScheduledTaskAction -Execute "C:\Apps\cricapp\scripts\backup-db.bat"
$trigger = New-ScheduledTaskTrigger -Daily -At "03:00AM"
Register-ScheduledTask -TaskName "CricApp DB Backup" `
  -Action $action -Trigger $trigger -RunLevel Highest -Force
```

---

## Phase 6: Deployment Script

### V17. Create Automated Deploy Script

Create `C:\Apps\cricapp\scripts\deploy.ps1`:
```powershell
param([string]$Branch = "main")
$ErrorActionPreference = "Stop"
$AppDir = "C:\Apps\cricapp\current"

function Log($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] $msg"
    Add-Content "C:\Apps\cricapp\logs\deploy.log" "[$ts] $msg"
}

Log "=== Deploy starting (branch: $Branch) ==="

# Pull latest
Set-Location $AppDir
git fetch origin
git checkout $Branch
git pull origin $Branch

# Install deps
Log "Installing dependencies..."
bun install --frozen-lockfile

# Type check
Log "Running type check..."
bun run typecheck
if ($LASTEXITCODE -ne 0) { Log "ERROR: Type check failed"; exit 1 }

# Migrations
Log "Running migrations..."
bun run db:migrate
if ($LASTEXITCODE -ne 0) { Log "ERROR: Migration failed"; exit 1 }

# Restart service
Log "Restarting cricapp..."
pm2 restart cricapp
pm2 save

# Health check (30s timeout)
$ok = $false
for ($i = 0; $i -lt 10; $i++) {
    Start-Sleep 3
    try {
        $r = Invoke-WebRequest "http://localhost:3005/api/v1/health" -UseBasicParsing -TimeoutSec 5
        $j = $r.Content | ConvertFrom-Json
        if ($j.status -eq "ok") { $ok = $true; break }
    } catch { Log "Not ready (attempt $($i+1)/10)..." }
}

if ($ok) { Log "Deploy SUCCESS" } else { Log "ERROR: Health check failed"; exit 1 }
```

**Usage:** `powershell -ExecutionPolicy Bypass -File C:\Apps\cricapp\scripts\deploy.ps1`

---

## Phase 7: Monitoring

### V18. Add CricApp to VPS Health-Check Script

The VPS health-check script (`C:\Apps\shared\scripts\health-check.ps1`) runs every 5 minutes and auto-restarts crashed services. Add CricApp to its `$sites` array:

```powershell
# In health-check.ps1's $sites array, add:
@{ name = "cricapp"; url = "http://localhost:3005/api/v1/health"; pm2Name = "cricapp" }
```

### V19. External Uptime Monitor (UptimeRobot)

1. Create free account at https://uptimerobot.com
2. Add HTTP(S) monitor: `https://cricscores.in/api/v1/health`
3. Check interval: 5 minutes
4. Alert contacts: your email/Telegram

### V20. Log Monitoring Commands

```powershell
# Follow live PM2 logs
pm2 logs cricapp --lines 50

# View PM2 log files directly
Get-Content "C:\Apps\cricapp\logs\out.log" -Wait -Tail 50
Get-Content "C:\Apps\cricapp\logs\error.log" -Wait -Tail 50

# Check PM2 process status
pm2 describe cricapp

# Check Nginx access/error logs for cricscores.in
Get-Content "C:\Apps\nginx\logs\cricscores-access.log" -Tail 50
Get-Content "C:\Apps\nginx\logs\cricscores-error.log" -Tail 30
```

---

## Post-Deployment Verification Checklist

Run these after every deployment:

```powershell
# 1. PM2 process running
pm2 describe cricapp
# Should show: status = online

# 2. Nginx serving cricscores.in
Invoke-WebRequest "http://localhost/api/v1/health" -Headers @{Host="cricscores.in"} -UseBasicParsing
# Expected: 200 OK

# 3. Health endpoint via HTTPS (full chain: Cloudflare → Nginx → Bun)
# From any external machine:
# curl https://cricscores.in/api/v1/health
# Expected: {"status":"ok","database":"connected"}

# 4. HTTPS enforced (Cloudflare Always Use HTTPS)
# curl -I http://cricscores.in/api/v1/health
# Expected: 301 redirect to https://

# 5. WebSocket (manual test from local machine)
# Install wscat: npm install -g wscat
# wscat -c "wss://cricscores.in/ws"
# Type: {"type":"join_match","matchId":"test"}
# Expected: {"type":"error","message":"Match not found"}

# 6. Bun port NOT accessible from outside
# From another machine: telnet 103.118.16.189 3005 — should timeout

# 7. Check error logs
pm2 logs cricapp --err --lines 30
Get-Content "C:\Apps\nginx\logs\cricscores-error.log" -Tail 30
```

---

## Architecture Diagram

```
Friends' Android Phones
    |
    | HTTPS (443) + WSS (443)
    v
Cloudflare Edge (SSL termination, DDoS protection)
    |
    | HTTP (80)
    v
cricscores.in (DNS → 103.118.16.189)
    |
    v
[Nginx] (port 80, reverse proxy — also serves 4 other sites)
    |
    | HTTP (3005, loopback only)
    v
[Bun/ElysiaJS] (127.0.0.1:3005, managed by PM2)
    |
    v
[PostgreSQL] (127.0.0.1:5432)
```

---

## Quick Reference

| Action | Command |
|--------|---------|
| Deploy latest code | `powershell -File C:\Apps\cricapp\scripts\deploy.ps1` |
| Restart server | `pm2 restart cricapp` |
| Stop server | `pm2 stop cricapp` |
| Start server | `pm2 start cricapp` |
| View live logs | `pm2 logs cricapp --lines 50` |
| View errors only | `pm2 logs cricapp --err --lines 30` |
| Process details | `pm2 describe cricapp` |
| All PM2 processes | `pm2 ls` |
| Manual backup | `C:\Apps\cricapp\scripts\backup-db.bat` |
| Reload Nginx | `C:\Apps\nginx\nginx.exe -s reload` |
| Test Nginx config | `C:\Apps\nginx\nginx.exe -t` |
| Nginx CricApp logs | `Get-Content C:\Apps\nginx\logs\cricscores-access.log -Tail 50` |
| Save PM2 state | `pm2 save` |
