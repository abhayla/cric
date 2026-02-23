---
name: backup
description: "Guide pg_dump backup setup, retention policy, and restore testing. Use when user says 'backup', 'pg_dump', 'database backup', or 'restore test'."
disable-model-invocation: true
allowed-tools: Bash, Read, Write, Edit
metadata:
  version: 1.0.0
---

# Backup — Database Backup Setup

Guide PostgreSQL backup configuration with pg_dump, retention, and restore testing.

> **Platform note:** CricScores deploys on Windows Server. The examples below use Linux/bash syntax as reference. On Windows, replace cron with Task Scheduler, use PowerShell scripts (`.ps1`) instead of `.sh`, and adjust paths (e.g., `C:\backups\cricscores\` instead of `/var/backups/cricscores/`).

## Arguments

`$ARGUMENTS` can be: `setup`, `run`, `restore-test`, or `status`.

## Steps — Setup (`setup`)

1. **Create backup directory:**
   ```bash
   mkdir -p /var/backups/cricscores
   ```

2. **Create backup script** at `/opt/cricscores/backup.sh`:
   ```bash
   #!/bin/bash
   TIMESTAMP=$(date +%Y%m%d_%H%M%S)
   BACKUP_DIR="/var/backups/cricscores"
   DB_NAME="cricscores"

   # Dump with compression
   pg_dump -Fc "$DB_NAME" > "$BACKUP_DIR/cricapp_$TIMESTAMP.dump"

   # Retain last 7 days (delete older backups)
   find "$BACKUP_DIR" -name "*.dump" -mtime +7 -delete

   echo "Backup complete: cricapp_$TIMESTAMP.dump"
   ```

3. **Set up cron job** (daily at 2 AM):
   ```bash
   crontab -e
   # Add: 0 2 * * * /opt/cricscores/backup.sh >> /var/log/cricscores-backup.log 2>&1
   ```

4. **Verify permissions:**
   ```bash
   chmod +x /opt/cricscores/backup.sh
   ```

## Steps — Manual Run (`run`)

1. Run backup manually:
   ```bash
   pg_dump -Fc cricscores > /var/backups/cricscores/cricapp_manual_$(date +%Y%m%d).dump
   ```

2. Verify backup file size and timestamp.

## Steps — Restore Test (`restore-test`)

1. **Create test database:**
   ```bash
   psql -c "CREATE DATABASE cricapp_restore_test;"
   ```

2. **Restore from latest backup:**
   ```bash
   LATEST=$(ls -t /var/backups/cricscores/*.dump | head -1)
   pg_restore -d cricapp_restore_test "$LATEST"
   ```

3. **Verify table counts:**
   ```bash
   psql cricapp_restore_test -c "SELECT schemaname, tablename FROM pg_tables WHERE schemaname = 'public';"
   ```

4. **Drop test database:**
   ```bash
   psql -c "DROP DATABASE cricapp_restore_test;"
   ```

5. Report: backup size, tables restored, restore duration.

## Steps — Status Check (`status`)

1. List backups: `ls -lh /var/backups/cricscores/`
2. Check disk usage: `du -sh /var/backups/cricscores/`
3. Check cron job: `crontab -l | grep cricscores`
4. Check last backup log: `tail -5 /var/log/cricscores-backup.log`
