---
name: screenshot-verify
description: Take a screenshot of the running app and compare it against the blueprint wireframe for the specified screen.
disable-model-invocation: true
allowed-tools: Bash, Read, Glob
---

# Screenshot Verify

Compare the running app screen against the blueprint wireframe.

## Steps

1. `$ARGUMENTS` should be the screen name (e.g., "scoring_page", "home_page", "match_setup_page").

2. Take a screenshot of the running app:
   ```bash
   cd apps/mobile && flutter screenshot --out=screenshot.png
   ```

3. Read the screenshot file to view the current app state.

4. Read `docs/planning/blueprint.html` to find the corresponding wireframe for the specified screen.

5. Compare and check:
   - **Layout**: Does the overall structure match the wireframe (AppBar, body sections, FAB, bottom nav)?
   - **Spacing**: Are margins and padding visually consistent?
   - **Data display**: Are all wireframe fields present and in the right positions?
   - **Interactive elements**: Are buttons, dialogs, and touch targets present?
   - **Theme**: Does the dark theme look correct (no white/light backgrounds)?

6. Report:
   - Matching elements (brief)
   - Discrepancies (detailed, with specific wireframe reference)
   - Suggested fixes for each discrepancy
