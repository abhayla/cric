---
name: server-test
description: "Run Bun server test suite (all tests or a specific file). Use when server code changes, user says 'test server', 'run server tests', or after modifying files in apps/server/src/."
disable-model-invocation: true
allowed-tools: Bash, Read
metadata:
  version: 1.0.0
---

# Server Test

Run the Bun server test suite.

## Steps

1. If `$ARGUMENTS` is provided, run the specific test file:
   ```bash
   cd apps/server && bun test $ARGUMENTS
   ```

2. If no arguments, run all server tests:
   ```bash
   cd apps/server && bun test
   ```

3. Report results:
   - Total tests run, passed, failed, skipped
   - For failures: test name, expected vs actual, file path with line number
   - If all pass, confirm with a one-line summary

4. If tests fail, read the failing test file to understand what's being tested and suggest which source files likely need fixes.
