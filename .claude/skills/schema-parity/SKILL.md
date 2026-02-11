---
name: schema-parity
description: Compare Drift (Flutter) tables against Drizzle (server) schema. Read-only parity check with structured diff report.
disable-model-invocation: true
allowed-tools: Read, Glob, Grep
---

# Schema Parity

Compare Drift (Flutter SQLite) tables against Drizzle (PostgreSQL) schema for cross-platform parity.

## Steps

1. Find all Drizzle schema files:
   ```
   Glob: apps/server/src/db/schema/*.ts
   ```

2. Find all Drift table files:
   ```
   Glob: apps/mobile/lib/src/shared/data/database/tables/*.dart
   ```

3. Read each schema file and extract:
   - Table name
   - Column names, types, nullability, defaults
   - Indexes and constraints

4. Read each Drift table file and extract:
   - Table name
   - Column names, types, nullability, defaults

5. Cross-reference and produce a structured diff report:

   **Matched Tables:**
   | Table | Drizzle Columns | Drift Columns | Status |
   |-------|----------------|---------------|--------|

   **Column Mismatches:**
   | Table | Column | Drizzle Type | Drift Type | Issue |
   |-------|--------|-------------|------------|-------|

   **Missing in Drift (server-only):**
   - List tables that exist in Drizzle but not in Drift (expected for tournament tables per Q11)

   **Missing in Drizzle (local-only):**
   - List tables that exist in Drift but not in Drizzle (expected for sync_queue, local_preferences)

   **Type Mapping Validation:**
   - Verify PostgreSQL → SQLite type mappings are correct (uuid→text, timestamp→dateTime, jsonb→text, etc.)

6. Summarize: total tables matched, mismatches found, action items.

**Note:** This skill is read-only. It never modifies schema files.
