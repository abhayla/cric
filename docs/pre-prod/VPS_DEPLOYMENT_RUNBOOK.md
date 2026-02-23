# VPS Deployment Runbook — CricScores Server

This is the complete, step-by-step runbook for deploying CricScores server to the VPS. Designed to be executed by a Claude Code session running directly on the VPS.

**VPS:** `103.118.16.189` (Windows Server 2022, hostname: `544934-ABHAYVPS`)
**Domain:** `cricscores.in`
**Repo:** `https://github.com/abhayla/cric.git`

---

## Pre-Flight Checks

Before starting, verify these are available on the VPS:

```powershell
bun --version          # Bun runtime
git --version          # Git
pm2 --version          # Process manager
node --version         # Node (needed by PM2)
psql --version         # PostgreSQL client
C:\Apps\nginx\nginx.exe -t   # Nginx
```

PostgreSQL 16 should be running as a Windows Service on `127.0.0.1:5432`.

## Credentials & Files Needed (ask user for these)

| Item | Purpose | When needed |
|------|---------|-------------|
| PostgreSQL superuser password | Create `cricscores` database and user | Phase 2 |
| `firebase-service-account.json` | Server-side Firebase Admin SDK auth | Phase 3 |
| Cloudflare API Token | DNS + SSL setup via API (needs Zone:DNS:Edit, Zone:SSL:Edit, Zone:Settings:Edit) | Phase 6 |
| Cloudflare Zone ID for `cricscores.in` | Target zone for API calls | Phase 6 |

---

## Phase 1: Directory Structure & Clone

### 1.1 Create app directories

```powershell
mkdir C:\Apps\cricscores\current, C:\Apps\cricscores\uploads, C:\Apps\cricscores\backups, C:\Apps\cricscores\logs, C:\Apps\cricscores\scripts
```

### 1.2 Clone repository

```powershell
cd C:\Apps\cricscores
git clone https://github.com/abhayla/cric.git current
```

### 1.3 Install server dependencies

```powershell
cd C:\Apps\cricscores\current\apps\server
bun install
```

---

## Phase 2: PostgreSQL Setup

### 2.1 Create database and user

Connect as postgres superuser:

```sql
CREATE USER cricscores_user WITH PASSWORD '<GENERATE_STRONG_PASSWORD>';
CREATE DATABASE cricscores OWNER cricscores_user;
GRANT ALL PRIVILEGES ON DATABASE cricscores TO cricscores_user;
\c cricscores
GRANT ALL ON SCHEMA public TO cricscores_user;
```

### 2.2 Verify connection

```powershell
psql -h 127.0.0.1 -p 5432 -U cricscores_user -d cricscores -c "SELECT 1;"
```

---

## Phase 3: Server Configuration

### 3.1 Create production .env

Create `C:\Apps\cricscores\current\apps\server\.env`:

```dotenv
DATABASE_URL=postgresql://cricscores_user:<PASSWORD>@127.0.0.1:5432/cricscores
FIREBASE_SERVICE_ACCOUNT_PATH=C:\Apps\cricscores\current\apps\server\firebase-service-account.json
PORT=3005
CORS_ORIGIN=https://cricscores.in
NODE_ENV=production
LOG_LEVEL=info
UPLOADS_DIR=C:\Apps\cricscores\uploads
MAX_UPLOAD_SIZE_MB=5
SYNC_BATCH_SIZE=50
WS_HEARTBEAT_INTERVAL_MS=30000
```

### 3.2 Place Firebase service account

Copy `firebase-service-account.json` to `C:\Apps\cricscores\current\apps\server\`.

> **User must provide this file.** It's from Firebase Console > Project Settings > Service Accounts > Generate new private key. Project: `cricapp-7403d`.

### 3.3 Run migrations and seed

```powershell
cd C:\Apps\cricscores\current\apps\server
bun run db:migrate
bun run db:seed
```

### 3.4 Verify server starts

```powershell
cd C:\Apps\cricscores\current\apps\server
$env:NODE_ENV="production"; bun run start
# Should print: CricScores server running at localhost:3005
# Test: curl http://localhost:3005/api/v1/health
# Expected: {"status":"ok","database":"connected"}
# Ctrl+C to stop
```

---

## Phase 4: PM2 Process Management

### 4.1 Create ecosystem config

Create `C:\Apps\cricscores\current\ecosystem.config.js`:

```javascript
module.exports = {
  apps: [{
    name: 'cricscores',
    script: 'C:\\Users\\Administrator\\.bun\\bin\\bun.exe',
    args: 'run start',
    cwd: 'C:\\Apps\\cricscores\\current\\apps\\server',
    interpreter: 'none',
    instances: 1,
    exec_mode: 'fork',
    max_memory_restart: '500M',
    env: {
      NODE_ENV: 'production',
      PORT: 3005
    },
    error_file: 'C:\\Apps\\cricscores\\logs\\error.log',
    out_file: 'C:\\Apps\\cricscores\\logs\\out.log',
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

### 4.2 Start with PM2

```powershell
cd C:\Apps\cricscores\current
pm2 start ecosystem.config.js
pm2 save
```

### 4.3 Verify

```powershell
pm2 describe cricscores
# status = online, restarts = 0
Invoke-WebRequest -Uri "http://localhost:3005/api/v1/health" -UseBasicParsing
```

---

## Phase 5: Nginx Reverse Proxy

### 5.1 Create site config

Create `C:\Apps\nginx\conf\sites\cricscores.conf`:

```nginx
# CricScores - Cricket Scoring API + WebSocket
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
        alias C:/Apps/cricscores/uploads/;
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

### 5.2 Verify nginx config includes sites directory

Check `C:\Apps\nginx\conf\nginx.conf` has this line in the `http {}` block:

```nginx
include sites/*.conf;
```

### 5.3 Test and reload

```powershell
C:\Apps\nginx\nginx.exe -t
C:\Apps\nginx\nginx.exe -s reload
```

### 5.4 Verify via Nginx

```powershell
Invoke-WebRequest "http://localhost/api/v1/health" -Headers @{Host="cricscores.in"} -UseBasicParsing
```

---

## Phase 6: Cloudflare DNS & SSL

### 6.1 Cloudflare API setup

Use Cloudflare API with an API token that has Zone:DNS:Edit and Zone:SSL:Edit permissions for `cricscores.in`.

**User must provide:**
- Cloudflare API Token (or Global API Key + email)
- Zone ID for `cricscores.in` (from Cloudflare dashboard > Overview > right sidebar)

### 6.2 Create DNS A records

```powershell
# Get Zone ID first (if not provided)
# curl -X GET "https://api.cloudflare.com/client/v4/zones?name=cricscores.in" -H "Authorization: Bearer <TOKEN>"

# Create @ record (proxied)
curl -X POST "https://api.cloudflare.com/client/v4/zones/<ZONE_ID>/dns_records" `
  -H "Authorization: Bearer <TOKEN>" `
  -H "Content-Type: application/json" `
  --data '{"type":"A","name":"cricscores.in","content":"103.118.16.189","ttl":1,"proxied":true}'

# Create www record (proxied)
curl -X POST "https://api.cloudflare.com/client/v4/zones/<ZONE_ID>/dns_records" `
  -H "Authorization: Bearer <TOKEN>" `
  --data '{"type":"A","name":"www","content":"103.118.16.189","ttl":1,"proxied":true}'
```

### 6.3 Configure SSL settings

```powershell
# Set SSL mode to Flexible (Cloudflare terminates HTTPS, sends HTTP to origin)
curl -X PATCH "https://api.cloudflare.com/client/v4/zones/<ZONE_ID>/settings/ssl" `
  -H "Authorization: Bearer <TOKEN>" `
  --data '{"value":"flexible"}'

# Enable Always Use HTTPS
curl -X PATCH "https://api.cloudflare.com/client/v4/zones/<ZONE_ID>/settings/always_use_https" `
  -H "Authorization: Bearer <TOKEN>" `
  --data '{"value":"on"}'

# Enable Automatic HTTPS Rewrites
curl -X PATCH "https://api.cloudflare.com/client/v4/zones/<ZONE_ID>/settings/automatic_https_rewrites" `
  -H "Authorization: Bearer <TOKEN>" `
  --data '{"value":"on"}'

# Set minimum TLS version
curl -X PATCH "https://api.cloudflare.com/client/v4/zones/<ZONE_ID>/settings/min_tls_version" `
  -H "Authorization: Bearer <TOKEN>" `
  --data '{"value":"1.2"}'
```

### 6.4 Enable WebSocket support

```powershell
curl -X PATCH "https://api.cloudflare.com/client/v4/zones/<ZONE_ID>/settings/websockets" `
  -H "Authorization: Bearer <TOKEN>" `
  --data '{"value":"on"}'
```

### 6.5 Verify DNS propagation

```powershell
nslookup cricscores.in
# Should return Cloudflare edge IPs (not 103.118.16.189 — that's expected with Proxied mode)
```

---

## Phase 7: Firebase Production Setup

Firebase project `cricapp-7403d` currently has only the dev Android app (`com.cricapp.cricapp`). Production requires adding the prod app (`in.cricscores.app`) and generating a release keystore.

### 7.1 Add prod Android app to Firebase project

This is done via Firebase CLI or Firebase Console. Use the Firebase Management REST API from the VPS:

```powershell
# Get a Google OAuth access token using the service account
# (firebase-service-account.json was already placed in Phase 3)

# Option A: Use Firebase Console (manual — user does this in browser)
# 1. Go to https://console.firebase.google.com/project/cricapp-7403d/settings/general
# 2. Click "Add app" > Android
# 3. Package name: in.cricscores.app
# 4. App nickname: CricScores (Prod)
# 5. Download google-services.json
# 6. Place in repo: apps/mobile/android/app/src/prod/google-services.json

# Option B: Use Firebase CLI (if installed on VPS)
# firebase apps:create android --project cricapp-7403d --package-name in.cricscores.app
```

> **User action required:** Download the prod `google-services.json` from Firebase Console after adding the app, and place it at `apps/mobile/android/app/src/prod/google-services.json` on the **dev machine** (not VPS).

### 7.2 Generate release keystore (on dev machine or VPS)

```powershell
# Generate keystore for production signing
keytool -genkey -v -keystore cricscores-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias cricscores
# Store in a SAFE location — losing this means you can't update the app on Play Store

# Extract SHA-1 and SHA-256 fingerprints
keytool -list -v -keystore cricscores-release.jks -alias cricscores
```

### 7.3 Add SHA fingerprints to Firebase

Add both SHA-1 and SHA-256 fingerprints to the prod Android app in Firebase Console:

1. Go to Firebase Console > Project Settings > Your Apps
2. Select the `in.cricscores.app` Android app
3. Click "Add fingerprint"
4. Add SHA-1 fingerprint (for Phone Auth)
5. Add SHA-256 fingerprint (for App Links / safety)

Also add the **debug keystore** SHA-1 if you want to test prod flavor on emulator:
```powershell
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android
```

### 7.4 Enable Phone Auth in Firebase

Verify Phone Authentication is enabled (should already be from dev setup):

1. Firebase Console > Authentication > Sign-in method
2. Phone provider: **Enabled**
3. Test phone numbers (for friend testing without real SMS costs):
   - `+919999999999` → OTP: `123456` (scorer)
   - `+919999999998` → OTP: `123456` (viewer)

### 7.5 Create key.properties (on dev machine)

Create `apps/mobile/android/key.properties` (gitignored):

```properties
storePassword=<KEYSTORE_PASSWORD>
keyPassword=<KEY_PASSWORD>
keyAlias=cricscores
storeFile=<ABSOLUTE_PATH_TO>/cricscores-release.jks
```

### 7.6 Server-side Firebase Admin

The server uses `firebase-admin` SDK with a service account JSON. This is **project-level** (not app-level), so the same `firebase-service-account.json` from project `cricapp-7403d` authenticates tokens from BOTH dev (`com.cricapp.cricapp`) and prod (`in.cricscores.app`) apps — no server changes needed.

### 7.7 Verify Firebase auth works end-to-end

After the prod app is added to Firebase:

```
1. Build prod APK: flutter build apk --flavor prod --release --dart-define=FLAVOR=prod
2. Install on device
3. Login with test phone number +919999999999 / OTP 123456
4. Server should validate the Firebase ID token and return 200
```

---

## Phase 8: Windows Firewall

> Phases 8-11 below are server infrastructure (VPS only).

```powershell
# Block direct access to Bun server from outside
New-NetFirewallRule -DisplayName "Block CricScores Direct" -Direction Inbound -Protocol TCP -LocalPort 3005 -Action Block

# Block PostgreSQL from outside (may already exist)
New-NetFirewallRule -DisplayName "Block PostgreSQL External" -Direction Inbound -Protocol TCP -LocalPort 5432 -Action Block
```

---

## Phase 9: Database Backups

### 8.1 Create backup script

Create `C:\Apps\cricscores\scripts\backup-db.bat`:

```batch
@echo off
setlocal
set PGPASSWORD=<PASSWORD>
set DB_USER=cricscores_user
set DB_NAME=cricscores
set BACKUP_DIR=C:\Apps\cricscores\backups
set PG_BIN="C:\Program Files\PostgreSQL\16\bin"

for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set TIMESTAMP=%datetime:~0,8%_%datetime:~8,4%
set BACKUP_FILE=%BACKUP_DIR%\cricscores_%TIMESTAMP%.dump

if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

%PG_BIN%\pg_dump.exe -h 127.0.0.1 -p 5432 -U %DB_USER% -F c -f "%BACKUP_FILE%" %DB_NAME%

:: Delete backups older than 7 days
forfiles /p "%BACKUP_DIR%" /s /m *.dump /d -7 /c "cmd /c del @path" 2>nul
endlocal
```

### 8.2 Schedule daily backup

```powershell
$action = New-ScheduledTaskAction -Execute "C:\Apps\cricscores\scripts\backup-db.bat"
$trigger = New-ScheduledTaskTrigger -Daily -At "03:00AM"
Register-ScheduledTask -TaskName "CricScores DB Backup" -Action $action -Trigger $trigger -RunLevel Highest -Force
```

---

## Phase 10: Deploy Script

Create `C:\Apps\cricscores\scripts\deploy.ps1`:

```powershell
param([string]$Branch = "main")
$ErrorActionPreference = "Stop"
$AppDir = "C:\Apps\cricscores\current\apps\server"
$RepoDir = "C:\Apps\cricscores\current"

function Log($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] $msg"
    Add-Content "C:\Apps\cricscores\logs\deploy.log" "[$ts] $msg"
}

Log "=== Deploy starting (branch: $Branch) ==="

Set-Location $RepoDir
git fetch origin
git checkout $Branch
git pull origin $Branch

Set-Location $AppDir
Log "Installing dependencies..."
bun install --frozen-lockfile

Log "Running type check..."
bun run typecheck
if ($LASTEXITCODE -ne 0) { Log "ERROR: Type check failed"; exit 1 }

Log "Running migrations..."
bun run db:migrate
if ($LASTEXITCODE -ne 0) { Log "ERROR: Migration failed"; exit 1 }

Log "Restarting cricscores..."
pm2 restart cricscores
pm2 save

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

---

## Phase 11: Monitoring

### 10.1 Add to VPS health-check script

In `C:\Apps\shared\scripts\health-check.ps1`, add to the `$sites` array:

```powershell
@{ name = "cricscores"; url = "http://localhost:3005/api/v1/health"; pm2Name = "cricscores" }
```

---

## Post-Deployment Verification Checklist

```powershell
# 1. PM2 process online
pm2 describe cricscores

# 2. Health via localhost
Invoke-WebRequest "http://localhost:3005/api/v1/health" -UseBasicParsing

# 3. Health via Nginx
Invoke-WebRequest "http://localhost/api/v1/health" -Headers @{Host="cricscores.in"} -UseBasicParsing

# 4. Health via HTTPS (full chain: Cloudflare -> Nginx -> Bun)
curl https://cricscores.in/api/v1/health

# 5. WebSocket test
# wscat -c "wss://cricscores.in/ws"
# Send: {"type":"join_match","matchId":"test"}
# Expect: {"type":"error","message":"Match not found"}

# 6. Port 3005 NOT accessible from outside
# From another machine: telnet 103.118.16.189 3005 — should timeout

# 7. Error logs clean
pm2 logs cricscores --err --lines 30
```

---

## Architecture

```
Friends' Android Phones
    |
    | HTTPS (443) + WSS (443)
    v
Cloudflare Edge (SSL termination, DDoS protection, WebSocket proxy)
    |
    | HTTP (80)
    v
[Nginx] port 80 on 103.118.16.189
    |
    | HTTP (3005, loopback only)
    v
[Bun/ElysiaJS] 127.0.0.1:3005 (PM2 managed)
    |
    v
[PostgreSQL] 127.0.0.1:5432
```

---

## Quick Reference

| Action | Command |
|--------|---------|
| Deploy | `powershell -File C:\Apps\cricscores\scripts\deploy.ps1` |
| Restart | `pm2 restart cricscores` |
| Stop | `pm2 stop cricscores` |
| Logs | `pm2 logs cricscores --lines 50` |
| Errors | `pm2 logs cricscores --err --lines 30` |
| Status | `pm2 describe cricscores` |
| All PM2 | `pm2 ls` |
| Backup | `C:\Apps\cricscores\scripts\backup-db.bat` |
| Nginx test | `C:\Apps\nginx\nginx.exe -t` |
| Nginx reload | `C:\Apps\nginx\nginx.exe -s reload` |
| Save PM2 | `pm2 save` |
