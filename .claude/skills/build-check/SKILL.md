---
name: build-check
description: Run code generation (build_runner) and static analysis (flutter analyze) to catch lint errors and regenerate Drift/Freezed/Riverpod files.
disable-model-invocation: true
allowed-tools: Bash, Read
---

# Build Check

Run code generation and static analysis for the Flutter app.

## Steps

1. Run build_runner to regenerate Drift, Freezed, and Riverpod files:
   ```bash
   cd apps/mobile && dart run build_runner build --delete-conflicting-outputs
   ```

2. Run Flutter static analysis:
   ```bash
   cd apps/mobile && flutter analyze
   ```

3. Report results:
   - build_runner: number of files generated, any errors
   - flutter analyze: number of issues by severity (error, warning, info)
   - For each issue: file path, line number, message

4. Reminder: Files matching `*.g.dart`, `*.freezed.dart`, `*.gr.dart` are auto-generated. Never edit them manually — re-run build_runner instead.
