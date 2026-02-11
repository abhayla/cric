---
name: analyze
description: Run Flutter static analysis (flutter analyze) without code generation. Faster than /build-check when you only need lint checking.
disable-model-invocation: true
allowed-tools: Bash, Read
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
