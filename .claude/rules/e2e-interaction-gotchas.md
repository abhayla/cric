---
name: e2e-interaction-gotchas
description: >
  Two hard-won Flutter integration_test gotchas: never call pumpAndSettle (the
  app's infinite animations make it burn the full timeout), and dismiss the
  soft keyboard before tapping anything it might occlude.
globs: ["apps/mobile/integration_test/**/*.dart"]
synthesized: true
version: "1.0.0"
private: false
---

# E2E Interaction Gotchas — pumpAndSettle and keyboard occlusion

## Gotcha 1: pumpAndSettle never settles here

The app renders infinite repeating animations (`PulsingLiveDot`,
`SyncStatusIndicator`), so `pumpAndSettle()` NEVER reaches a settled frame —
every call burns its full 5s timeout. With hundreds of settle points per test,
that alone exhausts the test timeout (documented in
`core/test_utils.dart`, lines 12-20).

**Use instead** (all in `apps/mobile/integration_test/core/test_utils.dart`):

- `settle(tester)` (lines 21-25) — pumps 10 × 100ms frames; enough for route
  transitions and standard animations. Pass `pumpCount:` for longer
  transitions.
- `visualPause(tester, ms)` — explicit pause for human observation on-device.
- `waitForFinder` / `waitForText` / `waitForWidget<T>` (lines 34-75) — poll a
  condition with a deadline when you need "wait until X appears", instead of
  pumping a guessed duration.
- `waitForFinderGone` (lines 79-91) — wait for a dialog/page to disappear
  (e.g., `helpers/forms.dart` uses a 30s timeout for the page pop after a
  slow prod-server save).

MUST NOT call `tester.pumpAndSettle()` anywhere in `integration_test/`. If a
transition genuinely needs more frames, raise `pumpCount` or poll with
`waitForFinder` — do not reintroduce pumpAndSettle "just for this one spot".

## Gotcha 2: the keyboard eats taps that finders say succeeded

Symptom: "Finder found widget but tapped empty space" — the tap lands on the
soft keyboard overlay, not the button. `tester.ensureVisible()` does NOT
account for keyboard occlusion, so scrolling the button "into view" does not
help.

**Fix:** call `dismissKeyboard(tester)` (`core/test_utils.dart`, lines
97-104) before tapping any button that may sit in the lower half of the
screen after text entry. It sends a `TextInputAction.done` to the active
field, settles, unfocuses via `FocusManager.instance.primaryFocus?.unfocus()`,
and pumps 500ms for the dismiss animation. All three parts matter — an
unfocus without the follow-up pump still taps mid-animation.

Apply it after EVERY form-fill sequence (player creation, team naming, match
setup fields) and before tapping Save/Submit/Next buttons. When a tap still
misses after dismissal, use `dumpVisibleTexts(tester, label)` (same file) to
see what is actually on screen rather than retrying blind.

## CRITICAL RULES

- MUST NOT call `pumpAndSettle()` in integration tests — use
  `settle(tester, pumpCount: N)` from `core/test_utils.dart`.
- MUST poll with `waitForFinder`/`waitForText`/`waitForFinderGone` (deadline +
  interval) instead of pumping guessed durations for "wait until" conditions.
- MUST call `dismissKeyboard(tester)` after text entry and before tapping
  buttons that the soft keyboard may occlude; `ensureVisible` is NOT a
  substitute.
- SHOULD use `visualPause` only for human observation, never as a
  synchronization mechanism.
