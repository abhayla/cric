---
name: db-migrate
description: Generate and apply Drizzle database migrations after schema changes.
disable-model-invocation: true
allowed-tools: Bash, Read
---

# DB Migrate

Generate and apply Drizzle database migrations.

## Steps

1. Generate migration files from schema changes:
   ```bash
   cd apps/server && bunx drizzle-kit generate
   ```

2. Review the generated migration SQL by reading the newest file in `apps/server/src/db/migrations/`.

3. Apply the migration:
   ```bash
   cd apps/server && bunx drizzle-kit migrate
   ```

4. Report results:
   - Migration file name and path
   - Summary of SQL operations (CREATE TABLE, ALTER TABLE, etc.)
   - Any errors during generation or application

5. Reminder: After applying migrations, test with seed data to verify the schema works correctly:
   ```bash
   cd apps/server && bun run src/db/seed/master_data.ts
   ```
