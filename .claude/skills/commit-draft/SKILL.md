---
name: commit-draft
description: Analyze staged changes and draft a conventional commit message. Does NOT commit - only drafts for review.
disable-model-invocation: true
allowed-tools: Bash, Read
---

# Commit Draft

Analyze staged changes and draft a conventional commit message.

## Steps

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
