# Code Reviewer Memory

## Recurring Patterns and Lessons

- 2026-02-23: `kDebugMode` auth bypass in router.dart is intentional for UI testing but should be explicitly documented as requiring removal before Play Store submission — it bypasses the entire auth flow in debug builds.
- 2026-02-23: `analyze_output.txt` is committed to the repo (exists at apps/mobile/analyze_output.txt) but is not in .gitignore — always flag these artifact files.
- 2026-02-23: `apps/mobile/android/app/google-services.json` is committed with real Firebase project credentials (project_id: cricapp-7403d, API key: AIzaSyBkeeiHgX_WFdueEH9M2h8qICPkfe_rxeI) — gitignore has `**/google-services.json` but the file is still tracked, likely because it was committed before the gitignore rule was added. Needs `git rm --cached` to remove from tracking.
- 2026-02-23: `apps/mobile/android/key.properties` contains plaintext signing passwords — gitignore rule uses bare `key.properties` which git treats as matching at any depth, so it may already be excluded, but verify with `git ls-files`.
- 2026-02-23: FutureProvider bodies use `ref.read` instead of `ref.watch` for repository providers — this is correct for FutureProvider (one-shot fetch) but note it means cache invalidation works but re-fetch requires explicit ref.invalidate.
- 2026-02-23: The `live` feature (LivePage) has no providers.dart of its own — it re-exports from home and tournaments features via a thin re-export file. This is clean but means the live feature has no dedicated data layer, which is appropriate since it reuses existing data.
- 2026-02-23: The `scorerMatchAuth` cache in websocket/handler.ts (UID → Set<matchId>) is never evicted — for a long-running server this will grow unboundedly for each unique scorer. Low risk for MVP but worth noting for production.
- 2026-02-23: The `_routeExtraCache` in router.dart is a global Map that is never cleared — each unique matched path keeps its last extra indefinitely, creating a potential memory leak for dynamic routes like /scoring/:matchId where matchId varies.
- 2026-02-23: Dart `unnecessary_underscores` lint warnings (13 total) in home_page.dart, live_page.dart, add_player_page.dart, tournament pages, and scoring_page_test.dart — these are info-level and do not affect functionality.
- 2026-02-23: The Updates feature has no test coverage at all (no test file for UpdatesPage, updates providers, or updates repository) — this is a gap added with the navigation restructure.
- 2026-02-23: The LivePage imports directly from home/providers.dart and tournaments/providers.dart — this technically crosses feature boundaries but is encapsulated behind live/providers.dart re-export, which is an acceptable pattern for a pure hub page.
- 2026-02-23: `_onEventTap` in UpdatesPage calls `ref.read(updatesRepositoryProvider).markAsRead(...)` fire-and-forget without error handling — if the server call fails the UI still shows the event as read.
- 2026-02-23: The `_groupByDate` logic in UpdatesPage uses `today.weekday - 1` for week start which breaks for Sunday (weekday=7, gives 6 days back — correct) but places Monday as week start, not Sunday — consistent with Indian cricket context.
- 2026-02-23: Test routes guard in test-verify.routes.ts uses `onBeforeHandle` with a NODE_ENV check as a secondary guard — this is defense-in-depth since index.ts already conditionally imports the routes only in test env.
