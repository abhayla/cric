# Integration Test CLAUDE.md

## Test Data Naming Convention (MANDATORY)

All test teams and players MUST follow the naming pattern from `config/test_data.dart`:

| Entity | Pattern | Example |
|--------|---------|---------|
| Team name | `Team{N}` | `Team1`, `Team20` |
| Player name | `Player{suffix}` | `Player301`, `Player507` |
| Player phone | `9999999{suffix}` | `9999999301`, `9999999507` |

### Viewer Account Rule

**Abhay (phone `9999999998`, OTP `123456`) is the viewer/second-device account.** He must be added as a roster member on at least one team involved in every test match, so he can view the match live from the second device. Currently, `generateTeams()` in `test_data.dart` adds him to Team1. If a test uses teams other than Team1 (e.g., perf test uses Team3/Team4), ensure Abhay is on one of those teams too.

### Reserved Ranges

| Range | Used By | Teams | Players |
|-------|---------|-------|---------|
| Team1–12 | Standard test set (`test_data.dart`) | `generateTeams(12)` | Player301–432 |
| Team20–21 | Performance test (`perf_basic_test.dart`) | 2 teams × 6 players | Player501–512 |

### Reserved Phone Numbers

| Phone | OTP | Used By |
|-------|-----|---------|
| `9999999999` | `123456` | Scorer (device 1) — all tests |
| `9999999998` | `123456` | Viewer/Abhay (device 2) — `08_viewer_live_test` |
| `9999999997` | `123456` | Spectator (device 2) — `spectator_live_test` (not on any team) |

### Adding New Test Data

1. Pick a `Team{N}` number NOT in the reserved ranges above.
2. Pick a `Player{suffix}` range that doesn't overlap (use 3-digit suffixes >= 500).
3. Define as `const` `TestTeam`/`TestPlayer` lists in the test file (not in `test_data.dart` unless shared).
4. Update the reserved ranges table above.

### Anti-Patterns (DO NOT)

```dart
// BAD - custom names cause confusion and break conventions
TestTeam(name: 'PerfA', players: [TestPlayer(name: 'PA1', phone: '1234567890')])
TestTeam(name: 'SpeedAlpha', players: [TestPlayer(name: 'Alpha1', phone: '5555555555')])

// GOOD - follows the convention
TestTeam(name: 'Team20', players: [TestPlayer(name: 'Player501', phone: '9999999501')])
```

## Rules

- **Dismiss keyboard before tapping off-screen buttons.** On device/emulator, the soft keyboard occludes the bottom portion of the screen. `ensureVisible` scrolls within the `ScrollView` extent but does NOT account for keyboard occlusion — the button may be "visible" in scroll terms but physically behind the keyboard. Always call `dismissKeyboard(tester)` (from `core/test_utils.dart`) before `ensureVisible` + `tap` on any button that could be below the fold. This applies to all form submission flows.

## Known Gotchas

- **`ensureTeamsExist` verifies roster completeness** via API. If a team has the wrong player count (e.g., from a prior crashed run), it deletes and recreates from scratch.
- **`_selectPlayingXIIfNeeded`** taps generic `InkWell` widgets by index. When `roster.length < playersPerSide`, the toss wizard gets stuck. Ensure teams have the correct number of players before match setup.
- **Prod server latency**: `fillAndSubmitPlayer` uses a 30s timeout for the page pop after API call. If the server is slow, player creation may time out.
- **`fillAndSubmitPlayer` timeout** is in `helpers/forms.dart` line ~211 (`waitForFinderGone timeoutMs: 30000`).

## Test Execution

All integration tests run against the prod server (`cricscores.in`):

```bash
cd apps/mobile
flutter test --flavor prod --dart-define=FLAVOR=prod \
  integration_test/tests/<test>.dart -d emulator-5554
```

Tests that create teams (01, perf) should run before tests that assume teams exist (02-08).
