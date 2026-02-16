---
name: debug-log
description: "Create or update a debug iteration log in docs/debug/. Use when debugging a persistent issue, user says 'track this bug', 'debug log', or iteration count exceeds 3 on same issue. Tracks hypothesis, fix, result per iteration."
disable-model-invocation: true
allowed-tools: Read, Write, Glob
metadata:
  version: 1.0.0
---

# Debug Log

Create or update a debug iteration log for tracking fix attempts.

## Steps

1. If `$ARGUMENTS` is not provided, report "Usage: /debug-log <issue-name>" and stop.

2. Set the log file path: `docs/debug/$ARGUMENTS.md`

3. If the file does not exist, create it with this template:
   ```markdown
   # Debug Log: $ARGUMENTS

   **Created:** <current date>
   **Status:** IN PROGRESS

   ## Issue Description
   <!-- Describe the issue here -->

   ## Iterations

   | # | Hypothesis | Fix Applied | Result | Key Finding |
   |---|-----------|-------------|--------|-------------|
   ```

4. If the file exists, read it and count existing iterations.

5. Add a new iteration row to the table:
   ```
   | <next#> | <!-- hypothesis --> | <!-- fix --> | <!-- result --> | <!-- finding --> |
   ```

6. Add escalation reminders at thresholds:
   - Iteration 4: Add `> **Tier 1 Escalation:** Consider broader context. Re-read related docs.`
   - Iteration 6: Add `> **Tier 2 Escalation:** Step back and question assumptions. Consider alternative root causes.`
   - Iteration 8: Add `> **Tier 3 Escalation:** Consider architectural issues. Ask user for guidance.`
   - Iteration 10: Add `> **HARD CAP REACHED:** Stop and ask user for direction. Do not continue without explicit approval.`

7. Report the current iteration count and any escalation tier reached.
