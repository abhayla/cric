# CricApp - Continue Prompt

## Context for Resuming Work

**Project:** CricApp - Cricket scoring mobile app (CricHeroes competitor)
**Status:** Phase 4 (Analytics) COMPLETE — Manhattan, Worm, Run Rate charts + MVP algorithm implemented. 1649 Flutter tests, 202 server tests.
**Working Directory:** `C:\Abhay\VideCoding\cric\`

## Tech Stack

See [CLAUDE.md](../CLAUDE.md#tech-stack) for tech stack.

## Documentation

See [PROJECT_MANAGEMENT.md](process/PROJECT_MANAGEMENT.md) for the full documentation map with all planning and process docs.

## What to Do Next

**Phase 4 (Analytics) is COMPLETE.** Manhattan chart, Worm chart, Run Rate chart, and MVP rankings implemented. Next: Phase 5 (Player Profiles & Stats) or Phase 6 (Polish & Testing).

**Recent completion:** Phase 4 Analytics (Issues #42/#43 scope). 8 new source files + 8 new test files + 3 modified files. 109 net new tests (1649 total Flutter tests). All analytics computed client-side from existing ScorecardData — no new server endpoints needed.

### Phase 4 completion details:
- **Domain entities:** `chart_data.dart` (OverStats, WormDataPoint, RunRateDataPoint, InningsChartData, MatchChartData), `mvp_data.dart` (MvpPlayerScore, MatchMvpData)
- **Computation utils:** `analytics_utils.dart` (computeManhattan, computeWorm, computeRunRate, computeMatchChartData), `mvp_utils.dart` (computeMvp implementing SCORING_RULES.md §5 — batting/bowling/fielding points with milestones, SR bonus, economy bonus, tiebreakers)
- **Chart widgets:** ManhattanChart (fl_chart BarChart, wicket over coloring), WormChart (LineChart, solid+dashed lines), RunRateChart (LineChart, reference lines at 6/9/12), MvpRankingWidget (medal badges for top 3, card list)
- **ScorecardPage integration:** Replaced "Analytics coming soon" with 4 nested sub-tabs (Manhattan, Worm, Run Rate, MVP). Manhattan has innings toggle chips.
- **Dependency:** Added `fl_chart: ^0.69.0`
- **MVP algorithm verified:** R. Sharma spec example = 10.2 pts, J. Bumrah spec example = 15.0 pts (exact match to SCORING_RULES.md §5)

### Phase 3 Progress (IN PROGRESS)

| Issue | Title | Status | Tests |
|-------|-------|--------|-------|
| #36 | Scoring service: delivery recording pipeline (server) | DONE | 48 |
| #26 | Scoring domain entities + state machine notifier (Flutter) | DONE | 333 |
| #27 | Select new batter + select bowler bottom sheets | DONE | 43 |
| #28 | Scoring page UI | DONE | 67 |
| #29 | Extras panel | DONE | 36 |
| #30 | Wicket dialog | DONE | 47 |
| #31 | Innings transition modal | DONE | 47 |
| #32 | Match complete modal | DONE | 40 |
| #33 | Undo functionality | DONE | 15 |
| #37 | Scorecard page | DONE | 62 |
| #38 | WebSocket server + room management | DONE | 32 |
| #39 | WebSocket client + live broadcast (Flutter) | DONE | 81 |
| #40/#41 | Full offline scoring + sync queue | DONE | 127 |

**Issue #36 completion details:**
- `apps/server/src/services/scoring.service.ts` — Full 10-step delivery pipeline, undo, getDeliveries, abandon, declare, reopenInnings, reopenMatch
- `apps/server/src/routes/v1/scoring.ts` — 6 REST endpoints (POST delivery, DELETE undo, GET deliveries, POST abandon, POST declare, POST reopen)
- `apps/server/test/services/scoring.service.test.ts` — 48 tests (basic deliveries, extras, wickets, free hit, stats updates, over completion, innings completion, validation, undo, getDeliveries, abandonMatch, declareInnings, reopenInnings, reopenMatch, configurable rules)
- Pre-transaction validation pattern for fail-fast error handling
- Bun test workaround: `.rejects.toThrow()` hangs with async DB functions; use `expectToReject()` helper with try-catch instead

**Issue #27 completion details:**
- 4 source files + 3 test files = 7 files, 43 new tests (1018 total Flutter tests)
- **New entity:** `playing_xi_player.dart` — PlayingXIPlayer (playerId, displayName, playerRole, battingStyle, bowlingStyle, isCaptain, isKeeper + computed: initials, badge, battingStyleShort, roleLabel). 15 tests.
- **ScoringState additions:** `BowlerOption` class (playerId, displayName, isEligible, ineligibleReason, spell), 3 new fields (`battingTeamPlayers`, `bowlingTeamPlayers`, `maxOversPerBowler`), 5 computed getters (`yetToBatPlayers`, `retiredHurtBatters`, `availableBatterCount`, `bowlerOptions`, `eligibleBowlerCount`). 20 tests.
- **SelectBatterSheet widget:** Shows yet-to-bat + retired hurt players. Single-tap selection. Auto-select + SnackBar when 1 option. Dismissed batter subtitle in AppColors.wicket. 14 tests.
- **SelectBowlerSheet widget:** Shows eligible bowlers (O-M-R-W + Ec) and ineligible greyed out with reason ("Bowled last over", "Max overs reached"). Single-tap. Auto-select + SnackBar when 1 eligible. 14 tests.
- **Bowler eligibility:** Consecutive-over check (lastBowlerId) + max overs (`maxOversPerBowler` or `ceil(totalOvers/5)`)
- **TDD followed:** RED → GREEN → REFACTOR for all 4 steps (entity → state → batter widget → bowler widget)

**Issue #28 completion details:**
- 6 source files + 6 test files + 1 modified = 13 files, 67 new tests (1085 total Flutter tests)
- **ScoringPage** (`presentation/pages/scoring_page.dart`): StatefulWidget holding ScoringNotifier. ScoringPageArgs plain class with all init fields. Layout: Column [ScoreHeader (fixed), Expanded(ScrollView with batter cards + bowler card + this-over), ScoringControls (fixed)]. PopScope for exit dialog. Auto-triggers SelectBatterSheet/SelectBowlerSheet on state change. 16 tests.
- **ScoreHeader** (`presentation/widgets/score_header.dart`): Primary-colored container with team name, innings label, score/overs, CRR. Shows RRR/Target/Need for 2nd innings only. 11 tests.
- **BatterCard** (`presentation/widgets/batter_card.dart`): Striker highlight (primary left border + asterisk) vs non-striker. Row: name, R, B, 4s, 6s, SR. 8 tests.
- **BowlerCard** (`presentation/widgets/bowler_card.dart`): Wicket-red left border. Row: name, O, M, R, W, Ec. 5 tests.
- **ThisOverDisplay** (`presentation/widgets/this_over_display.dart`): Ball indicators (colored circles per delivery using notation). Free hit badge. Color mapping: wicket→red, four→blue, six→purple, dot→grey outline. 11 tests.
- **ScoringControls** (`presentation/widgets/scoring_controls.dart`): Run buttons (0,1,2,3,4,6 + "..." overthrow), extras row (WD,NB,B,LB,W), action bar (undo + swap). 16 tests.
- **Router** (`app/router.dart`): Added `/scoring/:matchId` route, `scoringPath()` helper, wired toss `onStartMatch` to navigate to scoring page.
- **Stubs:** W → "Wicket dialog — coming in Issue #30" (extras stubs removed by #29)
- **TDD followed:** RED → GREEN → REFACTOR for all widgets (bottom-up: batter_card → bowler_card → this_over_display → score_header → scoring_controls → scoring_page → router)

**Issue #29 completion details:**
- 1 source file + 1 test file + 2 modified = 4 files, 36 net new tests (1121 total Flutter tests)
- **ExtrasPanel** (`presentation/widgets/extras_panel.dart`): StatefulWidget bottom sheet for extras. ExtraType enum (wide/noBall/bye/legBye) with displayName, color, runsLabel, runOptions, defaultRuns. Configurable penalties (wideRunsPenalty, noBallRunsPenalty). Run buttons: Wide [0,1,2,3,4,...], NoBall [0,1,2,3,4,6,...], Bye/LegBye [1,2,3,4,...]. Selected button = FilledButton in type color, unselected = OutlinedButton. Custom picker ("...") opens AlertDialog with ActionChip Wrap [5-12]. Total row shows computed total (penalty + runs for wide/noBall, just runs for bye/legBye). Full-width Confirm button in type color. 29 tests.
- **ScoringPage wiring**: Replaced 4 SnackBar stubs with `_showExtrasPanel(ExtraType)` → opens bottom sheet → on confirm calls `_recordExtra` which delegates to notifier's `recordWide/NoBall/Bye/LegBye`. Checks side effects (needsNewBowler/Batter) after recording. 8 integration tests (4 open + 4 confirm with score verification).
- **Deferred:** Wicket-on-extras toggle (depends on Issue #30 Wicket Dialog). No-ball + bye combination (notifier limitation).
- **TDD followed:** RED (tests fail at compile) → GREEN (implementation passes all tests)

**Issue #30 completion details:**
- 1 new source file + 1 new test file + 2 modified = 4 files, 47 net new tests (1168 total Flutter tests)
- **WicketDialog** (`presentation/widgets/wicket_dialog.dart`): 3-step wizard dialog for recording dismissals. Step 1: Dismissal type grid (11 DismissalType values as chips — Timed Out/Obstruct. disabled at 0.35 opacity). Step 2: Fielder selection with search TextField + ListView (for caught/stumped/run out). Step 3: Run out details — batter toggle (striker/non-striker), batters crossed Switch, runs 0-3 ChoiceChips. Pink header (#FFEBEE) with "Wicket!" in red, close X button. Footer: Back (disabled step 1) + Next/Confirm Wicket (red FilledButton, disabled without selection). Free hit mode: only Run Out enabled.
- **WicketDialogResult** data class: dismissalType, dismissedPlayerId, fielderId?, fielderName?, runsFromBat, battersCrossed.
- **ScoringPage wiring**: Replaced W button stub snackbar with `_showWicketDialog()` → `showDialog` with `barrierDismissible: false` → on confirm calls `_recordWicket()` which delegates to notifier's `recordWicket()` then checks side effects (auto-shows SelectBatterSheet). Removed unused `_showStubSnackBar` method.
- **Tests (43 widget + 4 integration):** Header (3), step 1 grid (9), button text per type (6), free hit (3), step 2 fielder (8), step 3 run out (7), confirm callbacks (5), scoring page integration (4: W opens dialog, Bowled→0/1, auto-select batter, W disabled when innings complete, Caught+fielder→0/1).
- **TDD followed:** RED (wrote all 43 tests first) → GREEN (implemented widget until all pass) → wire into ScoringPage → integration tests
- **Deferred:** Wide+wicket combination, direct hit toggle (YAGNI — no `recordWicket()` param)

**Issue #31 completion details:**
- 1 new source file + 1 new test file + 2 modified = 4 files, 47 net new tests (1215 total Flutter tests)
- **InningsTransitionModal** (`presentation/widgets/innings_transition_modal.dart`): 3-step StatefulWidget wizard. Step 1: Innings summary (score, team/overs, extras breakdown, run rate, FOW list, top 2 batters + top bowler, target + RRR). Step 2: Select 2 opening batters from chasing team (checkbox rows, max 2, auto-deselect oldest on 3rd pick) + striker designation (radio when 2 selected, auto-first). Step 3: Select opening bowler from bowling team (radio rows). Primary-container header with stepper indicators (1-Summary, 2-Openers, 3-Bowler). Footer: Back (disabled step 1) + Next/Start Innings.
- **InningsTransitionResult** data class: strikerId, strikerName, nonStrikerId, nonStrikerName, bowlerId, bowlerName.
- **ScoringNotifier additions:** `FallOfWicket` class (wicketNumber, scoreAtFall, oversAtFall, dismissedPlayerName). `fallOfWickets` computed getter on ScoringState (iterates deliveryHistory). `declareInnings()` (1st innings only, guards). `startSecondInnings()` (creates fresh ScoringState with swapped teams, target, resets, calls selectNewBatter/selectNewBowler).
- **ScoringPage wiring:** `_checkSideEffects` now takes `prevIsInningsComplete` param. Early return on innings completion: 1st innings → `_showInningsTransitionModal()`, 2nd innings → match complete SnackBar stub. `_showInningsTransitionModal()` computes top performers, shows non-dismissible dialog. `_handleInningsTransition()` calls `startSecondInnings()`.
- **Tests (17 notifier + 25 widget + 5 integration):** declareInnings (3), fallOfWickets (4), startSecondInnings (10), modal header (2), step 1 summary (9), step navigation (4), step 2 openers (6), step 3 bowler (4), scoring page integration (5: all-out modal, overs-exhausted modal, completing modal transitions, target shown, match complete snackbar).
- **TDD followed:** RED → GREEN → REFACTOR for notifier layer, widget layer, then integration wiring.

**Issue #32 completion details:**
- 2 new source files + 2 new test files + 2 modified = 6 files, 40 net new tests (1255 total Flutter tests)
- **FirstInningsSummary** class in `scoring_notifier.dart`: Captures 1st innings snapshot (teamName, teamId, totalRuns, totalWickets, totalBalls, oversDisplay) with `scoreDisplay` computed getter. Stored in `ScoringState.firstInningsSummary` (nullable), populated by `startSecondInnings()` before state replacement.
- **MatchResultType** enum (runs, wickets, tie) + **MatchResult** class (winnerTeamId?, winnerTeamName?, resultType, margin?, resultDescription). Mirrors server `completeMatch()` logic at `scoring.service.ts:1204-1222`.
- **ScoringState.matchResult** computed getter: Returns null if match not complete or no firstInningsSummary. Computes: 1st > 2nd → runs victory (margin = difference), 2nd > 1st → wickets victory (margin = playersPerSide - 1 - wickets), equal → tie.
- **MatchCompleteModal** (`presentation/widgets/match_complete_modal.dart`): StatelessWidget. Layout: ConstrainedBox(400) → Material(rounded) → Column [header(primaryContainer), scoreComparison(primary bg with team avatars/initials/scores/overs + VS), resultText(headlineSmall bold primary), footer(FilledButton View Scorecard + OutlinedButton Back to Home)].
- **MatchCompleteAction** enum (viewScorecard, backToHome).
- **ScoringPage wiring:** Replaced SnackBar stub with `_showMatchCompleteModal()` (non-dismissible dialog). `_handleMatchCompleteAction()`: viewScorecard → stub SnackBar (Issue #34), backToHome → Navigator.pop. Added optional `firstInningsSummary` to ScoringPageArgs for test injection.
- **Tests (30 notifier + 17 widget + 4 integration - 1 updated):** FirstInningsSummary (3), MatchResult (4), ScoringState.firstInningsSummary (3), ScoringState.matchResult (7), startSecondInnings captures (3), notifier sub-total = 20 new; widget header (2), score comparison (8), result text (3), footer actions (4), widget sub-total = 17; integration: modal appears (1 updated), correct result (1), back to home (1), view scorecard stub (1) = 4 new.
- **Deferred:** Super Over button (no tournament/knockout context), Man of the Match (Phase 5+), View Scorecard navigation (Issue #34).
- **TDD followed:** RED → GREEN → REFACTOR for notifier layer, widget layer, then integration wiring.

**Issue #33 completion details:**
- 1 modified source file + 1 modified test file = 2 files, 15 net new tests (1270 total Flutter tests)
- **Bug fixes in `undoLastDelivery()`:**
  - FIX 1: `bowlerId` not restored on undo across over boundary — now restores from reopened `Over.bowlerId`
  - FIX 2: `lastBowlerId` not restored on undo across over boundary — now set to bowler of the over before the reopened one (or null if first over)
  - FIX 3: Maiden count not decremented on undo across over boundary — now checks `previousOver.isMaiden` and decrements bowler's maidens
- **New constraint: `undoBlockedByTransition`** — New boolean field on `ScoringState` (default false). `canUndo` now checks `!undoBlockedByTransition`. Set to true by `selectNewBatter`/`selectNewBowler` (only when deliveryHistory is non-empty). Reset to false by `_processDelivery` and `undoLastDelivery`. Matches SCORING_RULES.md Section 4: undo blocked after scorer confirms new batter/bowler selection.
- **Tests (15 new):** Blocked-after-transition group (7): canUndo false after selectNewBatter/selectNewBowler, true before selections, NOT blocked during initial setup, resets after delivery, undo resets flag. Over boundary fixes group (4): restores bowlerId, restores lastBowlerId, first over sets lastBowlerId null, decrements maiden count. Edge cases group (4): undo bye, undo leg-bye, undo wicket restores isNotOut, undo free hit chain preserves pending.
- **No UI changes needed:** Undo button already exists in ScoringControls; `canUndo` getter propagates changes automatically.
- **TDD followed:** RED (wrote 15 tests) → GREEN (implemented fixes) → REFACTOR (verified 1270 tests pass + flutter analyze clean).

**Issue #37 completion details:**
- 4 new source files + 4 new test files + 3 modified = 11 files, 62 net new tests (1332 total Flutter tests)
- **InningsData** (`domain/entities/innings_data.dart`): Complete innings snapshot capturing all data needed for scorecard. Fields: teamName, teamId, headline stats, Map<String,BatterInnings>, Map<String,BowlerSpell>, extras breakdown, fallOfWickets, deliveryHistory, roster. Computed: scoreDisplay, oversDisplay, runRate, extrasDisplay, battingOrder (first-appearance from delivery history), yetToBatPlayers, bowlingOrder. Factory: `InningsData.fromScoringState(ScoringState)`. 14 tests.
- **ScorecardData** (`domain/entities/scorecard_data.dart`): Container for both innings + matchResult + match metadata. Factory: `ScorecardData.fromScoringState(state)` with assertions. 5 tests.
- **CommentaryGenerator** (`core/utils/commentary_generator.dart`): Pure top-level function generating ball-by-ball text from Delivery data. Handles: dot, runs, four, six, wide, no-ball, bye, leg-bye, all 11 dismissal types. 18 tests.
- **ScorecardPage** (`presentation/pages/scorecard_page.dart`): 3-tab page (Scorecard, Commentary, Analytics). Score comparison header (primary bg with team avatars/scores/overs + VS). Result banner (primaryContainer). Scorecard tab: innings toggle chips, batting table (Batter/R/B/4s/6s/SR + dismissal), extras row, total row, yet-to-bat, FOW chips, bowling table (Bowler/O/M/R/W/Ec). Commentary tab: reverse-chrono ListView with auto-generated text. Analytics tab: placeholder. 25 tests.
- **ScoringState additions:** `firstInnings: InningsData?` field (nullable), populated by `startSecondInnings()` alongside existing `firstInningsSummary`. Added to constructor, copyWith.
- **ScoringPage wiring:** `_handleMatchCompleteAction(viewScorecard)` creates `ScorecardData` from state and navigates via `Navigator.pushReplacement` to ScorecardPage.
- **Router:** Added `/scorecard/:matchId` route with `ScorecardData` extra, `scorecardPath()` helper.
- **TDD followed:** RED → GREEN → REFACTOR for entities, utility, then widget. All 1332 tests pass, flutter analyze clean.

**Issue #38 completion details:**
- 4 new source files + 3 new test files + 2 modified = 9 files, 32 net new tests (202 total server tests)
- **WebSocket types** (`src/types/websocket.ts`): ClientMessage (join_match/leave_match), ServerMessage (7 types: match_state/score_update/wicket/innings_complete/match_complete/delivery_undone/error). Shared sub-types: PlayerBattingSnapshot, PlayerBowlingSnapshot, OverBallDisplay, LastDeliveryInfo.
- **Room state** (`src/websocket/rooms.ts`): `getMatchState(matchId)` queries DB for full match snapshot (innings, batting/bowling stats, current over, recent deliveries). 6 `build*Message()` pure functions for each broadcast type. `matchTopic()` helper returns `match:<matchId>`. 17 tests.
- **Broadcaster** (`src/websocket/broadcaster.ts`): Stores Bun server reference via `initBroadcaster(server)`. 6 typed broadcast functions that call `server.publish(topic, JSON.stringify(message))`. Fire-and-forget pattern.
- **WebSocket handler** (`src/websocket/handler.ts`): Elysia plugin with `.ws('/ws', {...})`. Anonymous viewers allowed (no auth required). `join_match` → subscribe to topic + send match_state snapshot. `leave_match` → unsubscribe. Invalid messages → error response. `idleTimeout: 120`. 9 tests.
- **Scoring route integration** (`src/routes/v1/scoring.ts`): After `recordDelivery` → broadcasts score_update (+ wicket/innings_complete/match_complete if applicable). After `undoDelivery` → broadcasts delivery_undone. After `abandonMatch` → broadcasts match_complete. After `declareInnings` → broadcasts innings_complete. After `reopen*` → broadcasts match_state (full refresh). All broadcast errors caught and logged (don't block HTTP response).
- **Index wiring** (`src/index.ts`): `.use(websocketHandler)` before routes, `initBroadcaster(app.server!)` after `.listen()`.
- 6 integration tests verify end-to-end: service call → build message → broadcaster → WS subscriber receives correct message type.

**Offline Scoring + Sync Queue completion details (Issues #40/#41 scope):**
- 8 new source files + 6 new test files + 5 modified source + 1 modified test = 20 files, 127 net new tests (1540 total Flutter tests)
- **Approach:** Observer/Wrapper pattern — `ScoringPersistenceService` wraps `ScoringNotifier` without modifying it (preserving all 1413 existing tests). JSON snapshot persistence: serialize full `ScoringState` to JSON and upsert into `ScoringSnapshots` Drift table.
- **ScoringSnapshots table** (`shared/data/database/tables/scoring_tables.dart`): matchId (PK), inningsNumber, stateJson, isActive, updatedAt. Schema bumped to v2 with migration.
- **ScoringDao** (`shared/data/database/daos/scoring_dao.dart`): `@DriftAccessor` with snapshot ops (save/load/getActive/deactivate/delete) + sync queue ops (enqueue/getPending/markSynced/incrementRetry/getUnsynced/cleanup). 18 tests.
- **ScoringStateConverter** (`scoring/data/models/scoring_state_converter.dart`): Pure functions for JSON round-trip of entire ScoringState tree. Covers: PlayingXIPlayer, Delivery, WicketInfo, BatterInnings, BowlerSpell, Over, FirstInningsSummary, InningsData, FallOfWicket, ScoringState. 41 tests.
- **ScoringLocalDatasource** (`scoring/data/datasources/scoring_local_datasource.dart`): Wraps DAO + converter. Methods: saveState, loadState, hasActiveSession, getResumableMatchIds, completeMatch, clearMatch. 10 tests.
- **ScoringPersistenceService** (`scoring/presentation/notifiers/scoring_persistence_service.dart`): Wraps ScoringNotifier. Fire-and-forget `_persistState()` after each mutation. Static factories: `createNew()`, `resume()`. Delegates: recordDelivery/Wide/NoBall/Bye/LegBye/Wicket, undoLastDelivery, selectNewBatter/Bowler, swapStrike, declareInnings, startSecondInnings. `onMatchComplete()`. 19 tests.
- **SyncService** (`shared/data/sync/sync_service.dart`): FIFO queue processor. `enqueueDelivery()`/`enqueueUndo()` + immediate sync attempt. `processSyncQueue()` stops on first failure. Periodic timer (10s). Max 5 retries then skip. `SyncStatus` enum (allSynced/pending/error). 17 tests.
- **SyncStatusIndicator** (`scoring/presentation/widgets/sync_status_indicator.dart`): Compact widget with cloud icons (green synced, orange pending + count badge, red error). 15 tests (8 standalone + 7 ScoreHeader integration).
- **ScoringPage integration:** Optional `datasource` param. Async `_initScoring()` with resume-or-create logic. Loading state. Exit dialog: "Progress saved locally" (with persistence) vs "Unsaved progress will be lost" (without). 6 persistence integration tests.
- **Provider wiring:** `scoringDaoProvider`, `scoringLocalDatasourceProvider` added.
- **TDD followed:** RED → GREEN → REFACTOR for all 8 implementation steps (table → DAO → converter → datasource → service → page integration → sync → UI).

**Issue #26 completion details:**
- 8 source files + 8 test files = 16 files, 333 new tests (955 total Flutter tests)
- **Domain entities (6 files in `features/scoring/domain/entities/`):**
  - `delivery.dart` — DismissalType enum (11 values with id/label/code/requiresFielder/bowlerCredited), InningsCompletionReason enum, Delivery entity (26 fields + computed: isLegal, totalRuns, isExtra, isDotBall, bowlerRunsConceded, notation)
  - `wicket_info.dart` — WicketInfo (dismissedPlayerId, dismissalType, bowlerCredited, fielderId?, battersCrossed?)
  - `innings.dart` — Innings entity (totals, completion state, target, super over) with computed oversDisplay, runRate, runsNeeded
  - `batter_innings.dart` — BatterInnings (runs, balls, fours, sixes, isNotOut, isOnStrike, dismissalType) with computed strikeRate, isActive, canReturn, dismissalDescription
  - `bowler_spell.dart` — BowlerSpell (ballsBowled, maidens, runsConceded, wicketsTaken) with computed oversDisplay, economyRate, figures
  - `over.dart` — Over (overNumber, bowlerId, runsConceded, isMaiden, deliveries) with computed legalBalls, notation
- **Core utility (`core/utils/scoring_utils.dart`):**
  - Pure functions: isLegalDelivery, calculateTotalRuns, shouldSwapStrike, isOverComplete, checkInningsCompletion, isMaidenOver, isNextFreeHit, validateExtras, validateBatterPair
- **Presentation (`features/scoring/presentation/notifiers/scoring_notifier.dart`):**
  - ScoringState: ~30 fields covering match context, players, innings totals, over state, player stats maps, completion, UI state, undo history + 15+ computed getters
  - ScoringNotifier: 10-step _processDelivery pipeline mirroring server, recordDelivery/Wide/NoBall/Bye/LegBye/Wicket, undoLastDelivery, swapStrike, selectNewBatter/Bowler
- **Test breakdown:** delivery 66, wicket_info 9, innings 23, batter_innings 33, bowler_spell 20, over 12, scoring_utils 66, scoring_notifier 104

### Phase 2.5 Progress (COMPLETE)

| Issue | Title | Status | Tests |
|-------|-------|--------|-------|
| #25 | Tournament domain entities + repository interface | DONE | 108 |
| #26 | Tournament API — CRUD, registration, fixtures, standings | DONE | 122 (server) |
| #27 | Tournament data layer (models, datasource, repository) | DONE | 42 |
| #28 | Tournaments List page | DONE | 12 |
| #29 | Create Tournament page | DONE | 14 |
| #30 | Tournament Detail page (3 tabs) | DONE | 12 |
| #31 | Standings page | DONE | 6 |
| #32 | Knockout Bracket page | DONE | 6 |
| #33 | Tournament Leaderboard page | DONE | 6 |
| #34 | Routing integration | DONE | 0 (routing) |

**Total:** 622 Flutter tests passing, 122 server tests passing. All 6 tournament screens implemented with TDD.

**Deferred from Phase 2.5 (to Phase 3):**
- Super over (requires scoring engine)
- Standings update on match completion (requires match completion flow)
- Tournament leaderboard data (requires completed matches with stats)
- Drift tournament tables for offline caching (YAGNI — no current code needs them)

### Phase 2 Progress (COMPLETE)

| Issue | Title | Status | Commit |
|-------|-------|--------|--------|
| #12 | Teams list page | DONE | (in #30) |
| #13 | Team detail page | DONE | (in #29) |
| #14 | Create team page | DONE | (in #28) |
| #15 | Team service + API endpoints | DONE | (earlier) |
| #16 | Create Team page | DONE | `84eb7aa` |
| #17 | Team Detail page | DONE | `2184582` |
| #18 | Manage Roster + Add Player pages | DONE | `3ec6696` |
| #19 | Match API: creation, toss, playing XI | DONE | `1b60372` |
| #20 | Match domain entities and data layer | DONE | `6fcee62` |
| #21 | Match Setup page | DONE | `4848b68` |
| #22 | Toss page with 5-step wizard | DONE | `fc8f3b7` |
| #23 | Drift local DB + offline caching | DONE | `25b93b5` |
| #24 | Phase 2 routing integration | DONE | `5286469` |

**Phase 2 COMPLETE.** Phase 2.5 (Tournaments) also COMPLETE. Next: Phase 3 (Scoring Engine).

### Issue #24 Completion Summary

Phase 2 routing and navigation integration (2 new tests, 408 total passing):

**Router changes (router.dart):**
- Added `matchSetup` (`/match-setup`) and `toss` (`/toss/:matchId`) routes with `AppRoutes` constants
- Added `tossPath(String matchId)` helper method
- MatchSetupPage: wired `onMatchCreated` → navigate to toss, `onNavigateToCreateTeam` → push create team
- TossPage: receives match/team data via `extra` map, `onStartMatch` → navigate to home (scoring placeholder for Phase 3)
- 15 total routes (was 13)

**Home page wiring (home_page.dart):**
- "Start Match" → `context.push(AppRoutes.matchSetup)`
- "Create Team" → `context.push(AppRoutes.createTeam)`
- "Tournament" → `context.go(AppRoutes.tournaments)` (switches to Tournaments tab)

**Navigation flows verified:**
- Home → Start Match → Match Setup → Toss → Home (scoring placeholder)
- Home → Create Team → Create Team page (pop back)
- Home → Tournament → Tournaments tab (bottom nav switch)
- Teams tab → Team Detail → Manage Roster → Add Player (pre-existing)

### Issue #23 Completion Summary

Drift local database setup + basic offline caching (70 new tests, 406 total passing):

**Database infrastructure (shared/data/database/):**
- 8 Drift tables mirroring PostgreSQL: users, teams, team_rosters, matches, match_players, ball_types + 2 local-only: sync_queue, local_preferences
- `AppDatabase` with ball_types seeding (leather, tennis, tape, other) via `InsertMode.insertOrIgnore`
- `TeamsDao` with upsert, batch insert, get-by-id, roster join queries, roster delete
- `database_provider.dart` exposing `databaseProvider` + `teamsDaoProvider`

**Offline caching (teams feature):**
- `TeamLocalDatasource`: cacheTeams, cacheTeamDetail (with roster + user profiles), getCachedTeams, getCachedTeamDetail (with join)
- `TeamRepositoryImpl` modified: optional `localDatasource`, cache-on-fetch, fallback-on-failure pattern
- `providers.dart`: teamLocalDatasourceProvider (nullable, null if DB not initialized)

**DRY improvement:**
- Added `apiValue` + `fromApiValue()` to `PlayerRole`, `BattingStyle`, `BowlingStyle` enums in `app_user.dart` (matches existing `RosterRole` pattern)
- Removed 4 duplicate parse functions from `team_model.dart` and `team_local_datasource.dart`

**Tests:** 35 database + 14 DAO + 11 local datasource + 8 repository caching = 68 new tests (+ 2 existing = 70 delta)

### Issue #22 Completion Summary

Toss page with 5-step wizard (85 tests, TDD workflow):

**Domain layer (toss_notifier.dart):**
- TossStep enum (5 steps: tossWinner, decision, xiTeamA, xiTeamB, openers)
- RosterPlayer lightweight class (playerId, displayName, playerRole, isCaptain, isKeeper + initials/badge getters)
- TossState class: step navigation, canProceed validation per step, team derivation (4 toss combinations), battingXI/fieldingXI computed lists, auto-pre-selection (roster.length == playersPerSide), sentinel-based copyWith for nullable fields, toRecordTossInput/toSetPlayingXIInput API conversions

**Presentation (toss_page.dart):**
- StatefulWidget with 5-step toss wizard: compact stepper (24px circles), team card selection, Bat/Field toggle, Playing XI checkbox lists, opener selection with striker radio, bowler selection
- Back/Next/Start Match button navigation

**Tests:** 68 notifier + 17 page = 85 tests. 336 total tests passing.

### Issue #21 Completion Summary

Match Setup page (48 tests, TDD workflow) — form for creating new matches with team selection, format/overs/ball type, venue, date, players per side, advanced settings. Connected to match repository for creation.

### Issue #20 Completion Summary

Match domain entities and data layer (62 tests, TDD workflow):

**Domain layer:**
- `match.dart`: MatchStatus (6 states), TossDecision (bat/field with bowl API mapping), MatchFormat (t20/odi/test/custom), Match entity (22 fields, computed: title, effectiveMaxOversPerBowler, formatLabel, isLive, isCompleted, isTournamentMatch), PlayingXIEntry (with badge: C/WK/C&WK), Match validation (overs 1-50, players 2-11, different teams)
- `match_repository.dart`: MatchListResult, CreateMatchInput, RecordTossInput, SetPlayingXIInput DTOs + abstract MatchRepository (5 methods)

**Data layer:**
- `match_model.dart`: Freezed MatchModel/PlayingXIModel with toEntity() extensions
- `match_remote_datasource.dart`: Dio HTTP for all 5 match endpoints (create, list, detail, playing XI, toss)
- `match_repository_impl.dart`: Converts domain types (MatchFormat.apiValue, TossDecision.apiValue)
- `providers.dart`: Riverpod providers (datasource, repository, matchDetail, matchesList)

### Phase 1 Progress (COMPLETE)

| Issue | Title | Status | Commit |
|-------|-------|--------|--------|
| #1 | Project initialization (Flutter + Bun scaffolds) | DONE | `3614d8e` |
| #2 | PostgreSQL + Drizzle schema + seed data | DONE | `cd3bdb1` |
| #3 | Firebase Auth setup + server middleware | DONE | `5cd261f` |
| #4 | M3 Light theme + go_router + auth guards | DONE | `0771dbb` |
| #5 | Splash screen | DONE | `fd21c7d` |
| #6 | Login page | DONE | `eeeeb64` |
| #7 | OTP verification page | DONE | `981f71b` |
| #8 | Profile setup page | DONE | `3e14ca0` |
| #9 | Home page (dashboard) | DONE | `24c3a40` |
| #10 | Bottom navigation shell | DONE | (part of #4) |
| #11 | Match history page (empty state) | DONE | `3ae9da9` |

**Phase 1 stats:** 65 Flutter tests pass, 54 server tests pass. 11 issues closed.

### Issues #5-#11 Completion Summary (Auth + Home Screens)

All presentation-layer screens built with TDD (RED tests first, then GREEN implementation):

**Issue #5 — Splash screen (`splash_page.dart`):**
- Cricket ball icon (`CricketBallIcon` custom painter), two-tone "CricApp" title (`Text.rich`), tagline, loading spinner
- 4 tests pass

**Issue #6 — Login page (`login_page.dart`):**
- Phone input with country code picker (20 cricket nations), Indian phone validation (`^[6-9]\d{9}$`), Send OTP button
- `CricketBallIcon` extracted to `shared/widgets/` (DRY — second use case from splash)
- 10 tests pass

**Issue #7 — OTP verification (`otp_page.dart`):**
- 6-digit OTP input with auto-advance, 30s countdown timer, masked phone display, auto-verify on completion
- 8 tests pass

**Issue #8 — Profile setup (`profile_setup_page.dart` + `app_user.dart`):**
- Domain entity: `AppUser` with `PlayerRole` (4), `BattingStyle` (2), `BowlingStyle` (9) enums
- Form: display name, playing role dropdown, batting style choice chips, bowling style dropdown, location
- CircleAvatar with dynamic initials, validation (name 2-50 chars + role required)
- 21 tests pass (11 domain + 10 presentation)

**Issue #9 — Home dashboard (`home_page.dart`):**
- SliverAppBar with two-tone title + search, quick actions (Start Match, Create Team, Tournament), Recent Matches section with empty state card, pull-to-refresh
- 5 tests pass

**Issue #10 — Bottom navigation shell:** Already implemented in Issue #4 (`_AppShell` in `router.dart`)

**Issue #11 — Match history (`match_history_page.dart`):**
- AppBar "Matches", empty state (cricket icon, "No matches yet", "Start a Match" CTA), pull-to-refresh
- Router updated: `_PlaceholderPage('Matches')` → `MatchHistoryPage()`
- 5 tests pass

**Router state after Phase 1:** Real pages for splash, login, otp, profileSetup, home, matches. Remaining placeholders: tournaments, teams, profile (Phase 2+).

### Issue #4 Completion Summary

M3 Light theme + go_router + auth guards:

**Theme:** Already complete from Issue #1 — `app_theme.dart` (M3 light, seed #1976D2, Roboto), `app_colors.dart` (9 semantic scoring colors), 8dp spacing in `app_constants.dart`, portrait lock in `main.dart`.

**Router (`app/router.dart`):**
- `GoRouter` with auth-based redirect logic
- 9 routes: splash, login, otp, profile-setup + 5 shell tabs (home, matches, tournaments, teams, profile)
- `ShellRoute` with `NavigationBar` (5 destinations: Home, Matches, Tourneys, Teams, Profile)
- Auth guard: loading → splash, unauthenticated → login, authenticated on auth route → home
- `AppRoutes` class with all route path constants
- `NoTransitionPage` for tab switches (no animation between tabs)
- Placeholder pages for all routes (replaced in later issues)

**Providers (`app/providers.dart`):**
- `firebaseAuthDatasourceProvider` — singleton instance
- `authStateProvider` — `StreamProvider<User?>` wrapping Firebase auth state

**App (`app/app.dart`):** Switched from `MaterialApp` to `MaterialApp.router` with `routerConfig`.

**Tests:** 12 Flutter tests pass (4 new router tests + 7 auth + 1 widget).

### Issue #3 Completion Summary

Firebase Auth (Phone OTP) + server middleware:

**Server (apps/server/):**
- `src/config/firebase.ts` — Firebase Admin SDK init (lazy, from service account JSON)
- `src/middleware/auth.ts` — JWT verification middleware (derives `firebaseUser` from Bearer token)
- `src/middleware/error-handler.ts` — Global error handler (`AppError` class, `.as('global')` for Elysia propagation)
- `src/middleware/cors.ts` — CORS middleware (allow * for MVP, OPTIONS preflight)
- `src/services/auth.service.ts` — User CRUD (`verifyAndGetUser`, `updateProfile`, `getUserByFirebaseUid`)
- `src/routes/v1/auth.ts` — `POST /auth/verify` (token verify + user upsert), `PUT /auth/profile` (with TypeBox validation)
- `src/routes/v1/health.ts` — Updated with version, uptime, database connectivity check
- `src/types/auth.ts` — Shared `FirebaseUser` interface
- `src/index.ts` — Wired all middleware and routes, calls `initFirebase()`

**Flutter (apps/mobile/):**
- `lib/main.dart` — Added `Firebase.initializeApp()` before runApp
- `lib/src/features/auth/data/datasources/firebase_auth_datasource.dart` — Phone OTP methods: `sendOtp()`, `verifyOtp()`, `signOut()`, `getIdToken()`, `authStateChanges` stream, `SmartAuth` SMS auto-read integration
- `android/settings.gradle.kts` — Added Google Services plugin
- `android/app/build.gradle.kts` — Applied Google Services plugin

**Firebase project:** `cricapp-7403d`, package `com.cricapp.cricapp`
- `google-services.json` at `apps/mobile/android/app/` (gitignored)
- `firebase-service-account.json` at `apps/server/` (gitignored)
- Both credential files added to `.gitignore`

**Tests:** 54 server tests pass (14 new: error handler, CORS, auth service), 8 Flutter tests pass (7 new: auth datasource)

**Elysia error handler note:** `.as('global')` is required on the error handler plugin to propagate `onError` to routes defined on the parent Elysia instance. Without it, errors thrown in route handlers bypass the plugin's `onError`.

### Issue #2 Completion Summary

PostgreSQL database + Drizzle ORM schema + seed data:

**Database setup:**
- Created `cricapp_user` and `cricapp_dev` database on local PostgreSQL 16.8
- `.env` file configured with real credentials
- `.mcp.json` updated with cricapp_dev connection

**Schema (8 files in `apps/server/src/db/schema/`):**
- `master-data.ts` — 4 tables: ball_types, dismissal_types, fielding_positions, wagon_wheel_zones
- `users.ts` — 1 table: users (UUID PK, firebase_uid UNIQUE)
- `teams.ts` — 2 tables: teams, team_rosters (unique team+player)
- `matches.ts` — 4 tables: matches, match_players, match_result, match_analytics
- `innings.ts` — 2 tables: innings, overs (super over support)
- `deliveries.ts` — 3 tables: deliveries (29 cols, 6 indexes), wickets_by_delivery, fall_of_wickets
- `stats.ts` — 4 tables: batting_stats, bowling_stats, fielding_stats, player_career_stats
- `tournaments.ts` — 6 tables: tournaments + teams/groups/fixtures/standings/requests
- **Total: 26 tables** (DATABASE.md header says 28 but actual table definitions count to 26)

**Migrations:** 2 SQL files generated and applied (initial schema + unique constraints on master data)

**Seed data:** 43 records across 4 master tables (idempotent via onConflictDoNothing + unique constraints):
- 4 ball types (leather, tennis, tape, other)
- 11 dismissal types (with requires_fielder and requires_bowler_credit flags)
- 16 fielding positions (with codes)
- 12 wagon wheel zones (30-degree segments, OF1-OF6 + ON1-ON6)

**Tests:** 40 tests pass (31 schema validation + 9 seed data)
- `test/db/schema-validation.test.ts` — Table count, column presence, critical fields
- `test/db/seed.test.ts` — Record counts, flag correctness, angle values

**Design note:** `matches.tournament_id` is a plain UUID column without FK constraint (avoids circular import between matches.ts and tournaments.ts). The partial index `idx_matches_tournament` is defined. The FK can be added via raw SQL migration if needed.

### Issue #1 Completion Summary

Both projects scaffolded with full folder structure from `.claude/rules.md`:

**Flutter (apps/mobile/):**
- 7 feature modules (auth, scoring, analytics, player_profile, teams, tournaments, home)
- Clean architecture per feature (data/domain/presentation layers)
- M3 light theme (seed #1976D2), semantic scoring colors
- Core: validators, cricket_utils, app/cricket constants, exceptions
- Dependencies: Riverpod 3.1, Freezed 3.1, Drift 2.31, go_router 17.1, Firebase Auth 6.1
- minSdkVersion=23, flutter analyze clean, smoke test passing

**Bun server (apps/server/):**
- ElysiaJS 1.4 + Drizzle ORM 0.38 + postgres.js 3.4
- Directory structure: config/, db/, routes/v1/, services/, websocket/, middleware/, types/, utils/
- Environment validation (12 env vars), database config, health endpoint
- TypeScript strict mode, tsc --noEmit passes

**Bun installed** at `C:\Users\Administrator\.bun\bin\bun.exe` (v1.3.9). Must set PATH: `export PATH="$PATH:/c/Users/Administrator/.bun/bin"`

**Per-directory CLAUDE.md files** could not be created — deny rule in settings.json blocks any file named `CLAUDE.md`. These can be created manually later.

**CI validators** both pass (flutter-validator.js + server-validator.js). Updated server-validator.js to recognize `config/` directory.

### Review & Quality Feedback System Improvements
7. **Commit-draft pre-verification** — Advisory step warns if tests haven't been run before drafting commit message.
8. **CLAUDE_CODE_CONFIG.md** — Updated: 14 agents, 10 hooks, 16 skills. Added missing hooks 8-10 documentation.

### Best Practices Overhaul Completed (Previous Session)

Infrastructure improvements applied before implementation begins:

1. **TDD Workflow** — PLAYBOOK.md rewritten: 15→17 steps with strict Red-Green-Refactor per layer (Steps 3/5/7 = RED, Steps 4/6/8 = GREEN+REFACTOR). New `/tdd` skill. IMPLEMENTATION_PRACTICES.md Section 13.5 added.
2. **Agent Tuning** — Model optimization: 3 agents downgraded (ui-researcher→haiku, docs-manager→haiku, 3 agents→sonnet), 3 agents upgraded to inherit main model (scoring-researcher, system-architect, debugger). 5 agents now accumulate knowledge in `.claude/agents/memory/`.
3. **Auto-Format Hook** — PostToolUse hook formats .dart (dart format) and .ts (prettier) on every Edit/Write. Skips generated files.
4. **Quality Gate** — Stop hook replaces remind-session-handoff. Checks CONTINUE_PROMPT.md + uncommitted source changes.
5. **Enhanced Compaction** — Reinject hook now includes git state (branch, modified files, staged files) + "What to Do Next" excerpt.
6. **CLAUDE.md Slimmed** — Cricket Domain Rules → 3-line reference (full rules in `.claude/skills/cricket-domain/SKILL.md`). Compaction guidance + hierarchy plan added.
7. **New Skills** — `cricket-domain` (full rules reference), `tdd` (guided TDD). `context: fork` on phase-gate + screenshot-verify.
8. **Agent Preloading** — scoring-researcher, database-researcher, tester now read relevant skills before starting.
9. **Settings** — 5 new allow rules (screenshot, node scripts, mkdir, prettier). 47 total allow rules, 10 hooks.

### Wireframe Review — Current State

**Completed:**
- Group A: Auth Flow (01-splash, 02-login, 03-otp, 04-profile-setup) — DONE
- Group B: Home & Navigation (05-home) — DONE
- Group C: Teams Flow (06-teams-list, 07-create-team, 08-team-detail, 09-manage-roster) — DONE
- Group D: Match Setup (10-match-setup, 11-toss) — DONE
- Group D2: Tournament Flow (19-tournaments-list, 20-create-tournament, 21-tournament-detail, 22-standings, 23-knockout-bracket, 24-tournament-leaderboard) — DONE

**Remaining (in order):**
- **Group F: Post-Match** — 15-scorecard, 16-match-analytics, 17-player-profile, 18-match-history

### Per-Screen Review Process

For each screen:
1. Open `docs/ui/XX-name.html` in Playwright browser (HTTP server on port 9123: `python -m http.server 9123 --directory docs/ui`), take screenshot
2. Read the HTML source
3. Launch 4 agents in parallel (use `sonnet` model for speed):
   - `cricheroes-comparator` — Compare against CricHeroes equivalent screen
   - `planner-researcher` — Technical planning, architecture, implementation concerns
   - `scoring-researcher` — Cricket rules compliance, scoring logic implications
   - `ui-researcher` — M3 light theme, accessibility, widget structure
4. Compile consolidated report with CRITICAL / MEDIUM / LOW issues
5. Apply wireframe edits and doc fixes for approved changes
6. Get user approval before proceeding to next screen/group

### Key Docs to Reference During Review

- `docs/ui/*.html` — All 28 wireframe files
- `docs/ui/styles.css` — Shared CSS variables and components
- `docs/planning/DATABASE.md` — Schema (enums, column names, table relationships)
- `docs/planning/API.md` — Endpoint specs (field names, request/response shapes)
- `docs/planning/SCORING_RULES.md` — Cricket rules, match state machine, delivery pipeline
- `docs/process/CODE_STANDARDS.md` — M3 light theme tokens, UI patterns, design decisions
- `docs/planning/CRICHEROES_REFERENCE.md` — CricHeroes competitive analysis
- `.claude/rules.md` — File placement rules for Flutter implementation

### Changes Applied During Wireframe Review

#### Session 1 — Groups A & B

**Theme change (applies globally):**
- M3 seed color changed from `#2E7D32` (green) to `#1976D2` (blue)
- Updated in: CODE_STANDARDS.md, CONTINUE_PROMPT.md, CRICHEROES_REFERENCE.md

**04-profile-setup.html:**
- Removed photo upload area (deferred per C5 — initials avatar only)
- Fixed playing role dropdown: Batter, Bowler, All-Rounder, WK-Batter (matches DB enums)
- Fixed bowling style dropdown: 9 options matching DATABASE.md (split "Left Arm Spin" into Orthodox + Chinaman)
- Updated location placeholder

**05-home.html:**
- Removed search icon (search deferred to post-MVP)
- Replaced "Catches: 14" with "Avg: 31.8" in My Stats grid
- Added CRR: 8.51 to live match card
- Changed 3rd match to "Match Tied" result (165 vs 165) for result type coverage

**DATABASE.md:**
- `users.display_name`: varchar(100) → varchar(60) (aligns with API 2-50 char validation)
- `users.city` → `users.location` (renamed)
- `teams.city` → `teams.location` (renamed)

**API.md:**
- All `"city":` fields renamed to `"location":` across all endpoints

**CODE_STANDARDS.md:**
- Fixed `player_role` enum: `'keeper'` → `'wk_batter'` (matches DATABASE.md)

#### Session 2 — Group C (Teams Flow)

**CLAUDE.md:**
- Added `bunx tsc --noEmit` to Bun server build commands
- Added Implementation Phases summary section (7 phases, Weeks 1-12)
- Added CI Pipeline section (5 jobs, self-hosted Windows runner)

**06-teams-list.html (5 changes):**
- Removed search icon from header (search deferred to post-MVP)
- Switched from 3-column to 2-column grid (`grid-template-columns: repeat(2, 1fr)`)
- Added role badge (OWNER / CAPTAIN / MEMBER) per card — CSS class `.team-grid-role`
- Added location to meta text: `"11 players · Mumbai"` format
- Replaced empty state emoji `&#x1F465;` with Material icon `data-icon="groups"`

**07-create-team.html (2 changes):**
- Removed Ball Type chip group entirely (ball_type is on `matches` table, not `teams` — confirmed via DATABASE.md and CricHeroes behavior)
- Changed team name `maxlength="30"` → `maxlength="50"` (matches API validation rule G11: 2-50 chars)

**08-team-detail.html (6 changes):**
- Changed subtitle from `"Leather Ball · 11 Players"` to `"Mumbai · 11 Players"` (ball type not a team attribute)
- Changed stats card from 3-column (Matches/Wins/Losses) to 4-column (Matches 12/Wins 8/Losses 3/Tied 1) — covers all result types
- Fixed all-rounder descriptions: `"Right Fast"` → `"Right Hand Bat · Right Arm Fast"`, `"Left Spin"` → `"Left Hand Bat · Left Arm Orthodox"` (show both batting + bowling style)
- Fixed WK section: header `"Wicketkeeper"` → `"WK-Batters"`, role `"Right Hand Bat"` → `"WK-Batter · Right Hand Bat"`
- Fixed bowler descriptions to match DB enums: `"Right Fast"` → `"Right Arm Fast"`, `"Right Medium"` → `"Right Arm Medium"`, `"Left Spin"` → `"Left Arm Orthodox"`, `"Off Break"` → `"Right Arm Off Spin"`
- Replaced empty state emojis: `&#x1F4CB;` → `data-icon="scoreboard"`, `&#x1F464;` → `data-icon="person_add"`

**09-manage-roster.html (7 changes):**
- Removed inline `#addPlayerModal` (conflicts with dedicated `28-add-player.html` page — "Add Player" button correctly navigates there)
- Fixed role labels: `"Batsman"` → `"Batter"`, `"Wicketkeeper"` → `"WK-Batter"` (matches DB enum display convention established in screen 08)
- Fixed all bowling style descriptions to match DB enums: `"Right Fast"` → `"Right Arm Fast"`, `"Right Medium"` → `"Right Arm Medium"`, `"Left Spin"` → `"Left Arm Orthodox"`, `"Off Break"` → `"Right Arm Off Spin"`
- All-rounder subtitles now show both batting + bowling style: `"All-rounder · Right Hand Bat · Right Arm Fast"`
- Added captain `C` badge on Arjun Mehta (CricHeroes ADOPT — `team_rosters.role = captain`)
- Added `WK` badge on Nikhil Verma (CricHeroes ADOPT — indicates designated keeper)
- Increased remove button touch target from 32px → 40px (closer to 48dp minimum per E3)

#### Session 3 — Group D (Match Setup)

**10-match-setup.html (6 changes):**
- Added `players_per_side` field: number input (range 2-11) with preset chips (6, 8, 11) — critical for scoring engine all-out threshold
- Added tournament rule locking (T9): when tournament selected, all inherited fields show "Locked by tournament" badges and are disabled (overs, ball_type, players_per_side, plus advanced settings)
- Expanded overs presets from 4 to 6: added 15 and 25 (5, 10, 15, 20, 25, 50)
- Added Match Date field with `type="date"` defaulting to today
- Added collapsible Advanced Settings panel: wide_runs, no_ball_runs, max_overs_per_bowler, powerplay_overs (with tournament locking support)
- Replaced empty state emoji with Material icon `data-icon="groups"`

**11-toss.html (full rewrite, 8 changes):**
- Expanded from 3-step to 5-step stepper: Toss > Choice > XI-A > XI-B > Openers (G19 Playing XI embedded in toss flow)
- Added Playing XI selection steps for both teams (Steps 3-4): full roster lists with checkboxes, "X / 11 selected" counters, players_per_side validation
- Changed "Bowl" to "Field" for toss decision (correct cricket terminology)
- Added striker designation prompt: after selecting 2 openers, "Who will face the first ball?" radio selection (matches API `openingStrikerId`/`openingNonStrikerId`)
- Added Back button for step navigation (visible on steps 2-5)
- Fixed all role labels: "Batsman" to "Batter", "Wicketkeeper" to "WK-Batter", "All-rounder" to "All-Rounder"
- Fixed bowling style labels: "Right Fast" to "Right Arm Fast", "Right Medium" to "Right Arm Medium", plus full enum labels
- Added compact stepper CSS overrides for 5 steps to fit phone frame width
- Replaced emoji icons with Material icons (`data-icon="sports_cricket"`, `data-icon="sports"`)
- Increased player row padding to 12px for 48dp touch targets
- CTA button shows "Start Match" on final step

#### Session 4 — Group D2 (Tournament Flow)

**19-tournaments-list.html (5 changes):**
- Removed search icon from header (search deferred to post-MVP)
- Added location to card subtitle: `"8 Teams · Mumbai"` format
- Changed "Upcoming" badge to use outlined style for visual hierarchy
- Replaced empty state emoji `&#x1F3C6;` with Material icon `data-icon="trophy"`
- Added pull-to-refresh hint text below list

**20-create-tournament.html (7 changes):**
- Added `maxlength="100"` to tournament name input
- Expanded overs presets from 4 to 6: added 15 and 25 (5, 10, 15, 20, 25, 50)
- Added Match Rules section (T9 template fields): players_per_side, max_overs_per_bowler, wide_runs, no_ball_runs, powerplay_overs — all with stepper controls
- Added Match Schedule section (T13): default start time, match duration (stepper, minutes), gap between matches (stepper, minutes)
- Increased stepper button size from 32px → 40px for touch targets
- Show/hide Points System and Group Stage Settings sections based on format selection (knockout hides both, round_robin hides groups)
- Added `chip-change` custom event listener for format conditional visibility

**21-tournament-detail.html (6 changes):**
- Changed settings gear icon to overflow menu: `data-icon="settings"` → `data-icon="menu"` (contextual entity actions, not global settings)
- Fixed match count: `12` → `15` in hero stats (8-team Group+KO = 12 group + 2 semi + 1 final)
- Added L column to standings mini-table (Team/P/W/L/Pts/NRR) — differentiates 2W-0L-1T from 2W-1L
- Changed `btn btn-outline btn-sm` → `btn btn-outline` for Bracket/Leaderboard quick link buttons
- Added 3 hidden empty states for Overview ("No Upcoming Matches"), Fixtures ("No Fixtures Yet"), Teams ("No Teams Registered") tabs

**22-standings.html (4 changes):**
- Added tournament context bar between header-tabs and content: `<div class="tournament-bar">Weekend Warriors Cup</div>`
- Fixed qualified badge font-size: `9px` → `var(--caption-sm)` across all 4 qualified badges
- Replaced empty state emoji `&#x1F4CA;` with `data-icon="leaderboard"` SVG pattern
- Added `leaderboard` SVG icon to app.js ICONS object

**23-knockout-bracket.html (5 changes):**
- Added tournament context bar with `.tournament-bar` CSS and HTML
- Replaced trophy emoji `🏆` with `data-icon="trophy"` SVG pattern in winner section
- Added overs to bracket scores: `187/6` → `187/6 (20.0)`, `172/9` → `172/9 (20.0)`
- Added result summary below SF1 match card: "MW won by 15 runs"
- Added empty state: "Bracket Not Ready" with trophy icon for pre-group-stage state

**24-tournament-leaderboard.html (3 changes):**
- Replaced empty state emoji `&#x1F3C5;` with `data-icon="trophy"` SVG pattern
- Fixed Batting Avg detail: `"245 runs, 3 inn"` → `"245 runs, 3 dis"` (batting average = runs/dismissals, NOT runs/innings)
- Fixed Economy detail: `"6 wkts, 12 ov"` → `"70 runs, 12 ov"` (economy = runs conceded/overs, wickets are irrelevant context)

#### Session 5 — Group E (Scoring Flow)

**13-wicket-dialog.html (no changes needed):**
- Reviewed by 3 agents (cricheroes-comparator, scoring-researcher, ui-researcher). All terminology, dismissal types, fielder selection, run out details already correct per DB enums and SCORING_RULES.md.

**14-extras-panel.html (no changes needed):**
- Reviewed by 3 agents. Extra types, additional runs selector, wicket-on-extra toggle, and total runs calculation all match SCORING_RULES.md pipeline. Bye/leg-bye correctly hide wicket section.

**26-match-complete.html (4 changes):**
- Fixed team avatar size: `48px` → `56px` (matches `.avatar.lg` design token)
- Standardized footer: custom `.match-complete-actions` → `.modal-footer` with `flex-direction: column; gap: 8px`
- Super Over button changed from `btn-outline` → `btn-primary` (primary CTA for tied knockout)
- JS toggle function updated: swaps View Scorecard to `btn-outline` when tied knockout state active

**27-super-over-setup.html (8 changes):**
- Fixed touch targets: `.player-check-row` and `.player-radio-row` padding `10px` → `14px 12px` (48dp compliance)
- Fixed terminology: "Batsman" → "Batter" (replace_all), "Wicketkeeper" → "WK-Batter" (replace_all)
- Fixed bowling styles: "Right Fast" → "Right Arm Fast", "Left Spin" → "Left Arm Orthodox" (full DB enum labels)
- Added batting order info bar above stepper: "Mumbai Warriors bat first (chased in regulation)"
- Updated Step 3 description: "Select 3 batters and 1 bowler." → "Select 3 batters, designate striker, and select 1 bowler."
- JS `toggleSOCheck()` updated with max-3 batter enforcement (auto-deselect oldest when 4th selected)

**28-add-player.html (3 changes):**
- Fixed role chips: "Batsman" → "Batter" with `data-value="batter"`, "Wicketkeeper" → "WK-Batter" with `data-value="wk_batter"`, "allrounder" → `data-value="all_rounder"`
- Fixed bowling style chips: replaced 6 abbreviated labels with full 9-value DB enum (right_arm_medium, right_arm_fast, right_arm_off_spin, right_arm_leg_spin, left_arm_fast, left_arm_medium, left_arm_orthodox, left_arm_chinaman, none)
- Fixed search result bowling label: "Right Medium" → "Right Arm Medium"

### Implementation Notes (Logged During Review, No Wireframe Changes)

- **Pull-to-refresh**: ADOPT on all list screens (`RefreshIndicator` wrapper, trivial)
- **Empty states**: Use per-section empty states on Home, not one generic full-page state
- **My Stats on Home**: Show 0 values until Phase 5 career stats are built
- **Bottom nav "Tourneys"**: Test label truncation on 320dp width devices during implementation
- **Live match card (2nd innings)**: Show "Need X from Y balls" + RRR (already planned per CH-29)
- **Profile setup**: Reused for Edit Profile (pre-filled via route params)
- **All match result types**: Implementation must handle: won by runs, won by wickets, Match Tied, No Result, Won in Super Over
- **Ball type is match-level, NOT team-level**: `ball_type_id` exists on `matches` table only — removed from team create/detail screens
- **Tournament rule locking (T9)**: Match setup fields inherited from tournament must be visually locked and non-editable. 5 fields: players_per_side, max_overs_per_bowler, wide_runs, no_ball_runs, powerplay_overs + overs and ball_type
- **Playing XI embedded in toss flow (G19)**: Steps 3-4 of toss stepper, not a separate screen. Checkbox list from roster, validated against players_per_side
- **Striker/non-striker distinction required**: API toss endpoint requires `openingStrikerId` and `openingNonStrikerId` — toss UI must collect "Who will face the first ball?" after selecting 2 openers
- **5-step toss stepper compact CSS**: When stepper has 5+ steps, use smaller step numbers (24px), shorter labels (10px), and reduced connector width (12px min, 4px margin) to fit phone frame
- **Bowling style display convention**: Always use full DB enum label format: "Right Arm Fast" not "Right Fast", "Left Arm Orthodox" not "Left Spin", "Right Arm Off Spin" not "Off Break"
- **Role display convention**: Use "Batter" (not "Batsman"), "WK-Batter" (not "Wicketkeeper") — consistent with DB enum `player_role` values
- **Captain/keeper badges**: Show (C) and (WK) badges next to player names on roster/team screens
- **Tournament context bar**: Sub-screens (standings, bracket, leaderboard) need a `.tournament-bar` showing tournament name for navigation context
- **Match count for Group+KO**: 8 teams, 2 groups of 4 = C(4,2)×2 = 12 group matches + 2 semi-finals + 1 final = 15 total
- **Batting average formula**: runs/dismissals (NOT runs/innings) — standard cricket convention
- **Economy detail context**: Show runs conceded + overs bowled (not wickets — wickets are irrelevant to economy rate)
- **Tournament leaderboard MVP**: No `tournament_player_stats` table needed — aggregate on-the-fly from `batting_stats`/`bowling_stats` filtered by tournament_id join through matches
- **Empty state icon convention**: Use `data-icon` SVG pattern throughout (not emoji characters) for consistent rendering across devices
- **Format conditional sections**: On Create Tournament, Knockout hides both Points System and Group Stage Settings; Round Robin hides Group Settings only; Group+KO shows both

---

**After wireframe review is complete**, proceed with Phase 1 implementation:

1. Initialize Flutter project (`apps/mobile/`) with the folder structure from Section 2.1
2. Initialize Bun server (`apps/server/`) with the folder structure from Section 2.2
3. Set up PostgreSQL + Drizzle schema using tables from `docs/planning/DATABASE.md`
4. Seed master data (dismissal types, fielding positions, wagon wheel zones, ball types)
5. Set up Firebase project + configure Flutter Firebase
6. Implement Firebase Auth (Phone OTP only — no Google/Email for MVP)
7. Implement auth middleware on Bun (Firebase JWT verification)
8. Set up Material 3 light theme (seed color `#1976D2`)
9. Set up go_router with auth guards
10. Build screens: Splash, Login, OTP, Profile Setup

**GitHub MCP not yet configured.** Run `claude mcp add --scope user` to add the GitHub MCP server with a personal access token (scopes: `repo`, `workflow`).

**PostgreSQL MCP configured.** `.mcp.json` has real cricapp_dev credentials. Restart Claude Code to pick up changes if MCP auth fails.

## Key Design Decisions Already Made

- Ball-by-ball granularity (every delivery stored)
- UUIDs for all primary keys (sync-friendly)
- 12-zone wagon wheel system (30-degree segments)
- Pre-computed stats per innings + career aggregates
- JSONB for graph data in match_analytics
- Offline-first with sync queue in local SQLite
- Scorer = publisher, viewers = subscribers in WebSocket rooms
- Anonymous WebSocket viewers (no auth required for read-only)
- Free hit tracking on no-balls; free hit persists through wides
- Byes/leg-byes don't break maidens
- Standalone tied match → COMPLETED with "Match Tied"; knockout tournament tied match → Super Over (see T14)
- No DLS calculations or shot types tables (deferred / not needed for MVP)
- Partnerships deferred to post-MVP (compute from deliveries later)
- Teams use soft delete (`is_active` boolean)
- WebSocket heartbeat via protocol-level ping/pong (30s interval, 5s timeout)
- Sync ordering: match → innings → deliveries → stats
- Server-wins conflict resolution (silent overwrite)
- Local ID → server ID mapping table (no mass FK updates)
- Offset-based pagination (`?page=1&limit=20`) on all endpoints
- Every table has `created_at` + `updated_at`
- `match_players` table for Playing XI (replaces inline approach)
- `innings_stats` dropped — 3 computed columns moved to `innings` table
- Firebase JWT directly (no server-issued JWT)
- scorer_id lock for concurrent scoring prevention
- Scorer picks crossed/not-crossed explicitly on run out
- Wicket on last ball order: Wicket → New Batter → New Bowler
- Bowler over limit: `ceil(totalOvers / 5)` per bowler
- Declaration behind "Set" button; abandonment stats DO count in career
- 5-run penalty supported with full UI flow
- Custom run input (overthrows) + custom extras input
- M3 light theme: seed color #1976D2, Roboto, Material Symbols, portrait lock
- 8dp grid spacing system, M3 default transitions only
- Scoring page: fixed header (top) + scrollable middle + fixed buttons (bottom)
- Initials-only avatar for MVP; simple file picker for team logo (no crop)
- Minimal settings in Profile (logout + app version)
- Single login screen: Phone OTP only (no tabs — single auth flow)
- Home dashboard: recent matches, quick actions, my stats card
- Deployment: existing VPS (Win Server 2022, PostgreSQL 16.8, Nginx, PM2, Cloudflare, GitHub Actions)
- WebSocket delivery message matches REST fields; reconnect via REST snapshot (no replay)
- `total_runs` computed at application level; overs decimal notation utility on both platforms
- **[Q1]** Flutter minSdkVersion = API 23 (Android 6.0) — covers 97%+ Indian devices
- **[Q2]** Extra dependencies: flutter_secure_storage, image_picker, logger, firebase_crashlytics
- **[Q3]** Bun server development port = 3000 (Nginx reverse proxies to this)
- **[Q4]** Firebase project: user provides google-services.json + service account key; we write integration code
- **[Q5]** `is_penalty boolean default false` added to deliveries table for 5-run penalties
- **[Q6]** Free hit tracked in ScoringState (Riverpod) only — `isFreeHitPending` in Freezed state, no DB column
- **[Q7]** Materialized view SQL written in Phase 5 when career stats are built
- **[Q8]** Sync retry count = 5 with exponential backoff (5s→10s→30s→60s→60s)
- **[Q9]** local_preferences keys: `last_sync_timestamp`, `current_match_id`, `user_id`, `last_viewed_team_id`, `app_version_seen`
- **[Q10]** Run out wicket dialog has "Direct Hit?" toggle → populates `fielding_stats.direct_hits`
- **[Q11]** MVP tie-breaker: share the rank (joint placement), next rank skips
- **[Q12]** "Set" menu has "Reopen Last Innings" and "Reopen Match" options (contextual)
- **[Q13]** Auth is **Phone OTP only** — no Google, no Email for MVP
- **[Q14]** "Set" button menu: 6 items (Declare Innings, Abandon Match, 5-Run Penalty, Bowler Injured, Reopen Last Innings, Reopen Match)
- **[Q15]** Scoring button sizes: Run 56x56dp circular, Extras 48x40dp rect, Wicket 56x56dp red, Other 48x48dp, Action bar 40x40dp
- **[Q16]** Connectivity dot: 8dp in score header top-right (green/yellow/red)
- **[Q17]** Offline error handling: log + dot color change only — no dialogs/toasts/banners during scoring
- **[Q18]** Sync retry_count persists across restarts (stored in SQLite sync_queue, never reset on relaunch)
- **[T1]** Tournament formats: Round-Robin, Knockout, Group Stage + Knockout (all three supported)
- **[T2]** Points system: Configurable per tournament (default ICC: W=2, T=1, NR=1, L=0)
- **[T3]** Fixture scheduling: Auto-generate + manual edit
- **[T4]** Qualification: Configurable top-N per group, auto-seeded knockout brackets (A1 vs B2, B1 vs A2)
- **[T5]** Tiebreaker order: Points → NRR → Head-to-head → Joint rank (fixed, not configurable)
- **[T6]** Roles: Creator = organizer (no additional roles for MVP)
- **[T7]** Stats: Tournament-scoped leaderboards (top scorers, wicket takers, batting avg, economy)
- **[T8]** Timeline: New Phase 2.5 after Teams (Phase 2), before Scoring Engine (Phase 3)
- **[T9]** Tournament as match rules template: 5 new config fields (players_per_side, max_overs_per_bowler, wide_runs, no_ball_runs, powerplay_overs). Tournament matches inherit locked rules; standalone matches use defaults.
- **[T10]** Open team registration with organizer approval: new tournament_requests table (pending/approved/rejected). Team captain initiates, organizer approves/rejects. Direct-add by organizer also kept.
- **[T11]** Roster size validation at registration: team must have at least players_per_side members in roster to register or be added.
- **[T12]** Match created when scorer starts (not at fixture generation): fixture has match_id=NULL until scorer taps "Start Match", then match record is created inheriting tournament rules.
- **[T13]** Time-of-day scheduling: scheduled_time (time) + estimated_duration_minutes (integer) added to tournament_fixtures alongside existing scheduled_date. Venue conflict detection (warning only, non-blocking).
- **[T14]** Super over for knockout ties: triggered when knockout match ends tied. 1 over per side, 3 batters, 2-wicket limit. Repeat if tied again (sudden death with different bowlers). Result type = "super_over".
- **[T15]** Super over stats excluded from career stats and tournament leaderboard; count only toward match result.
- **[T16]** Leaderboard stays at 4 categories: runs, wickets, batting_avg, economy (no change from T7).

### Round 4 Final Gap Analysis (A1-A5, B1-B5, C1-C6, D1-D3, E1-E3)

**Scoring Engine Logic (A1-A5):**
- **[A1]** Undo scope: blocked after transition — undo available only before new batter confirmed or new bowler confirmed.
- **[A2]** Penalty delivery fields: bowler_id = NULL, ball_number = 0, over_number = current over. Penalty runs don't affect bowler economy.
- **[A3]** Super over UI trigger: auto-trigger with confirmation. Knockout tie → Match Complete modal shows "Start Super Over" button. Standalone tie → COMPLETED "Match Tied" (no super over).
- **[A4]** Bowler mid-over replacement (ICC Law 22.7): any bowler not at max overs qualifies; previous-over bowler CAN replace; replacement cannot bowl NEXT over; injured bowlers excluded.
- **[A5]** 5-run penalty direction: both directions supported. UI toggle "Awarded to Batting/Fielding team". Batting team penalty → current innings extras. Fielding team penalty → other team's innings total.

**UI Flows — Missing Prototypes (B1-B5):**
- **[B1]** Select New Batter: single-tap bottom sheet list. Title "Select New Batter" + "Replacing: [name]". Player name + batting style + role. Auto-select if only 1 remaining.
- **[B2]** Select Next Bowler: single-tap bottom sheet. Title "Over X+1". Eligible list (O-M-R-W + economy). Ineligible greyed out with reason. Auto-select if only 1 eligible.
- **[B3]** Innings Transition: 3-step stepper. Step 1: 2 opening batsmen (checkboxes). Step 2: 1 opening bowler (radio). Step 3: Confirm + "Start Innings".
- **[B4]** Match Complete: result text + final scores. "View Scorecard" (primary) + "Back to Home" (outlined). No MVP display (shown on scorecard).
- **[B5]** Super Over Setup: 3-step stepper. Step 1: Team A 3 batters + striker/non-striker. Step 2: Team A bowler. Step 3: Team B batters + bowler. Batting order auto-determined (team that batted 2nd goes first).

**Technical Implementation (C1-C6):**
- **[C1]** Sync batching: single POST /api/v1/sync/push with all entity types. Server processes in dependency order. Deliveries > 50 → multiple requests, other entities in first only.
- **[C2]** Sync retry reset: reset to 0 on success. FAILED at retry_count=5. FAILED items retried via pull-to-refresh (resets to 0). Match completion triggers final forced sync attempt. Never auto-reset on restart.
- **[C3]** Date/time format: storage UTC. Display: "d MMM yyyy" + 12h AM/PM. Relative for < 7 days ("Today", "Yesterday", "3 days ago").
- **[C4]** Drizzle migration strategy: removed from MVP scope. Dev: manual `bunx drizzle-kit migrate`. Production strategy deferred to Phase 7.
- **[C5]** Image upload: team logo only (256x256, quality 80%, max 100KB, server rejects > 100KB with 413). Profile photo deferred to post-MVP (initials avatar).
- **[C6]** Package versions: latest stable at time of init. Use `flutter pub add` / `bun add`. pubspec.yaml/package.json versions are minimum targets.

**Infrastructure (D1-D3):**
- **[D1]** Dev API URL: default `http://10.0.2.2:3000/api/v1` (emulator). Override via `--dart-define=API_BASE_URL=...` for physical device. Production URL at Phase 7.
- **[D2]** PostgreSQL: existing VPS PostgreSQL 16.8. DB names: `cricapp_dev` (dev), `cricapp` (prod). Credentials in .env.
- **[D3]** Nginx: new server block file at Phase 7. HTTP proxy + WebSocket upgrade. SSL via Cloudflare. Direct port 3000 for development.

**Cross-Cutting UX (E1-E3):**
- **[E1]** Android back button: scoring page shows confirmation dialog "Match in progress. Exit scoring?" with Stay/Exit. Exit saves locally. Toss/Setup: normal back. Dialogs: dismiss dialog.
- **[E2]** App background/kill recovery: rely on offline-first. Background: WS disconnects, auto-reconnect. Kill: resume from local DB. Brief "Resuming match..." loading.
- **[E3]** Accessibility minimal for MVP: 48x48dp touch targets, M3 light WCAG AA, basic Semantics on scoring buttons, respect system font (except scoring page). Deferred: full screen reader, high contrast, color blind.

### Round 2 Pre-Implementation Audit (Q1-Q25 + AR-1 through AR-14)

**Auto-resolved from cricket laws (AR):**
- **[AR-1]** Caught dismissal: runs before catch DO NOT count (batter gets 0). Law 33.
- **[AR-2]** Hit wicket on no-ball: batter NOT out (no-ball overrides).
- **[AR-3]** Stumped off wide: bowler IS credited with wicket.
- **[AR-4]** Wide + bye: mutually exclusive (wide IS an extra type). Add validation.
- **[AR-5]** Free hit expiry: expires on next LEGAL delivery. Byes/leg-byes on free hit = legal delivery, so free hit consumed.
- **[AR-6]** All-out threshold: `players_per_side - 1` (not hardcoded 10). Flexible team sizes.
- **[AR-7]** ball_number semantics: extras share ball_number with upcoming legal delivery.
- **[AR-8]** Local DB transaction: ALL writes in Step 8 of pipeline must be in single Drift transaction.
- **[AR-9]** Validation: both client (UX speed) and server (authoritative on sync).
- **[AR-10]** Added index on deliveries.sequence_number for performance.
- **[AR-11]** Added unique constraint (innings_id, over_number) on overs table.
- **[AR-13]** "Handled Ball" merged into "Obstructing the Field" per 2017 Laws. Removed from seed data.
- **[AR-14]** Byes/leg-byes do NOT break maidens (already in docs, confirmed).

**Scoring Engine (Q1-Q7):**
- **[Q1]** Mankad: deferred to post-MVP (breaks delivery pipeline assumption, very rare in amateur cricket).
- **[Q2]** Timed Out + Obstructing Field: deferred to post-MVP (keep in DB enum, grey out in wicket dialog).
- **[Q3]** Retired hurt last-man: innings ends if < 2 active batters remain. Retired hurt CAN return, so not permanently unavailable.
- **[Q4]** Configurable wide_runs/no_ball_runs: denormalized to matches table (default 1). Pipeline reads from matches table per-match.
- **[Q5]** 5-run penalty is undoable: reverse penalty_runs from innings total, delete penalty delivery record.
- **[Q6]** ABANDONED matches can be reopened by scorer/organizer if result not finalized. Confirmation dialog shown.
- **[Q7]** Bowler injury mid-over: "Bowler Injured" option in Set menu. Replacement bowler completes remaining balls. Cannot bowl next over.

**Database (Q8-Q11):**
- **[Q8]** 5 new columns on matches table: players_per_side (default 11), max_overs_per_bowler (nullable), wide_runs (default 1), no_ball_runs (default 1), powerplay_overs (nullable). Copied from tournament on creation.
- **[Q9]** sequence_number: client-assigned, monotonically incrementing per innings. Server validates uniqueness on sync.
- **[Q10]** player_career_stats: recalculated server-side when match status → COMPLETED. NOT incremental during scoring.
- **[Q11]** Local SQLite: 16 mirrored tables + 2 local-only (sync_queue, local_preferences). Tournament tables server-only.

**API & Sync (Q12-Q16):**
- **[Q12]** REST-only for scoring writes. WebSocket is broadcast-only (read path). Removed delivery/undo_delivery from WS client-to-server messages.
- **[Q13]** Sync push expanded to all scoring entities: deliveries, innings, battingStats, bowlingStats, fieldingStats, fallOfWickets, overs, matchPlayers, matchResult.
- **[Q14]** Conflict resolution: last-write-wins by updated_at. Server wins. Conflicts[] in sync push response with server versions.
- **[Q15]** Toss endpoint already includes opener selection (openingStrikerId, openingNonStrikerId, openingBowlerId).
- **[Q16]** WebSocket reconnection: server sends full match_state snapshot on join/rejoin. No message queue or replay needed.

**UI/UX (Q17-Q22):**
- **[Q17]** Wagon wheel zone selection deferred to post-MVP. wagonWheelZoneId removed from delivery payload.
- **[Q18]** "More..." button (48x48dp) with number picker (0-12) for overthrow scenarios (5, 7, etc.).
- **[Q19]** Manual strike swap icon button between batter cards. UI-only operation, no delivery record.
- **[Q20]** Viewer mode: same scoring page layout, all scoring controls hidden. Access via "Watch Live" → WebSocket read-only.
- **[Q21]** Add Player dialog: "Search by phone" (find existing user) + "Create new" (placeholder profile claimable later).
- **[Q22]** Bottom nav: 5 tabs — Home, Matches, Tournaments, Teams, Profile.

**Infrastructure (Q23-Q25):**
- **[Q23]** Single Firebase project for MVP (no staging/production split).
- **[Q24]** Light prototypes map directly to M3 light theme (layout/structure/colors match, use M3 tokens per CODE_STANDARDS.md).
- **[Q25]** 12 env vars in .env.example: DATABASE_URL, JWT_SECRET, FIREBASE_SERVICE_ACCOUNT_PATH, PORT, WS_PORT, CORS_ORIGIN, UPLOADS_DIR, MAX_UPLOAD_SIZE_MB, LOG_LEVEL, NODE_ENV, SYNC_BATCH_SIZE, WS_HEARTBEAT_INTERVAL_MS.

### Round 1 Pre-Implementation Gap Resolution (G1-G32)

- **[G1]** FK cascades: RESTRICT (users/teams/matches), CASCADE (parent→children), SET NULL (optional FKs)
- **[G2]** updated_at: application-level on both platforms (Drizzle .$onUpdate, Drift DAO methods)
- **[G3]** Overs table: populated live at over completion (Step 6 of delivery pipeline)
- **[G4]** Super over players: application-level enforcement using match_players, no new tables
- **[G5]** match_analytics JSONB: formal typed interfaces (manhattan_data, worm_data, mvp_scores)
- **[G6]** File upload: VPS filesystem + Nginx static serving, POST /api/v1/uploads/image
- **[G7]** 5 new match endpoints: abandon, declare, reopen, super-over, scorer transfer
- **[G8]** Undo broadcast: delivery_undone WS message with full score/batter/bowler state
- **[G9]** Deliveries pagination: offset-based, inningsId required, default 50, max 100
- **[G10]** CORS: allow * for MVP (irrelevant for mobile, enables future web dashboard)
- **[G11]** Validation: TypeBox schemas with defined rules (phone ^[6-9]\d{9}$, name 2-50 chars, etc.)
- **[G12]** Powerplay: display-only PP badge for MVP, no fielding enforcement
- **[G13]** Overthrows: all runs to batter (bowler concedes); bye/legbye + overthrow stays extras
- **[G14]** 5-run penalty: separate penalty delivery, batting vs fielding team, innings.penalty_runs column
- **[G15]** Run out on wide: total_runs = 1 (wide base) + completed_runs, all as wide_runs
- **[G16]** Declaration: enabled for all formats (amateur cricket flexibility)
- **[G17]** Abandonment in tournaments: No Result, NR points, excluded from NRR, partial stats count
- **[G18]** Match complete: modal dialog (not screen), View Scorecard + Back to Home buttons
- **[G19]** Playing XI: embedded in toss flow as Step 2.5 (checkbox list, players_per_side validation)
- **[G20]** 2nd innings openers: in Innings Transition modal (2 batsmen + 1 bowler selection)
- **[G21]** Commentary: template-based, on-the-fly from delivery data (no new DB column)
- **[G22]** Missing screens: edit profile/team reuse forms, settings inline, search/filters deferred
- **[G23]** Semantic colors: specific hex values (four=0xFF1565C0, six=0xFF6A1B9A, wicket=0xFFC62828, etc.)
- **[G24]** Empty states: per-screen icon + message + CTA (10 screens defined)
- **[G25]** Wagon wheel selector: dropdown above chart, default top scorer, filter by striker_id + innings_id

### Comprehensive CricHeroes Gap Review (69 Items, 9 Groups)

Live web research across 30+ sources, 4 research agents, iterative user review of all 9 feature groups. Key finding: 25 of 69 items were already implemented in UI prototypes.

**ADOPT (7 items — UI prototypes updated):**
- **[CH-1]** SMS auto-read OTP: Flutter `smart_auth` package (logic only, Phase 1)
- **[CH-3]** Searchable country code selector: `02-login.html` updated with 20 cricket nations dropdown
- **[CH-4]** Location field in profile setup: `04-profile-setup.html` updated (optional city/state)
- **[CH-13]** Bulk contact import for teams: phone contacts multi-select (logic only, Phase 2)
- **[CH-14]** Team location field: `07-create-team.html` updated (optional location)
- **[CH-29]** "Need X from Y balls" context: `12-scoring-page.html` updated (2nd innings context bar)
- **[CH-52]** Run rate per-over graph: `16-match-analytics.html` updated (5th tab "Run Rate")

**DEFER (20 items — post-MVP, see CRICHEROES_REFERENCE.md Section 12.3):**
- WhatsApp Login (OTPless), PIN Login, Notifications tab, Team profile tabs, Invite link sharing, Match banners, Match officials, Live Match Edit, Post-match edit window, Projected score, Field position map, Awards (PoTM), Share as image, Player comparison, Badges, Awards display, Form tracker, Player tags, Bulk schedule import

**ALREADY DONE (25 items):** CRR, RRR, partnership, batter SR, bowler economy, free hit badge, swap strike, scorecard tables, FOW, extras breakdown, super over, commentary, Manhattan/Worm/Wagon/MVP charts, tournament formats/points/groups/scheduling — all already in UI prototypes.

**SKIP (18+ items):** Different tab structure, stories, side drawer, team attendance, CricPay, team chat, extra match types, virtual coin toss, pitch type, SQS, CricInsights PRO, sponsor features, payment processing.

## Completed Work

### Wireframe Review (In Progress — 6 of 7 Groups Done)

Systematic review of all 28 HTML wireframes in `docs/ui/` before implementation. Each screen gets a visual review + 3-agent parallel analysis (CricHeroes comparison, domain rules compliance, M3 dark theme/accessibility).

**Groups completed:** A (Auth Flow — 4 screens), B (Home — 1 screen), C (Teams Flow — 4 screens), D (Match Setup — 2 screens), D2 (Tournament Flow — 6 screens), E (Scoring Flow — 7 screens) = 24 of 28 screens reviewed.

**Session 1 changes (Groups A+B):** Theme seed color #2E7D32→#1976D2, profile setup photo upload removed + enums fixed, home screen search removed + stats/CRR/result types improved, DATABASE.md `city`→`location` + `display_name` varchar reduced, CODE_STANDARDS.md `keeper`→`wk_batter`, API.md `city`→`location`.

**Session 2 changes (Group C):** CLAUDE.md improved (tsc, phases, CI sections). Teams-list 2-col grid + role badges + location. Create-team ball type removed + maxlength fixed. Team-detail subtitle/stats/player-descriptions/emojis all fixed. Manage-roster inline modal removed + role labels/bowling styles/badges/touch targets all fixed.

**Session 3 changes (Group D):** Match-setup: players_per_side field, tournament rule locking, expanded overs presets, match date, advanced settings panel, Material icons. Toss: full rewrite — 5-step stepper with Playing XI selection (G19), striker designation, "Field" terminology, role/bowling style label fixes, back navigation, compact stepper CSS.

**Session 4 changes (Group D2):** Tournaments-list: search removed, location added, empty state icon fixed. Create-tournament: maxlength, overs presets, T9 match rules section, T13 scheduling, format conditional visibility. Tournament-detail: overflow menu, match count 15, L column in standings, empty states. Standings: tournament context bar, qualified badge sizing, empty state icon. Knockout-bracket: context bar, trophy SVG, overs in scores, result summary, empty state. Leaderboard: empty state icon, batting avg detail (dismissals not innings), economy detail (runs conceded not wickets).

**Session 5 changes (Group E):** Scoring flow screens 12-14 + 25-28 reviewed. Wicket dialog and extras panel needed no changes. Match-complete: avatar size 56px, modal-footer standardization, Super Over btn-primary for tied knockout, JS toggle for button states. Super-over-setup: touch targets 14px, Batter/WK-Batter terminology, full bowling style labels, batting order info bar, max-3 enforcement JS. Add-player: role chip data-values fixed, bowling styles expanded to full 9-value DB enum, search result label fixed.

See "Changes Applied During Wireframe Review" section for full change log.

---

### Pre-Implementation Infrastructure

Hardened Claude Code development infrastructure with deterministic enforcement:

**Hooks (9):** `.claude/hooks/` — PowerShell scripts for automated guardrails:
- `validate-file-placement.ps1` — Enforces rules.md on every Edit/Write (snake_case, no widgets in core, service suffixes, etc.)
- `guard-cross-feature-imports.ps1` — Blocks cross-feature data/domain imports on Write
- `protect-sensitive-files.ps1` — Blocks writes to .env, credentials, keys on Edit/Write
- `load-session-context.ps1` — Injects CONTINUE_PROMPT.md "What to Do Next" on session start
- `reinject-after-compaction.ps1` — Re-injects critical rules + git state + task context after compaction
- `quality-gate.ps1` — Blocks session end if CONTINUE_PROMPT.md not updated or uncommitted source changes
- `guard-bash-commands.ps1` — Blocks destructive git/file operations
- `auto-invoke-cricheroes-comparator.ps1` — Auto-invokes CricHeroes comparison on feature file writes
- `auto-format.ps1` — Formats .dart/.ts files on Edit/Write (skips generated files)

**Skills (16 total):** `/analyze`, `/server-test`, `/commit-draft`, `/debug-log`, `/schema-parity`, `/drift-migrate`, `/score-test`, `/build-check`, `/sync-test`, `/screenshot-verify`, `/session-handoff`, `/db-migrate`, `/phase-gate`, `/issue-create`, `/tdd`, `/cricket-domain`

**MCP Servers (2):**
- PostgreSQL MCP (project-scope, `.mcp.json` — gitignored)
- GitHub MCP (user-scope, via `claude mcp add`)

**CI Pipeline:** `.github/workflows/ci.yml` — 5 jobs (structure-validate, flutter-analyze, flutter-test, server-lint, server-test) on self-hosted Windows runner

**Validation Scripts:** `scripts/validate-structure/` — `flutter-validator.js` + `server-validator.js` for CI and pre-commit use

**Settings.json:** Expanded permissions (47 allow rules, 11 deny rules) + 10 hooks configured (PreToolUse, PostToolUse, SessionStart, Stop)

**Documentation synced:** CLAUDE_CODE_CONFIG.md (13 agents, 16 skills, 9 hooks, 2 MCP servers), PROJECT_MANAGEMENT.md, README.md, .gitignore

---

### Comprehensive CricHeroes Gap Review

Conducted live web research (30+ sources, 4 research agents covering auth/home/teams, scoring/analytics/scorecard, tournaments/profiles, and UI prototype analysis). Reviewed all 69 differences across 9 groups with iterative user approval. Updated 5 UI prototype files and CRICHEROES_REFERENCE.md Master Gap Summary (Section 12, now with subsections 12.1-12.5).

### CricHeroes Comparison System Setup

Created automated competitive intelligence system:
- **`docs/planning/CRICHEROES_REFERENCE.md`** — Comprehensive CricHeroes knowledge base covering all features organized by CricApp phase (auth, teams, tournaments, scoring, analytics, profiles, real-time). Includes gap analysis tables with ADOPT/SKIP/DEFER recommendations. 69 gaps reviewed: 7 ADOPT, 25 ALREADY DONE, 20 DEFER, 18+ SKIP.
- **`.claude/agents/cricheroes-comparator.md`** — Research agent that reads knowledge base + does live web analysis, outputs structured comparison reports.
- **CLAUDE.md rule added** — Main agent automatically invokes comparator before implementing any new feature/screen. All clarifying questions include CricHeroes option.
- **Workflow integrated** — Step 2.5 added to IMPLEMENTATION_PRACTICES.md feature workflow.
- **Documentation updated** — CLAUDE_CODE_CONFIG.md (Agent #5), PROJECT_MANAGEMENT.md (doc map entry), CONTINUE_PROMPT.md.

### Step 0g: Pre-Implementation Gap Analysis Round 4 — Final & Exhaustive (22 Decisions)

Audited every planning doc (4,216 lines), process doc (2,593 lines), and all 24 UI prototypes. Found documents 90%+ complete and internally consistent. The 22 gaps below were the only remaining items that would cause assumptions during implementation. All 22 resolved and applied across 7 docs.

**SCORING_RULES.md:** Added A1 (undo blocked after transition) to Section 4 constraints. Updated A2 (penalty delivery: bowler_id=NULL, ball_number=0) in Section 3.6. Updated A3 (super over UI trigger: auto-trigger with confirmation modal) in Section 9.7. Updated A4 (bowler mid-over replacement per ICC Law 22.7: previous-over bowler CAN replace) in Section 6.4b. Updated A5 (5-run penalty direction toggle) in Section 3.6. Fixed duplicate Section 3.9 numbering → 3.11 Dismissal Types.

**DATABASE.md:** Updated A2: deliveries.bowler_id now nullable for penalty deliveries. Added ball_number=0 note for penalties.

**API.md:** Added C1 sync batching rules to Section 1.7: single endpoint, dependency order processing, 50 delivery max per request.

**CODE_STANDARDS.md:** Added B1 (Select New Batter modal), B2 (Select Next Bowler modal), B3 (Innings Transition 3-step stepper), B4 (Match Complete modal), B5 (Super Over Setup flow). Added C3 (date/time display format table). Updated C5 (team logo: client compression 256x256/80%, server 413 rejection; profile photo deferred). Added E1 (Android back button behavior table). Added E3 (minimal a11y: touch targets, WCAG AA, Semantics, font scaling).

**IMPLEMENTATION_PRACTICES.md:** Added C2 (sync retry reset rules: reset on success, FAILED at 5, pull-to-refresh retry, match completion forced sync). Added C4 (Drizzle migration: manual for dev, deferred for prod). Added C6 (package version strategy: latest stable, caret ranges). Updated D1 (API URL default: 10.0.2.2:3000 for emulator). Added E2 (app background/kill recovery: offline-first, no special handling).

**IMPLEMENTATION_PLAN.md:** Added D1 (dev API URL config with dart-define). Added D2 (PostgreSQL setup: cricapp_dev / cricapp databases on VPS). Updated D3 (Nginx: HTTP proxy + WS upgrade, SSL via Cloudflare, direct port for dev).

**CONTINUE_PROMPT.md:** Added all 22 R4 decisions in categorized format (A1-A5, B1-B5, C1-C6, D1-D3, E1-E3).

### Step 0f: Pre-Implementation Readiness Audit Round 2 (25 Questions + 14 Auto-Resolved)

A comprehensive re-audit of ALL planning docs identified 25 additional gaps requiring user decisions and 14 auto-resolvable gaps (from cricket laws/best practices). All 39 resolved and applied to planning/process docs.

**DATABASE.md:** Added 5 rule columns to `matches` table (players_per_side, max_overs_per_bowler, wide_runs, no_ball_runs, powerplay_overs). Added index on deliveries.sequence_number. Added unique constraint on overs(innings_id, over_number). Updated local SQLite tables to 16 mirrored + 2 local-only (tournament tables server-only). Documented sequence_number client-assignment, career stats update trigger, all-out threshold. Removed "handled_ball" from seed data (merged into obstructing_field per 2017 Laws).

**API.md:** Changed scoring to REST-only writes, WebSocket broadcast-only. Removed delivery/undo_delivery from WS client-to-server messages. Expanded sync push to accept all scoring entities. Added conflict resolution section (last-write-wins). Added match_state snapshot message for WS reconnection. Removed wagonWheelZoneId from delivery payload.

**SCORING_RULES.md:** Added deferred items section (Mankad, Timed Out, Obstructing Field, wagon wheel zones). Added retired hurt last-man rule. Added configurable wide_runs/no_ball_runs throughout pipeline. Added penalty undo procedure. Updated ABANDONED state to allow reopen. Added bowler injury mid-over change rule. Added 6th "Set" menu item (Bowler Injured). Added caught-dismissal runs rule, hit-wicket-on-no-ball rule, stumped-off-wide bowler credit, wide+bye exclusivity, free hit expiry rule, all-out threshold, transaction requirement.

**CODE_STANDARDS.md:** Added "More..." button spec, manual strike swap button, scorer vs viewer mode table, Add Player dialog spec, 5-tab bottom navigation, M3 dark theme interpretation table. Updated WS message types (removed client→server scoring).

**IMPLEMENTATION_PLAN.md:** Added 12-var .env.example. Resolved Firebase contradiction (single project MVP). Updated data flow to REST-only writes.

**IMPLEMENTATION_PRACTICES.md:** Fixed Firebase per-environment contradiction. Updated env vars reference.

**CONTINUE_PROMPT.md:** Added all Q1-Q25 + AR-1 through AR-14 decisions.

### Step 0e: Pre-Implementation Gap Analysis Resolution (32 Gaps)

A final comprehensive gap analysis identified 32 gaps across 6 categories. All 32 resolved and applied to planning/process docs.

**Plan A (G1-G11) — Database, API, WebSocket:**
- **DATABASE.md:** Added Section 9.1 (FK cascade rules: RESTRICT/CASCADE/SET NULL), Section 9.2 (updated_at: application-level both platforms), Section 9.3 (overs table: populated live at over completion), Section 9.4 (super over: application-level enforcement), Section 9.5 (formal JSONB schemas for match_analytics). Added `penalty_runs` column to `innings` table.
- **API.md:** Added Section 1.9 (POST /uploads/image: VPS filesystem + Nginx). Added 5 match action endpoints (abandon, declare, reopen, super-over, scorer). Updated deliveries GET with pagination (required inningsId, limit=50, max=100). Added `delivery_undone` WebSocket message with full state. Added Section 5 (CORS: allow * for MVP). Added Section 6 (validation rules table).

**Plan B (G12-G25) — Scoring Engine, UI/UX:**
- **SCORING_RULES.md:** Added Section 3.8 (powerplay: display-only PP badge), Section 3.9 (overthrows: all runs to batter/bowler). Updated Section 3.6 (5-run penalty: separate delivery, batting vs fielding team, innings.penalty_runs). Updated Section 3.2 (run out on wide: 1 + completed runs as wide_runs). Updated Section 3.10 (declaration: enabled all formats). Added Section 8.8 (abandonment: No Result, NR points, excluded from NRR).
- **CODE_STANDARDS.md:** Added scoring semantic colors table (9 elements with hex values). Added empty state content table (10 screens). Added match complete modal spec, playing XI selection flow (toss Step 2.5), 2nd innings opener selection, commentary auto-generation templates, missing screens scope, wagon wheel player selector dropdown. Updated WS message types to include `delivery_undone`.

**Infrastructure & Cross-Doc (G26-G32):**
- **PDR.md:** Marked US-12 (Google Sign-In) as deferred to post-MVP.
- **GITHUB_ISSUES.md:** Added Phase 2.5 Tournaments milestone, merged WebSocket into Phase 3.
- **PROJECT_MANAGEMENT.md:** Updated table count 24→28.

### Tournament/League Management Addition
Added full tournament/league management as Phase 2.5 in the MVP. Changes span 15 files across planning docs, UI prototypes, and blueprint:

**Planning docs updated:**
- **DATABASE.md:** Table count 22→27. Added `tournament_id` FK to `matches`. Added 5 new tables: `tournaments`, `tournament_teams`, `tournament_groups`, `tournament_fixtures`, `tournament_standings`. Added 10 tournament indexes. Added to SQLite mirrored tables.
- **SCORING_RULES.md:** Added Section 8: Tournament Rules — tournament state machine (DRAFT→REGISTRATION→LIVE→COMPLETED), 3 formats (round-robin, knockout, group+knockout), NRR calculation formula with worked example, tiebreaker order (Points→NRR→H2H→Joint rank), qualification rules, match integration hooks.
- **API.md:** Added Section 1.9: Tournaments with 12 REST endpoints (CRUD, status transitions, team management, fixture generation, standings, leaderboard). Added rate limiting row (30 req/min).
- **PDR.md:** Moved tournaments from "Excluded" to "Included in MVP". Added 7 user stories (US-16 to US-22). Updated table/screen counts.
- **IMPLEMENTATION_PLAN.md:** Inserted Phase 2.5: Tournament Management (Week 4-5) with 13 task checkboxes. Shifted Phases 3-7 by +1 week. Added verification plan row. Updated screen count to 24. Added `tournaments/` feature folder structure for both Flutter and server.

**UI prototypes created (docs/ui/):**
- 6 new screens: Tournaments List (19), Create Tournament (20), Tournament Detail (21), Standings (22), Knockout Bracket (23), Leaderboard (24)
- Updated `index.html`: screen count 18→24, added D2 Tournament Flow group
- Updated `05-home.html`: added Tournaments section with summary card, added "Tournament" quick action
- Updated `10-match-setup.html`: added optional tournament selector with modal

**Blueprint updated (docs/planning/blueprint.html):**
- Added 6 phone wireframes in new "Tournament Flow" cluster
- Added Tournament State Machine panel and NRR Calculation panel
- Added tournament sidebar navigation entry
- Added `/tournaments` to API route groups
- Updated DB ER panel: 24→27 tables, added tournament ER tables
- Added SVG navigation arrows for tournament flow
- Expanded canvas to accommodate new section

### Tournament System Design Refinement
Applied 8 review decisions (T9-T16) refining the Phase 2.5 tournament system:

**Planning docs updated:**
- **DATABASE.md:** Table count 27→28. Added 5 template columns to `tournaments` (players_per_side, max_overs_per_bowler, wide_runs, no_ball_runs, powerplay_overs). Added `tournament_requests` table (6th tournament table). Added scheduled_time + estimated_duration_minutes to `tournament_fixtures`. Added is_super_over + super_over_number to `innings`. Updated match_result.result_type enum to include "super_over". Added 2 new indexes. Updated SQLite mirrored tables.
- **API.md:** Added 5 template fields to POST/PUT tournament schemas. Added 3 new registration endpoints (POST register, GET requests, PUT approve/reject). Updated fixture response/edit with scheduling fields + venue conflict warning. Added super over data to match detail response.
- **SCORING_RULES.md:** Added Section 8.7: Match Rules Inheritance (tournament template → locked match fields). Added Section 9: Super Over Rules (trigger conditions, procedure, sudden death, result recording, stats exclusion, UI flow, scoring engine integration).
- **IMPLEMENTATION_PLAN.md:** Phase 2.5 tasks expanded from 13→19. Added template fields, registration flow, roster validation, fixture scheduling, super over implementation. Updated verification plan.
- **PDR.md:** Updated US-16 with template fields. Added US-23 (team self-registration) and US-24 (super over scoring). Moved super overs from excluded to included in MVP scope.
- **CONTINUE_PROMPT.md:** Added decisions T9-T16.

**Note:** `.claude/rules.md` tournament additions (lines 310, 329-332) were applied in a previous session.

### Step 0: Planning Doc Updates (Gap Analysis)
A comprehensive gap analysis resolved 120 decisions across 22 rounds of Q&A. All planning docs have been updated:
- **DATABASE.md:** Dropped `dls_calculations` and `shot_types` tables. Added `is_retired_hurt` to `batting_stats`, `is_active` to `teams`. Removed `super_over` from match status enum and `match_result.result_type`. Added full `sync_queue` and `local_preferences` schemas in Local-Only Tables section.
- **API.md:** Added `GET /api/v1/players/search` (player search by name) and `DELETE /api/v1/teams/:id` (soft delete team) endpoints.
- **SCORING_RULES.md:** Removed SUPER_OVER state from state machine. Tied match → COMPLETED with "Match Tied".
- **IMPLEMENTATION_PRACTICES.md:** Updated match state machine test list (6 states, no SUPER_OVER).
- **CLAUDE.md:** Updated match state machine description to reflect tied match handling.

### Step 0b: Missed Q1-Q18 Doc Fixes
4 decisions from Q1-Q18 that were missed in the original Step 0 have now been applied to DATABASE.md:
- **ball_types seed values:** Added "other" → now `leather, tennis, tape, other` (Gap 77)
- **bowling_style enum:** Replaced vague "etc." with full 9-value enum: `right_arm_fast, right_arm_medium, right_arm_off_spin, right_arm_leg_spin, left_arm_fast, left_arm_medium, left_arm_orthodox, left_arm_chinaman, none` (Gap 74)
- **Custom overs range:** Added "Valid range: 1-50" note on `matches.total_overs` column (Gap 11)
- **Max roster size:** Added "25 players per team (enforced at application level)" note on `team_rosters` section (Gap 53)

### Step 0c: Full 62-Question Pre-Implementation Gap Analysis
A second, more comprehensive gap analysis identified 62 questions across 7 categories. All 62 resolved and applied to docs (commit `d4013ae`). Working document at `docs/debug/gap-analysis-working.md`, full resolution log at plan file `mellow-seeking-crown.md`.

**Category 1 — Document Contradictions (Q1-7):** Fixed pagination to offset-based, added `updated_at` to 8 tables, anonymous WebSocket viewers, standardized wagon wheel zone to int FK, added `match_players` table, removed stale `shot_types` reference, removed SUPER_OVER from blueprint.

**Category 2 — Missing DB Infrastructure (Q8-10):** Deferred partnerships to post-MVP, dropped `innings_stats` table (moved 3 columns to `innings`), deferred materialized view SQL to Phase 5.

**Category 3 — Missing API Endpoints (Q11-16):** Expanded toss endpoint with opening player selection, added Playing XI endpoint, completed 4 incomplete endpoint specs, removed server JWT from auth/verify, defined sync pull response shapes.

**Category 4 — Scoring Engine Logic (Q17-31):** Specified run out crossed/not-crossed rules, retired hurt/out flow, stumped-off-wide UI, no-ball+byes interaction, wicket-on-last-ball order, new batter position by dismissal type, free hit through wides, custom run input (overthrows), custom extras input, declaration flow, abandonment rules, bowler over limit validation, concurrent scoring lock (scorer_id), 5-run penalty rules.

**Category 5 — UI/Design Gaps (Q32-50):** Added complete Section 10 "UI Design Tokens & Patterns" to CODE_STANDARDS.md covering M3 seed color (#2E7D32), Roboto font, Material Symbols icons, 8dp grid spacing, typography scale, dark surface hierarchy, loading/empty/error state patterns, M3 transitions, app bar pattern, snackbar patterns, scoring page fixed-scroll-fixed layout, team logo spec, initials-only avatar, minimal settings in Profile, email auth tab on login, home dashboard content.

**Category 6 — Deployment & Infrastructure (Q51-58):** Expanded IMPLEMENTATION_PLAN.md Phase 7 with existing VPS details (Windows Server 2022, PostgreSQL 16.8, Nginx, PM2, Cloudflare, GitHub Actions self-hosted runner), domain TBD, health monitoring integration, daily pg_dump backups.

**Category 7 — Server Architecture (Q59-62):** Fixed WebSocket delivery message to match REST fields, added reconnection/catch-up strategy (REST snapshot, no replay), documented overs decimal notation utility, clarified `total_runs` as application-level computation.

### Step 0d: Final 18-Question Pre-Implementation Gap Analysis
A final focused gap analysis before implementation resolved 18 decisions across 5 categories (Infrastructure, Database, Scoring Engine, UI/UX, Cross-Document Conflicts). All 18 decisions applied to 6 docs: DATABASE.md, SCORING_RULES.md, IMPLEMENTATION_PLAN.md, IMPLEMENTATION_PRACTICES.md, CODE_STANDARDS.md, and CONTINUE_PROMPT.md.

Key changes:
- **Auth simplified:** Phone OTP only (removed Google Sign-In, Email/Password)
- **DATABASE.md:** Added `is_penalty` boolean to deliveries table
- **SCORING_RULES.md:** Added "Direct Hit?" toggle for run outs, Reopen Last Innings/Match functionality, 5-item "Set" menu
- **IMPLEMENTATION_PLAN.md:** minSdkVersion=23, server port=3000, added flutter_secure_storage/image_picker/logger/firebase_crashlytics deps
- **IMPLEMENTATION_PRACTICES.md:** Sync retry=5 (persistent across restarts), offline errors=log-only
- **CODE_STANDARDS.md:** Scoring button size tiers, connectivity dot spec, local_preferences keys, Phone OTP only auth screen

### Interactive Architectural Blueprint
- **`docs/planning/blueprint.html`** — Comprehensive single-file HTML blueprint with:
  - All 24 screens wireframed (original 18 + 6 tournament screens: Tournaments List, Create Tournament, Tournament Detail, Standings, Knockout Bracket, Leaderboard)
  - 5 scoring dialogs orbiting the Scoring Page (Extras Panel, Wicket Dialog, Select Next Bowler, Select New Batter, Innings Transition)
  - Backend architecture band (API Layer, WebSocket Protocol, Database ER, Offline Sync swim-lane)
  - Cricket domain overlays (10-step delivery pipeline, match state machine, strike rotation decision tree, extras comparison table, undo mechanism, ScoringState shape, widget-to-state mapping, tournament state machine, NRR calculation panel)
  - Interactive pan/zoom (mouse drag + scroll wheel + touch pinch)
  - Navigation sidebar with animated pan-to-section
  - Minimap showing viewport position
  - Glossary of cricket terms
  - Hub-and-spoke layout with Scoring Page as gravitational center

### Best Practices Documentation
- Reorganized `docs/` into `planning/` and `process/` subdirectories
- Created Product Development Requirements (`docs/planning/PDR.md`)
- Created 6 process docs covering code standards, implementation workflow, debugging, issue management, and Claude Code config

## Repository Structure

See [CLAUDE.md](../CLAUDE.md#monorepo-layout) for the folder structure and [.claude/rules.md](../.claude/rules.md) for file placement rules.

## Instructions for Next Session

Read this file first, then read `docs/planning/IMPLEMENTATION_PLAN.md` Phase 1 section. Follow the **17-step TDD workflow** in `docs/process/PLAYBOOK.md` — write tests BEFORE implementation for each layer (Steps 3/5/7 = RED, Steps 4/6/8 = GREEN+REFACTOR). Use `/tdd <feature> <layer>` skill for guided TDD. Refer to `docs/planning/DATABASE.md` for schema, `docs/planning/API.md` for endpoints, `docs/planning/SCORING_RULES.md` for cricket logic (or `.claude/skills/cricket-domain/SKILL.md` for quick reference), and `docs/planning/blueprint.html` for visual architecture reference.
