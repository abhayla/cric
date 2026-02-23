---
name: deploy
description: "Guide server deployment with PM2, Nginx reverse proxy, Cloudflare DNS, and health checks. Use when user says 'deploy', 'set up server', 'configure nginx', or 'pm2 setup'."
disable-model-invocation: true
allowed-tools: Bash, Read, Write, Edit, Glob
metadata:
  version: 1.0.0
---

# Deploy — Server Deployment Workflow

Guide Bun server deployment to a VPS (Windows Server).

## Arguments

`$ARGUMENTS` can be: `setup` (first-time), `update` (redeploy), or `status` (health check).

## Steps — First-Time Setup (`setup`)

1. **Verify prerequisites:**
   ```bash
   node --version   # Node.js for PM2
   bun --version    # Bun runtime
   pm2 --version    # PM2 process manager
   ```

2. **Set up environment:**
   - Copy `.env.example` to `.env` on the server
   - Verify PostgreSQL connection string
   - Verify Firebase service account key path

3. **Run database migrations:**
   ```bash
   cd apps/server && bunx drizzle-kit migrate
   ```

4. **Seed master data:**
   ```bash
   cd apps/server && bun run src/db/seed/master_data.ts
   ```

5. **Start with PM2:**
   ```bash
   cd apps/server && pm2 start --interpreter bun src/index.ts --name cricscores-api
   pm2 save
   pm2 startup
   ```

6. **Configure Nginx** — See [references/nginx-config.md](references/nginx-config.md) for reverse proxy template with WebSocket support.

7. **Configure Cloudflare DNS:**
   - A record → server IP
   - Proxy status: Proxied (orange cloud)
   - SSL/TLS: Full (strict)

8. **Verify health:**
   ```bash
   curl https://api.yourdomain.com/health
   ```

## Steps — Redeploy (`update`)

1. Pull latest code: `git pull origin main`
2. Install dependencies: `cd apps/server && bun install`
3. Run migrations: `cd apps/server && bunx drizzle-kit migrate`
4. Restart PM2: `pm2 restart cricscores-api`
5. Verify health: `curl https://api.yourdomain.com/health`

## Steps — Health Check (`status`)

1. Check PM2 process: `pm2 status cricscores-api`
2. Check PM2 logs: `pm2 logs cricscores-api --lines 50`
3. Check endpoint health: `curl https://api.yourdomain.com/health`
4. Check database connection via API health endpoint
