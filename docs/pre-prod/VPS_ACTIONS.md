# Pre-Production: VPS Actions (Server Deployment)

These actions are performed on the VPS (`103.118.16.189`) running Windows Server. They set up the production server environment for friend testing.

**Domain:** `cricscores.in` → A record pointing to `103.118.16.189`

---

## Prerequisites (Manual — Before Claude Code Session on VPS)

- [ ] Point DNS A record for `cricscores.in` to `103.118.16.189` (TTL: 300s)
- [ ] Verify DNS propagation: `nslookup cricscores.in` returns VPS IP
- [ ] Ensure PostgreSQL 16 is installed and running as Windows Service
- [ ] Ensure Bun is installed (`bun --version`)
- [ ] Ensure Git is installed (`git --version`)
- [ ] Have `firebase-service-account.json` ready to copy to VPS

---

## Phase 1: Server Setup

### V1. Create Directory Structure

```
C:\cricapp\
├── server\          # Git clone of apps/server (or full repo)
├── uploads\         # User-uploaded images
├── backups\         # pg_dump files
├── logs\            # NSSM-captured stdout/stderr + deploy logs
└── scripts\         # deploy.ps1, backup-db.bat
```

### V2. Clone Repository and Install Dependencies

```powershell
cd C:\cricapp
git clone <repo-url> server   # Or copy apps/server/ content
cd server
bun install
```

### V3. Configure Production Environment

Create `C:\cricapp\server\.env`:
```dotenv
DATABASE_URL=postgresql://cricapp_user:<password>@127.0.0.1:5432/cricapp
FIREBASE_SERVICE_ACCOUNT_PATH=C:\cricapp\server\firebase-service-account.json
PORT=3000
CORS_ORIGIN=https://cricscores.in
NODE_ENV=production
LOG_LEVEL=info
UPLOADS_DIR=C:\cricapp\uploads
MAX_UPLOAD_SIZE_MB=5
SYNC_BATCH_SIZE=50
WS_HEARTBEAT_INTERVAL_MS=30000
```

Copy `firebase-service-account.json` to `C:\cricapp\server\`.

### V4. PostgreSQL Setup

```sql
-- Create dedicated user (not postgres superuser)
CREATE USER cricapp_user WITH PASSWORD '<strong_random_password>';
CREATE DATABASE cricapp;
GRANT ALL PRIVILEGES ON DATABASE cricapp TO cricapp_user;
```

Harden `postgresql.conf`:
```
listen_addresses = 'localhost'
```

Harden `pg_hba.conf` — only local connections:
```
host  all  all  127.0.0.1/32  scram-sha-256
```

### V5. Run Database Migrations and Seed

```powershell
cd C:\cricapp\server
bun run db:migrate
bun run db:seed
```

### V6. Verify Server Starts

```powershell
cd C:\cricapp\server
$env:NODE_ENV="production"; bun run start
# Check: http://localhost:3000/api/v1/health should return {"status":"ok","database":"connected"}
# Ctrl+C to stop
```

---

## Phase 2: Process Management (NSSM)

### V7. Install NSSM

Download from https://nssm.cc/download (64-bit). Extract to `C:\nssm\`.

```powershell
# Add to system PATH
[Environment]::SetEnvironmentVariable(
  "Path",
  $env:Path + ";C:\nssm\win64",
  [System.EnvironmentVariableTarget]::Machine
)
```

### V8. Register CricApp as Windows Service

```powershell
# Install service
nssm install cricapp "C:\Users\Administrator\.bun\bin\bun.exe"
nssm set cricapp AppDirectory "C:\cricapp\server"
nssm set cricapp AppParameters "run start"
nssm set cricapp Start SERVICE_AUTO_START

# Logging with rotation
nssm set cricapp AppStdout "C:\cricapp\logs\cricapp.out.log"
nssm set cricapp AppStderr "C:\cricapp\logs\cricapp.err.log"
nssm set cricapp AppRotateFiles 1
nssm set cricapp AppRotateBytes 10485760
nssm set cricapp AppTimestampLog 1

# Crash recovery — 3s restart delay
nssm set cricapp AppRestartDelay 3000

# Environment
nssm set cricapp AppEnvironmentExtra "NODE_ENV=production"

# Start
nssm start cricapp
```

### V9. Verify Service Running

```powershell
sc.exe query cricapp
# Should show STATE: RUNNING

Invoke-WebRequest -Uri "http://localhost:3000/api/v1/health" -UseBasicParsing
# Should return 200 OK with {"status":"ok","database":"connected"}
```

---

## Phase 3: Reverse Proxy + SSL (Caddy)

### V10. Install Caddy

Download Windows x64 binary from https://caddyserver.com/download. Place at `C:\caddy\caddy.exe`.

### V11. Create Caddyfile

Create `C:\caddy\Caddyfile`:
```
cricscores.in {
    reverse_proxy localhost:3000

    encode gzip

    header {
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        -Server
    }

    # Serve uploaded images directly
    handle /uploads/* {
        root * C:\cricapp
        file_server
    }
}
```

Caddy automatically:
- Obtains Let's Encrypt SSL certificate for `cricscores.in`
- Redirects HTTP → HTTPS
- Proxies WebSocket upgrade headers transparently
- Renews certificates before expiry

### V12. Validate and Start Caddy

```powershell
C:\caddy\caddy.exe validate --config C:\caddy\Caddyfile
C:\caddy\caddy.exe run --config C:\caddy\Caddyfile
# Verify HTTPS works, then Ctrl+C
```

### V13. Register Caddy as Windows Service

```powershell
nssm install caddy "C:\caddy\caddy.exe"
nssm set caddy AppDirectory "C:\caddy"
nssm set caddy AppParameters "run --config C:\caddy\Caddyfile"
nssm set caddy Start SERVICE_AUTO_START
nssm set caddy AppStdout "C:\cricapp\logs\caddy.out.log"
nssm set caddy AppStderr "C:\cricapp\logs\caddy.err.log"
nssm set caddy AppRotateFiles 1
nssm set caddy AppRotateBytes 10485760
nssm start caddy
```

---

## Phase 4: Firewall

### V14. Configure Windows Firewall

```powershell
# Allow HTTPS (Caddy)
New-NetFirewallRule -DisplayName "CricApp HTTPS" `
  -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow

# Allow HTTP (Caddy redirect + Let's Encrypt ACME challenge)
New-NetFirewallRule -DisplayName "CricApp HTTP" `
  -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow

# BLOCK direct access to Bun from outside
New-NetFirewallRule -DisplayName "Block Bun Direct" `
  -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Block

# BLOCK PostgreSQL from outside
New-NetFirewallRule -DisplayName "Block PostgreSQL External" `
  -Direction Inbound -Protocol TCP -LocalPort 5432 -Action Block
```

Also ensure VPS provider's security group / cloud firewall allows ports 80 and 443 inbound.

---

## Phase 5: Database Backups

### V15. Create Backup Script

Create `C:\cricapp\scripts\backup-db.bat`:
```batch
@echo off
setlocal
set PGPASSWORD=<password>
set DB_USER=cricapp_user
set DB_NAME=cricapp
set BACKUP_DIR=C:\cricapp\backups
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
$action = New-ScheduledTaskAction -Execute "C:\cricapp\scripts\backup-db.bat"
$trigger = New-ScheduledTaskTrigger -Daily -At "03:00AM"
Register-ScheduledTask -TaskName "CricApp DB Backup" `
  -Action $action -Trigger $trigger -RunLevel Highest -Force
```

---

## Phase 6: Deployment Script

### V17. Create Automated Deploy Script

Create `C:\cricapp\scripts\deploy.ps1`:
```powershell
param([string]$Branch = "main")
$ErrorActionPreference = "Stop"
$AppDir = "C:\cricapp\server"

function Log($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] $msg"
    Add-Content "C:\cricapp\logs\deploy.log" "[$ts] $msg"
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
nssm restart cricapp

# Health check (30s timeout)
$ok = $false
for ($i = 0; $i -lt 10; $i++) {
    Start-Sleep 3
    try {
        $r = Invoke-WebRequest "http://localhost:3000/api/v1/health" -UseBasicParsing -TimeoutSec 5
        $j = $r.Content | ConvertFrom-Json
        if ($j.status -eq "ok") { $ok = $true; break }
    } catch { Log "Not ready (attempt $($i+1)/10)..." }
}

if ($ok) { Log "Deploy SUCCESS" } else { Log "ERROR: Health check failed"; exit 1 }
```

**Usage:** `powershell -ExecutionPolicy Bypass -File C:\cricapp\scripts\deploy.ps1`

---

## Phase 7: Monitoring

### V18. External Uptime Monitor (UptimeRobot)

1. Create free account at https://uptimerobot.com
2. Add HTTP(S) monitor: `https://cricscores.in/api/v1/health`
3. Check interval: 5 minutes
4. Alert contacts: your email/Telegram

### V19. Log Monitoring Commands

```powershell
# Follow live logs
Get-Content "C:\cricapp\logs\cricapp.out.log" -Wait -Tail 50
Get-Content "C:\cricapp\logs\cricapp.err.log" -Wait -Tail 50

# Check service status
sc.exe query cricapp
sc.exe query caddy
```

---

## Post-Deployment Verification Checklist

Run these after every deployment:

```powershell
# 1. Services running
sc.exe query cricapp   # STATE: RUNNING
sc.exe query caddy     # STATE: RUNNING

# 2. Health endpoint via HTTPS
Invoke-WebRequest "https://cricscores.in/api/v1/health" -UseBasicParsing
# Expected: {"status":"ok","database":"connected"}

# 3. HTTP redirects to HTTPS
(Invoke-WebRequest "http://cricscores.in/api/v1/health" -MaximumRedirection 0 -ErrorAction SilentlyContinue).StatusCode
# Expected: 301

# 4. WebSocket (manual test from local machine)
# Install wscat: npm install -g wscat
# wscat -c "wss://cricscores.in/ws"
# Type: {"type":"join_match","matchId":"test"}
# Expected: {"type":"error","message":"Match not found"}

# 5. Bun port NOT accessible from outside
# From another machine: telnet 103.118.16.189 3000 — should timeout

# 6. Check error logs
Get-Content "C:\cricapp\logs\cricapp.err.log" -Tail 30
```

---

## Architecture Diagram

```
Friends' Android Phones
    |
    | HTTPS (443) + WSS (443)
    v
cricscores.in (DNS → 103.118.16.189)
    |
    v
[Caddy] (ports 80+443, auto-SSL)
    |
    | HTTP (3000, loopback only)
    v
[Bun/ElysiaJS] (127.0.0.1:3000, managed by NSSM)
    |
    v
[PostgreSQL] (127.0.0.1:5432)
```

---

## Quick Reference

| Action | Command |
|--------|---------|
| Deploy latest code | `powershell -File C:\cricapp\scripts\deploy.ps1` |
| Restart server | `nssm restart cricapp` |
| Stop server | `nssm stop cricapp` |
| View live logs | `Get-Content C:\cricapp\logs\cricapp.out.log -Wait -Tail 50` |
| View errors | `Get-Content C:\cricapp\logs\cricapp.err.log -Tail 30` |
| Manual backup | `C:\cricapp\scripts\backup-db.bat` |
| Restart Caddy | `nssm restart caddy` |
| Check all services | `sc.exe query cricapp; sc.exe query caddy` |
