---
name: drift-migrate
description: Manage Drift schema version bumps and scaffold migration code. Default read-only; only writes with "apply" argument.
disable-model-invocation: true
allowed-tools: Read, Write, Bash, Glob
---

# Drift Migrate

Manage Drift (Flutter SQLite) schema version bumps and migration scaffolding.

## Steps

1. Find the Drift database file:
   ```
   Glob: apps/mobile/lib/src/shared/data/database/app_database.dart
   ```

2. Read the database file and extract:
   - Current `schemaVersion` value
   - Existing migration steps in `onUpgrade`

3. Find all Drift table files and check for recent changes:
   ```
   Glob: apps/mobile/lib/src/shared/data/database/tables/*.dart
   ```

4. Identify what changed since the last migration:
   - New tables added
   - Columns added/removed/modified
   - Type changes

5. Scaffold the migration code:
   ```dart
   // Migration from version N to N+1
   // Changes: <description of changes>
   onUpgrade: (m, from, to) async {
     // Existing migrations...
     if (from < <N+1>) {
       // <generated migration SQL>
     }
   }
   ```

6. Present the scaffolded migration to the user.

7. **Safe mode (default):** Only display the scaffold. Do NOT write any files.

8. **Apply mode:** If `$ARGUMENTS` contains "apply":
   - Update `schemaVersion` to N+1
   - Insert the migration code into `onUpgrade`
   - Run build_runner to regenerate:
     ```bash
     cd apps/mobile && dart run build_runner build --delete-conflicting-outputs
     ```
   - Report success or errors
