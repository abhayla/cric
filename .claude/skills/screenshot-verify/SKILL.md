---
name: screenshot-verify
description: Take a screenshot of the running app and compare it against the HTML wireframe for the specified screen.
disable-model-invocation: true
allowed-tools: Bash, Read, Glob, mcp__playwright__browser_navigate, mcp__playwright__browser_take_screenshot, mcp__playwright__browser_snapshot
---

# Screenshot Verify

Compare the running app screen against the HTML wireframe.

## Arguments

`$ARGUMENTS` should be the screen number (e.g., "12" for scoring page, "05" for home page).

## Steps

1. **Identify the wireframe file:**
   - Find the wireframe: `docs/ui/$ARGUMENTS-*.html` (e.g., `docs/ui/12-scoring-page.html`)
   - If no match, list `docs/ui/` and ask the user which screen to compare.

2. **Screenshot the wireframe via Playwright:**
   ```
   Navigate Playwright to: http://localhost:9123/$ARGUMENTS-<name>.html
   Screenshot to: .playwright-mcp/screenshots/wireframe-$ARGUMENTS.png
   ```
   If localhost:9123 is not serving, tell the user to run:
   `python -m http.server 9123 --directory docs/ui`

3. **Screenshot the running Flutter app:**
   ```bash
   cd apps/mobile && flutter screenshot --out=../../.playwright-mcp/screenshots/app-$ARGUMENTS.png
   ```

4. **Read both screenshots** to view them visually.

5. **Compare against 6 criteria:**

   | # | Criterion | Check |
   |---|-----------|-------|
   | 1 | Layout structure | Header/body/footer zones match wireframe |
   | 2 | Component presence | All buttons, cards, fields, icons present |
   | 3 | Spacing compliance | 8dp grid system, margins/padding within ±4-8dp tolerance |
   | 4 | M3 Light theme | Correct surface colors, seed #1976D2, no hardcoded colors |
   | 5 | Content accuracy | Labels, placeholder text match wireframe |
   | 6 | Touch targets | All interactive elements >= 48x48dp |

6. **Report results:**

   ```
   ## Screenshot Verification: Screen $ARGUMENTS

   | Criterion | Status | Notes |
   |-----------|--------|-------|
   | Layout structure | PASS/FAIL | ... |
   | Component presence | PASS/FAIL | ... |
   | Spacing compliance | PASS/FAIL | ... |
   | M3 Light theme | PASS/FAIL | ... |
   | Content accuracy | PASS/FAIL | ... |
   | Touch targets | PASS/FAIL | ... |

   **Overall: PASS / FAIL**

   ### Discrepancies (if FAIL)
   - [ ] Fix 1: ...
   - [ ] Fix 2: ...
   ```

7. **If FAIL:** List specific fixes needed. The main agent will fix and re-run this skill (max 5 iterations).
