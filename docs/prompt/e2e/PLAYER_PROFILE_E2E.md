# Player Profile E2E Test — Run Prompt

Run this prompt when you want to test player profile and career stat accumulation across multiple matches.

---

## Status: PARTIALLY COVERED

Player profile verification is partially covered by:
- `03_verify_after_match_test.dart` — Navigates to player profile after a standalone match, verifies basic data present
- `07_verify_all_screens_test.dart` — Navigates to player profile, verifies page loads with data

**Not yet covered:** Exact stat accumulation across multiple matches (Scenarios 35-36 from `E2E_TEST_SCENARIOS.md`).

**To fully implement:** Create `integration_test/tests/09_player_stat_accumulation_test.dart` with deterministic scoring to verify exact career stat values.

---

## What Existing Tests Verify

- Player profile page loads with data
- Career stats section is present
- Match history section is present
- Basic navigation to player profile works (Teams -> Team Detail -> Players -> Player Detail)

## What Still Needs Testing

- Exact career batting stats (total runs, average, strike rate) after 2+ matches
- Exact career bowling stats (total wickets, economy) after 2+ matches
- Stats correctly accumulate (not overwritten) across matches
- Career stats match per-match sums exactly

---

## Prerequisites

1. **Android emulator is running**
2. **Prod server is live** at `cricscores.in`
3. **Teams already created** — run test 01 first
4. **At least 1 match completed** — run test 02 first

---

## Run Existing Coverage

```bash
# Verify player profile after standalone match
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/03_verify_after_match_test.dart -d emulator-5554

# Verify all screens including player profile
cd apps/mobile && flutter test --flavor prod --dart-define=FLAVOR=prod integration_test/tests/07_verify_all_screens_test.dart -d emulator-5554
```

---

## Implementation Notes for Full Coverage

### Current Architecture
- `verification/player_profile_verifier.dart` — Player profile page assertions
- `helpers/navigation.dart` — Tab switching, page navigation
- `flows/standalone_match_flow.dart` — Full match lifecycle
- `core/app_bootstrap.dart` — App launch + Firebase auth

### Approach for Exact Stat Verification
1. Score 2 matches with deterministic (not random) delivery sequences
2. Know exactly what each player's stats should be after both matches
3. Navigate to player profile and `expect()` exact values

### Career Stats Accumulation Logic
After 2 matches, `player_career_stats` should show:
- `matches = 2`
- `batting_innings = 2` (batted in both matches)
- `total_runs = sum of runs across both matches`
- `batting_average = total_runs / dismissals`

The `career-stats.service.ts` triggers `refreshMatchPlayerCareerStats()` after each `completeMatch()` call.

---

## Debugging Tips

- **Career stats show only 1 match?** The `completeMatch()` call triggers career stat refresh. Verify both matches completed.
- **Profile page empty?** Player detail page fetches data from server. Wait for `pumpAndSettle` after navigation.
- **Navigation fails?** Profile is accessed via My Cricket -> Teams sub-tab -> Team Detail -> Players tab -> Player name.
