---
name: e2e-inline-verification
description: >
  E2E verification is inline in the test flow, not a separate file: verify via
  API immediately after each UI-driven create, run deep scorecard reconciliation
  after match completion, and flush list views via the "All" filter before
  asserting on them.
globs: ["apps/mobile/integration_test/**/*.dart"]
synthesized: true
version: "1.0.0"
private: false
---

# E2E Inline Verification — verify at the point of creation

This extends the generic `e2e-persistence-verification` rule with CricScores'
API-first + filter-refresh ritual. Data entry goes through the UI (per
`integration_test/CLAUDE.md`: no Dio/http for *creation*), but verification
reads the API immediately — inside the same test, before the flow proceeds.

## The three rituals

### 1. API read-back after every UI-driven create

After creating an entity through the UI, verify it landed via API BEFORE
moving to the next entity or skipping work. Canonical example:
`flows/team_setup_flow.dart` lines 47-68 — when a team already appears in the
list, `_verifyRosterViaApi(...)` checks player count AND player names against
expectations; only then is the team skipped. An incomplete roster (e.g., from
a prior crashed run) is deleted via `_deleteTeamViaApi` and recreated. A name
visible in a list is treated as a hint, never as proof of a complete record.

### 2. Deep scorecard reconciliation after match completion

After a match completes, call `verifyScorecardDeep(tester, matchRecord:
record)` from `verification/scorecard_verifier.dart` (lines 22-82). It
asserts structure (Scorecard/Commentary/Analytics tabs, Batter/Bowler tables,
Extras, `Total (...)` rows) and — when a `MatchRecord` of every delivery the
test scored is passed — reconciles displayed totals against the recorded
deliveries. MUST build the `MatchRecord` while scoring (see
`models/delivery_record.dart`) so the reconciliation has ground truth;
structure-only verification is acceptable ONLY for tests that did not score
the match themselves.

### 3. Filter-refresh before list assertions

Before asserting counts on My Cricket list tabs, navigate to the tab and tap
the "All" filter chip to flush the view — stale filter state from a prior
screen makes counts under-report. Use `verifyMatchesTab(tester, minAllCount:
N)` from `verification/my_cricket_verifier.dart` (lines 84-124), which taps
Live/Won/Lost/All chips and asserts `MatchCard` counts under "All" — as done
by `03_verify_after_match_test.dart` line 44 and
`07_verify_all_screens_test.dart` line 91. Do not assert on a list you have
not just refreshed.

## Where verification lives

Inline in the test flow, at the moment of creation/completion — NOT in a
separate "verification test" run later. Shared verification *helpers* belong
in `integration_test/verification/` (scorecard_verifier, my_cricket_verifier,
player_profile_verifier); the *calls* belong inside the producing test.
Exception: the numbered verify tests (03, 07) exist to re-verify accumulated
state across tests — they complement inline checks, they do not replace them.

## CRITICAL RULES

- MUST verify via API immediately after each UI-driven create (roster count +
  names, not just entity name presence) before skipping or proceeding.
- MUST delete-and-recreate incomplete entities found during check-then-skip —
  never assume a partially created record is usable.
- MUST call `verifyScorecardDeep` with the test's `MatchRecord` after match
  completion so totals reconcile against recorded deliveries.
- MUST navigate to the tab and tap the "All" filter before asserting list
  counts; SHOULD use `verifyMatchesTab(minAllCount: N)` rather than raw
  finders.
- MUST NOT create data via direct API calls — UI creation + API verification;
  signal endpoints are the only API-write exception.
