---
name: score-test
description: "Run the scoring engine test suite (delivery processing, strike rotation, extras, wickets, undo logic). Use when scoring code changes, user says 'test scoring', 'run score tests', or after modifying files in features/scoring/."
disable-model-invocation: true
allowed-tools: Bash, Read
metadata:
  version: 1.0.0
---

# Score Test

Run the scoring engine test suite.

## Steps

1. If `$ARGUMENTS` is provided, run the specific test file:
   ```bash
   cd apps/mobile && flutter test test/src/features/scoring/$ARGUMENTS
   ```

2. If no arguments, run the full scoring test suite:
   ```bash
   cd apps/mobile && flutter test test/src/features/scoring/
   ```

3. Report results:
   - Total tests run, passed, failed, skipped
   - For failures: test name, expected vs actual, file path with line number
   - If all pass, confirm with a one-line summary

4. If tests fail, read the failing test file to understand what's being tested and suggest which source files likely need fixes.
