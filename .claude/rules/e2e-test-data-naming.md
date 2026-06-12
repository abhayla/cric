---
name: e2e-test-data-naming
description: >
  E2E test data uses deterministic names: Team{N}, Player{XXX} where XXX is the
  last 3 digits of phone 9999999XXX. New ranges MUST be claimed in the reserved
  ranges table before writing the test.
globs: ["apps/mobile/integration_test/**/*.dart"]
synthesized: true
version: "1.0.0"
private: false
---

# E2E Test Data Naming — deterministic, reserved, table-governed

All test entities follow the single-source-of-truth conventions in
`apps/mobile/integration_test/config/test_data.dart`:

| Entity | Pattern | Example |
|--------|---------|---------|
| Team | `Team{N}` | `Team1`, `Team20` |
| Player | `Player{XXX}` | `Player301`, `Player501` |
| Phone | `9999999{XXX}` (suffix == name suffix) | `9999999301` |

`generateTeams()` (test_data.dart, lines 38-49) produces this mapping
mechanically: player name suffix = `301 + globalIndex`, phone =
`'9999999$suffix'`. The standard set is `allTeams = generateTeams(12,
playersPerTeam: 6)`.

## Fixed accounts — never repurpose

- **Abhay** — phone `9999999998`, OTP `123456`. The viewer/second-device
  account. `generateTeams()` appends him to **Team1** (test_data.dart, line
  46); he MUST be on a roster of one team in every match a viewer test
  observes. If a test uses other teams, add Abhay to one of them.
- **Scorer** — `9999999999` (`scorerPhone`, used by `pumpAppAndWaitForHome`).
- **Spectator** — `9999999997` (`spectator_live_test.dart`, line 61-62):
  deliberately on NO roster, overridable via `--dart-define=VIEWER_PHONE=`.

## Reserved ranges — the table is the law

The table lives in `apps/mobile/integration_test/CLAUDE.md` ("Reserved
Ranges"): Team1–12 / Player301–432 belong to the standard set; Team20–21 /
Player501–512 belong to `perf_basic_test.dart`. Claiming a new range REQUIRES
adding a table row BEFORE writing the test:

1. Pick a `Team{N}` not in any reserved range.
2. Pick a player suffix range that does not overlap (use suffixes >= 500).
3. Define `const TestTeam`/`TestPlayer` lists in the test file — only move
   them into `test_data.dart` if shared by 2+ tests.
4. Update the reserved ranges table in the same change.

When a test reuses standard-set teams for isolation instead of claiming a new
range, it MUST justify the choice in a comment — see `perf_basic_test.dart`
lines 45-47 ("Use Team3 and Team4 for isolation from other tests that use
Team1/Team2").

## What NOT to do

- MUST NOT invent ad-hoc names (`PerfA`, `SpeedAlpha`) or non-convention
  phones (`1234567890`) — the check-then-skip logic in
  `flows/team_setup_flow.dart` and roster verification both key off the
  deterministic mapping.
- MUST NOT break the name-suffix == phone-suffix invariant; API verification
  helpers reconstruct phones from names.

## CRITICAL RULES

- Teams MUST be `Team{N}`; players MUST be `Player{XXX}` with phone
  `9999999{XXX}` — suffixes always match.
- Abhay (`9999999998`) MUST be rosterable on a team in every viewer-observed
  match; he is always on Team1 by default.
- A new team/player range MUST be claimed in the reserved ranges table in
  `apps/mobile/integration_test/CLAUDE.md` BEFORE the test is written;
  new player suffixes SHOULD start at >= 500.
- Reusing standard-set teams (e.g., Team3/Team4) MUST be justified with an
  isolation comment in the test file.
