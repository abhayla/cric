---
name: commit-draft
description: "Analyze staged changes and draft a conventional commit message (type(scope): description). Use when user says 'commit', 'draft commit', or 'prepare commit'. Does NOT commit — only drafts for review."
disable-model-invocation: true
allowed-tools: Bash, Read
metadata:
  version: 1.0.0
---

# Commit Draft

Analyze staged changes and draft a conventional commit message.

## Steps

### Pre-Draft Verification

Before drafting the commit message:

1. Identify which test suites are affected by staged changes:
   - `apps/mobile/lib/src/features/<X>/` → `flutter test test/src/features/<X>/`
   - `apps/server/src/` → `bun test`

2. Check if tests were run recently (within this session):
   - If YES and all passed → continue to draft
   - If NO or tests failed → warn: "**Tests not verified.** Run tests before committing."

3. This is a WARNING, not a blocker — the developer can proceed.

### Draft Steps

1. Check for staged changes:
   ```bash
   git diff --cached --name-only
   ```
   If nothing is staged, report "No staged changes. Stage files with `git add` first." and stop.

2. Analyze the staged diff to understand the changes:
   ```bash
   git diff --cached --stat
   git diff --cached
   ```

3. Check recent commit style:
   ```bash
   git log --oneline -10
   ```

4. Determine the commit type from the changed files:
   - `apps/mobile/lib/src/features/` changes → `feat:` or `fix:`
   - `apps/server/src/` changes → `feat:` or `fix:`
   - `docs/` changes → `docs:`
   - `test/` changes → `test:`
   - `.claude/`, `scripts/`, `.github/` changes → `chore:`
   - Mixed → use the primary change type

5. Determine the scope from the primary directory:
   - `apps/mobile/lib/src/features/scoring/` → `scoring`
   - `apps/server/src/services/` → `server`
   - `docs/planning/` → `planning`
   - `.claude/` → `claude-code`
   - Multiple scopes → omit scope

6. Draft the commit message in this format:
   ```
   <type>(<scope>): <description>

   Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
   ```

7. Present the drafted message to the user. Do NOT run `git commit`. Let the user review, modify, and commit manually.
