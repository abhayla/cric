# VPS Session Prompt

> **Status (2026-02-24):** Initial deployment COMPLETE. All 11 phases done. Server live at `https://cricscores.in`. Use this prompt for re-deployments or maintenance sessions.

Copy-paste the text below (between the `---` markers) into a new Claude Code session running on the VPS.

---

## Context

You are maintaining the **CricScores** server — a cricket scoring app backend (Bun + ElysiaJS + PostgreSQL + WebSockets) — on this VPS. Initial deployment was completed on 2026-02-24.

**VPS:** Windows Server 2022, IP `103.118.16.189`
**Domain:** `cricscores.in`
**Repo:** `https://github.com/abhayla/cric.git` (server code is in `apps/server/`)
**Firebase project:** `cricapp-7403d` (Phone OTP auth)

## What to do

Execute the full deployment by following the runbook at `docs/pre-prod/VPS_DEPLOYMENT_RUNBOOK.md` in the cloned repo. Work through all 11 phases sequentially:

1. **Directory structure & clone** — Create `C:\Apps\cricscores\` tree, clone the repo into `current/`, install server deps
2. **PostgreSQL** — Create `cricscores` database and `cricscores_user` (generate a strong random password)
3. **Server config** — Create `.env` in `apps/server/`, place `firebase-service-account.json` (ask me for it), run migrations + seed, verify server starts
4. **PM2** — Create `ecosystem.config.js`, start with PM2, `pm2 save`
5. **Nginx** — Create `C:\Apps\nginx\conf\sites\cricscores.conf`, test and reload Nginx
6. **Cloudflare** — Set up DNS A records (@ and www, proxied), SSL Flexible mode, Always Use HTTPS, WebSocket support. Ask me for the Cloudflare API token and Zone ID.
7. **Firebase production setup** — Add prod Android app (`in.cricscores.app`) to Firebase project `cricapp-7403d`. This involves: adding the app in Firebase Console, downloading prod `google-services.json`, generating a release keystore, adding SHA fingerprints, and verifying Phone Auth is enabled with test numbers. Some steps require Firebase Console access — ask me to do those and provide the outputs.
8. **Firewall** — Block ports 3005 and 5432 from outside
9. **DB backups** — Create backup script and daily scheduled task
10. **Deploy script** — Create `deploy.ps1` for future deployments
11. **Monitoring** — Add CricScores to the VPS health-check script

## Credentials you'll need (ask me for each)

| Item | When |
|------|------|
| PostgreSQL superuser password | Phase 2 |
| `firebase-service-account.json` file | Phase 3 |
| Cloudflare API Token (Zone:DNS:Edit, Zone:SSL:Edit, Zone:Settings:Edit perms) | Phase 6 |
| Cloudflare Zone ID for `cricscores.in` | Phase 6 |
| Firebase Console access (for adding prod app + SHA fingerprints) | Phase 7 |

## Important notes

- **Ask me** before proceeding whenever you need credentials or files listed above.
- Reference the existing VPS conventions at `C:\Apps\shared\docs\` — other apps (bestdemataccount, firekaro, ipodhan, algochanakya) already run here with Nginx + PM2 + Cloudflare.
- Port 3005 is allocated for CricScores (ports 3001-3004 and 8000 are taken by other apps).
- The server-side `firebase-admin` SDK uses a project-level service account — it validates tokens from BOTH dev (`com.cricapp.cricapp`) and prod (`in.cricscores.app`) Android apps automatically.
- After all phases, run the full post-deployment verification checklist from the runbook.
- If any phase fails, stop and tell me what went wrong — don't skip steps.

## VPS Gotchas (from initial deployment)

- **Use `127.0.0.1` not `localhost`** — This VPS has an IPv4/IPv6 DNS issue where `localhost` doesn't resolve. All health checks, curl commands, and connection strings must use `127.0.0.1`.
- **PM2 args: use `run src/index.ts`** — Do NOT use `run start` in ecosystem.config.js. It causes a double-bun spawn where the inner process can't bind the port.
- **Nginx reload may fail** — If `nginx.exe -s reload` fails with "Access is denied", force-kill all Nginx processes (`taskkill /IM nginx.exe /F`) and start fresh. Verify other sites still work.
- **db:migrate non-zero exit** — Drizzle's `db:migrate` returns non-zero when all migrations are already applied. Treat as WARNING, not ERROR.
- **Always `pm2 save` after changes** — And add `Start-Sleep 5` between `pm2 restart` and health checks to let the process bind.

## Key reference docs in the repo

- `docs/pre-prod/VPS_DEPLOYMENT_RUNBOOK.md` — The step-by-step runbook (primary reference)
- `docs/pre-prod/VPS_ACTIONS.md` — Original VPS deployment plan with architecture diagram
- `docs/pre-prod/ANYWHERE_ACTIONS.md` — Client-side pre-prod changes (not for VPS session)
- `docs/planning/API.md` — API endpoint specs
- `docs/planning/DATABASE.md` — PostgreSQL schema (26 tables)
- `apps/server/CLAUDE.md` — Server architecture and conventions
- `apps/server/.env.example` — Env var reference

---
