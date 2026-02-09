---
name: sync-test
description: Test offline sync round-trip by running server sync tests and Flutter sync tests.
disable-model-invocation: true
allowed-tools: Bash, Read
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
