---
name: sync-test
description: "Test offline sync round-trip by running server sync tests and Flutter sync engine tests. Use when sync logic changes, user says 'test sync', 'check offline', or after modifying sync queue or persistence code."
disable-model-invocation: true
allowed-tools: Bash, Read
metadata:
  version: 1.0.0
---

# Sync Test

Run both server-side and client-side sync tests.

## Steps

1. Run server sync service tests:
   ```bash
   cd apps/server && bun test test/services/sync.service.test.ts
   ```

2. Run Flutter sync engine tests:
   ```bash
   cd apps/mobile && flutter test test/src/shared/data/sync/
   ```

3. Report results for both:
   - Server tests: pass/fail count, any failures with details
   - Flutter tests: pass/fail count, any failures with details
   - If either side fails, note which side and suggest investigation starting points

4. If `$ARGUMENTS` is provided, run only the specified subset (e.g., "server" or "mobile").
