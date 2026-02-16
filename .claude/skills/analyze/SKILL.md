---
name: analyze
description: "Run Flutter static analysis (flutter analyze) without code generation. Use when you need a quick lint check, user says 'analyze', 'lint', or 'check warnings'. Faster than /build-check — skips build_runner."
disable-model-invocation: true
allowed-tools: Bash, Read
metadata:
  version: 1.0.0
---

# Analyze

Run Flutter static analysis only (no build_runner).

## Steps

1. Run Flutter analysis:
   ```bash
   cd apps/mobile && flutter analyze
   ```

2. Report results:
   - Number of issues by severity (error, warning, info)
   - For each issue: file path with line number, severity, message
   - If clean, confirm with "No issues found"

3. If errors exist, read the top 3 error files and suggest likely fixes.
