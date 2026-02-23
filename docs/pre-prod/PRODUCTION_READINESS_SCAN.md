# Production Readiness Scan — CricScores

**Date:** 2026-02-23
**Scanned by:** Claude Code (Opus 4.6)
**Scope:** Full codebase — `apps/mobile/` (Flutter) + `apps/server/` (Bun/ElysiaJS)
**Reference:** Prior analysis in `ANYWHERE_ACTIONS.md` and `VPS_ACTIONS.md`

---

## Executive Summary

**Verdict: NOT READY for public production. READY for limited friend-testing with fixes below.**

The app has solid foundations — clean architecture, 2000+ tests, offline-first scoring, E2E validated. However, the scan reveals **5 BLOCKERS**, **15 CRITICAL gaps**, and **12 OPTIONAL improvements** that range from security hardening to operational readiness.

All 11 items from the previous `ANYWHERE_ACTIONS.md` audit are **DONE** (verified). The gaps below are **new findings** not covered in the prior analysis.

---

## Prior Audit Status (ANYWHERE_ACTIONS.md)

| # | Item | Status |
|---|------|--------|
| A1 | Dio Timeouts (4 providers) | DONE |
| A2 | Firebase Auth Token (4 providers) | DONE |
| A3 | WebSocket Heartbeat (ping/pong) | DONE |
| A4 | Release Keystore & Signing | DONE (build.gradle.kts configured) |
| A5 | Cleartext Traffic flag | DONE |
| A6 | User-Friendly Error Messages | DONE (ErrorDisplay widget) |
| A7 | Sync Status on Scoring Page | DONE (SyncStatusIndicator wired) |
| A8 | WebSocket Reconnect (30 attempts) | DONE |
| A9 | Custom App Icon | DONE (cricket ball) |
| A10 | App Label "CricScores" | DONE |
| A11 | Pull-to-Refresh on Profiles | DONE |

---

## NEW FINDINGS

### BLOCKER — Must fix before any distribution

---

#### B1. No ProGuard / R8 Code Shrinking on Release Builds

**Risk:** Release APK contains full Dart debug symbols and unshrunk native code. APK is unnecessarily large and reverse-engineerable.

**File:** `apps/mobile/android/app/build.gradle.kts:54-62`

**Current state:**
```kotlin
buildTypes {
    release {
        signingConfig = if (keystorePropertiesFile.exists()) { ... }
        // No minifyEnabled, shrinkResources, or proguard config
    }
}
```

**Fix:** Add to `release` block:
```kotlin
isMinifyEnabled = true
isShrinkResources = true
proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
```
Create `apps/mobile/android/app/proguard-rules.pro` with Flutter/Firebase keep rules.

---

#### B2. Test Verification Routes Exposed in Production

**Risk:** `test-verify.routes.ts` is always registered in `index.ts` (line 13-32). While individual endpoints check `NODE_ENV !== 'test'`, the `/api/v1/test/health` endpoint is explicitly exempted from the guard (line 25). More critically, **if someone accidentally deploys with `NODE_ENV=test`**, they get full DB access: `reset-db`, `reset-match-data`, `run-migration`, all read endpoints without auth.

**File:** `apps/server/src/index.ts:13,32` — `testVerifyRoutes` always imported and registered
**File:** `apps/server/src/routes/v1/test-verify.routes.ts:23-29` — Guard relies solely on `NODE_ENV`

**Additionally:** `auth.ts:16` bypasses ALL Firebase auth when `NODE_ENV=test`, returning a hardcoded test user for every request. This is a **separate risk** — even if test routes are removed, all authenticated routes accept unauthenticated requests when `NODE_ENV=test`.

**Fix (test routes):** Conditionally register:
```typescript
if (process.env.NODE_ENV === 'test') {
  app.use(testVerifyRoutes);
}
```

**Fix (auth bypass):** Add startup validation that rejects `NODE_ENV=test` in production, or use a separate `ENABLE_TEST_AUTH` flag that's never set in production `.env`:
```typescript
if (process.env.NODE_ENV === 'test' && !process.env.ENABLE_TEST_AUTH) {
  throw new Error('Set ENABLE_TEST_AUTH=true explicitly to enable test auth bypass');
}
```

---

#### B3. CORS Wildcard Default in Production

**Risk:** `CORS_ORIGIN` defaults to `'*'` (line 17 of `env.ts`). If the `.env` file on VPS omits `CORS_ORIGIN`, the server accepts requests from any origin — cross-site request forgery attacks become trivial.

**File:** `apps/server/src/config/env.ts:17`
```typescript
CORS_ORIGIN: getEnvVar('CORS_ORIGIN', '*'),  // Dangerous default
```

**Fix:** Remove the default for production safety:
```typescript
CORS_ORIGIN: getEnvVar('CORS_ORIGIN'),  // REQUIRED — no default
```
Or validate that `*` is not allowed when `NODE_ENV=production`.

---

#### B4. WebSocket `publish_score` Has No Authentication

**Risk:** Any anonymous WebSocket connection can send `publish_score` messages and inject fake score updates to all viewers of any match. The handler (line 91-111 of `handler.ts`) does not verify the sender is the scorer for that match.

**File:** `apps/server/src/websocket/handler.ts:91-111`

**Current:** Anyone who connects to `/ws` and sends `{"type":"publish_score","matchId":"...","payload":{...}}` gets their payload relayed to all subscribers.

**Fix:** At minimum, validate the WS `token` query parameter matches the match scorer's Firebase UID. Or maintain a server-side map of `matchId → scorerWsId` and only relay from the authorized scorer.

---

#### B5. No INTERNET Permission in Release AndroidManifest

**Risk:** The `<uses-permission android:name="android.permission.INTERNET"/>` is only in `debug/AndroidManifest.xml` and `profile/AndroidManifest.xml`, but NOT in `main/AndroidManifest.xml`. On Android 6+, the app will fail to make any network requests in release builds.

**File:** `apps/mobile/android/app/src/main/AndroidManifest.xml` — no `<uses-permission>` tag
**File:** `apps/mobile/android/app/src/debug/AndroidManifest.xml:6` — has INTERNET permission

**Fix:** Add to `main/AndroidManifest.xml` before the `<application>` tag:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

---

### CRITICAL — Will cause bad experience or security issues

---

#### C1. No Global Error Handler (Flutter)

**Risk:** Unhandled exceptions crash the app with a red/grey error screen. No `FlutterError.onError`, no `PlatformDispatcher.onError`, no `runZonedGuarded` in `main.dart`.

**File:** `apps/mobile/lib/main.dart` — simple `runApp()` without error zone

**Fix:** Wrap `runApp` in `runZonedGuarded` and set `FlutterError.onError` to log errors gracefully instead of crashing.

---

#### C2. No Rate Limiting on Any Endpoint

**Risk:** All endpoints are unthrottled. A single client can spam the scoring endpoint, create unlimited teams/tournaments, or brute-force the health endpoint. Even basic protection is absent.

**Files:** All route files in `apps/server/src/routes/v1/`

**Fix:** Add rate limiting middleware (e.g., per-IP or per-user token bucket) at minimum on auth and scoring endpoints. Even a simple in-memory counter is better than nothing for friend-testing.

---

#### C3. No Security Headers

**Risk:** Server responses lack `X-Frame-Options`, `X-Content-Type-Options`, `Strict-Transport-Security`, `X-XSS-Protection`. While Nginx/Cloudflare may add some, the Bun server itself adds none.

**File:** `apps/server/src/middleware/cors.ts` — only sets CORS headers, no security headers

**Fix:** Add security headers in the CORS middleware or a separate middleware:
```typescript
set.headers['X-Content-Type-Options'] = 'nosniff';
set.headers['X-Frame-Options'] = 'DENY';
set.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin';
```

---

#### C4. No SSL on Database Connection

**Risk:** Database connection uses plain TCP (`postgres://...@127.0.0.1`). While the VPS runs both Bun and PostgreSQL on localhost, if the architecture ever changes (separate DB server), credentials travel unencrypted.

**File:** `apps/server/src/config/database.ts:6-10`

**Current:** `postgres(env.DATABASE_URL, { max: 10, idle_timeout: 20, connect_timeout: 30 })` — no `ssl` option.

**Impact for friend-testing:** LOW (localhost only). For actual production: CRITICAL.

---

#### C5. `debugPrint` Statements Leak Operational Details

**Risk:** 18+ `debugPrint` statements across production code output internal state to device logs (accessible via `adb logcat`). Includes scoring flow details, WebSocket state, sync errors with stack info.

**Files:** `router.dart` (8 calls), `websocket_client.dart` (1), `sync_service.dart` (4), `match_live_notifier.dart` (1), `toss_page.dart` (3), `scoring_persistence_service.dart` (1), `main.dart` (3)

**Fix:** Either wrap all `debugPrint` in `kDebugMode` checks, or use a logging package with level control (only `router.dart:168` currently uses `kDebugMode`).

---

#### C6. ListView Without .builder for Dynamic Lists

**Risk:** 14 usages of `ListView(children: [...])` across pages that display dynamic data (teams list, tournaments list, match history, updates feed). All items are built upfront regardless of visibility — causes jank and memory pressure with large lists.

**Key files:**
- `teams_list_page.dart:78` — team list
- `tournaments_list_page.dart:75` — tournament list
- `updates_page.dart:160` — activity feed
- `home_page.dart:168,227,346` — matches/teams/tournaments tabs
- `match_history_page.dart:27` — match list
- `tournament_detail_page.dart:306,565` — fixture/standing lists

**Fix:** Replace `ListView(children: items.map(...).toList())` with `ListView.builder(itemCount: items.length, itemBuilder: ...)` for any list that can grow beyond ~20 items.

---

#### C7. No Network Security Config for Android

**Risk:** No `network_security_config.xml` exists. The app relies on `usesCleartextTraffic="true"` which is a blunt instrument — it allows cleartext to ALL domains, not just the development server.

**File:** `apps/mobile/android/app/src/main/res/xml/network_security_config.xml` — DOES NOT EXIST

**Fix:** Create a proper network security config that allows cleartext only to specific development domains, and pins the production certificate.

---

#### C8. No Certificate Pinning

**Risk:** No SSL certificate pinning implemented. The app trusts any valid certificate presented by any CA. A compromised CA or MITM proxy (common on public WiFi in India) could intercept all API traffic including auth tokens.

**Evidence:** Zero matches for `SecurityContext`, `HttpOverrides`, `BadCertificateCallback` in the Flutter codebase.

**Impact for friend-testing:** LOW. For production with real users: HIGH.

---

#### C9. Silent Error Swallowing in ScoringPersistenceService

**Risk:** Line 250 of `scoring_persistence_service.dart` uses `.catchError((_) {})` to silently discard local DB persistence errors. If saving scoring state fails, the user's entire match session can be lost on app crash with no warning.

**File:** `apps/mobile/lib/src/features/scoring/presentation/notifiers/scoring_persistence_service.dart:250`

**Fix:** Replace with proper error handling that at minimum sets an error flag visible to the UI. Consider a `_lastSaveError` field that the scoring page can display.

---

#### C10. WebSocket Stream Errors Not Handled in MatchLiveNotifier

**Risk:** Stream subscriptions in `MatchLiveNotifier` (lines 178-181) have no `.onError()` handlers. If the WebSocket stream errors, the viewer is stuck in an ambiguous state — neither connected nor showing a disconnection error.

**File:** `apps/mobile/lib/src/features/scoring/presentation/notifiers/match_live_notifier.dart:178-181`

**Fix:** Add `.onError()` handlers to both `listen(_onStatusChange)` and `listen(_onMessage)` calls to transition to an error state.

---

#### C11. Server Broadcast Errors Silently Suppressed

**Risk:** In `scoring.ts` (lines 106-117), after `recordDeliveryBatch` succeeds and deliveries are persisted to DB, broadcast errors to viewers are caught and silently logged. The scorer gets a success response but viewers never receive the update. No retry mechanism exists.

**File:** `apps/server/src/routes/v1/scoring.ts:106-117`

**Fix:** At minimum, include a `broadcastStatus: 'failed'` field in the response so the client knows to rely on the durable sync path. Consider a broadcast retry queue.

---

#### C12. Home Page Tabs Missing ErrorDisplay Widget

**Risk:** The Matches, Teams, and Tournaments sub-tabs in `home_page.dart` (lines 183-187, 304-307, 421-425) show generic `_EmptyState` widgets on error instead of the shared `ErrorDisplay` widget. Users see "No teams found" instead of "Check your internet connection."

**File:** `apps/mobile/lib/src/features/home/presentation/pages/home_page.dart`

**Fix:** Replace `_EmptyState` error handling with `ErrorDisplay(error: error, onRetry: () => ref.invalidate(...))` pattern used in other pages.

---

#### C13. Missing Database Indexes on 3 Tables

**Risk:** `wickets_by_delivery` has NO indexes at all — queries like "get all wickets in innings" full-scan the table. `matchAnalytics` and `match_result` also lack indexes on `matchId`.

**Files:**
- `apps/server/src/db/schema/deliveries.ts:46-55` — `wickets_by_delivery` table, no indexes defined
- `apps/server/src/db/schema/matches.ts:68-76` — `matchAnalytics` table, no index on `matchId`
- `apps/server/src/db/schema/matches.ts:58` — `match_result` table, only unique constraint (no btree index)

**Fix:** Add indexes:
```typescript
index('idx_wickets_delivery').on(table.deliveryId),
index('idx_match_analytics_match').on(table.matchId),
```

---

#### C14. Network Images Without Error Handling or Caching

**Risk:** `NetworkImage` used without error builders or disk caching. Missing avatars crash the UI, every page load re-fetches images.

**Files:**
- `apps/mobile/lib/src/features/teams/presentation/widgets/team_card.dart:32` — `NetworkImage(team.logoUrl!)`
- `apps/mobile/lib/src/features/teams/presentation/pages/team_detail_page.dart:140` — `NetworkImage(team.logoUrl!)`
- `apps/mobile/lib/src/features/player_profile/presentation/widgets/player_profile_hero.dart:34,80` — avatar images

**Fix:** Replace with `Image.network(url, errorBuilder: ...)` or use `CachedNetworkImage` package.

---

#### C15. N+1 Query Pattern in Scoring Broadcast

**Risk:** After each wicket delivery, the server makes 5+ sequential SELECT queries to build the broadcast message (team names, dismissed player, dismissal type, fielder, bowler). This adds latency to every wicket delivery.

**File:** `apps/server/src/routes/v1/scoring.ts:287-336`

**Fix:** Batch-load related names in a single JOIN query instead of sequential lookups.

---

### OPTIONAL — Polish, performance, and operational improvements

---

#### O1. App Version Still 0.1.0+1

**File:** `apps/mobile/pubspec.yaml:4` — `version: 0.1.0+1`

Recommend bumping to `1.0.0+1` for the first distribution build. The `+1` is the Android `versionCode` — increment for each APK distributed.

---

#### O2. Application ID is Generic

**File:** `apps/mobile/android/app/build.gradle.kts:34` — `applicationId = "in.cricscores.app"`

Consider changing to `in.cricscores.app` to match the domain branding.

---

#### O3. ~~No Splash Screen~~ — ALREADY DONE

Splash screen exists: `apps/mobile/lib/src/features/auth/presentation/pages/splash_page.dart` with custom cricket ball icon, two-tone app name, tagline, and loading indicator. Android launch theme also configured.

---

#### O4. Firebase Init Failure Handling is Silent

**File:** `apps/mobile/lib/main.dart:16-18` — Firebase init failure is caught and logged but the app continues. If Firebase is truly unavailable, auth will fail for every user. Consider showing an error screen instead of silently proceeding.

---

#### O5. WS_PORT Environment Variable Unused

**File:** `apps/server/src/config/env.ts:16` — `WS_PORT` is defined (default 3001) but the server uses a single port for both HTTP and WebSocket (ElysiaJS handles upgrade on the same port). This creates confusion — VPS_ACTIONS.md refers to port 3005 for both.

**Fix:** Remove `WS_PORT` from env.ts to avoid confusion.

---

#### O6. Database Connection Pool Size

**File:** `apps/server/src/config/database.ts:7` — `max: 10` connections.

For friend-testing with 5-10 concurrent users this is fine. For production scale, consider making this configurable via env var.

---

#### O7. No Request Body Size Limit (Server)

**File:** `apps/server/src/index.ts` — No `maxBodySize` configuration on Elysia. Malicious clients could send arbitrarily large payloads.

---

#### O8. WebSocket Connection Limits

**File:** `apps/server/src/websocket/handler.ts` — No limit on concurrent WebSocket connections per match or per server. A single match could accumulate unlimited viewers.

---

#### O9. No Pagination on Server Queries

Several service functions return unbounded results:
- Match lists, team lists, tournament lists could return thousands of rows
- The client-side `defaultPageSize = 20` constant exists but server queries don't all enforce LIMIT

---

#### O10. No Crash/Analytics Reporting

No Firebase Crashlytics, Sentry, or equivalent configured. In friend-testing, crashes will go unreported unless users manually report them.

---

#### O11. `testSignals` In-Memory Store (Server)

**File:** `apps/server/src/routes/v1/test-verify.routes.ts:14` — `testSignals` Map lives in memory. If this route is accidentally available in production, it's a memory leak vector (unbounded Map growth).

Already mitigated by B2 fix (conditional route registration).

---

#### O12. No Offline-First Graceful Degradation for Non-Scoring Features

The scoring engine is fully offline-capable (local Drift DB). But non-scoring features (home page, teams list, tournaments, player profile, updates) all require network — they show errors when offline with no cached data fallback.

---

## Priority Fix Order

### For friend-testing distribution (minimum viable):

1. **B5** — INTERNET permission in release manifest (5 min, app won't work without this)
2. **B2** — Remove test routes from production (5 min, security)
3. **B3** — CORS wildcard default (2 min, security)
4. **B4** — WebSocket publish_score auth (30 min, scoring integrity)
5. **B1** — ProGuard/R8 (20 min, APK size)
6. **C1** — Global error handler (15 min, crash prevention)
7. **C5** — Debug prints cleanup (15 min, log hygiene)
8. **C6** — ListView.builder migration (30 min, performance)

### For broader distribution:

9. **C9** — Silent error swallowing in scoring persistence (15 min)
10. **C10** — WebSocket stream error handling (15 min)
11. **C11** — Server broadcast error reporting (20 min)
12. **C12** — Home page tabs ErrorDisplay (15 min)
13. **C2** — Rate limiting (1 hr)
14. **C3** — Security headers (15 min)
15. **C7** — Network security config (20 min)
16. **O1** — Version bump (2 min)
17. **O10** — Crash reporting (30 min)

### For real production:

18. **C4** — Database SSL
19. **C8** — Certificate pinning
20. **O9** — Server-side pagination
21. **O12** — Offline caching for non-scoring features

---

## Build Readiness Checklist

| Item | Status | Notes |
|------|--------|-------|
| API URL configurable via --dart-define | PASS | `String.fromEnvironment('API_BASE_URL')` with emulator default |
| WS URL configurable via --dart-define | PASS | `String.fromEnvironment('WS_BASE_URL')` with emulator default |
| Release signing configured | PASS | build.gradle.kts reads key.properties |
| key.properties gitignored | PASS | `.gitignore:44` |
| google-services.json gitignored | PASS | `.gitignore:40` |
| firebase-service-account.json gitignored | PASS | `.gitignore:41` |
| .env gitignored | PASS | `.gitignore:35-37` |
| Custom app icon | PASS | Cricket ball at all densities |
| App label = "CricScores" | PASS | AndroidManifest.xml:3 |
| INTERNET permission (release) | **FAIL** | Missing from main/AndroidManifest.xml |
| ProGuard/R8 enabled | **FAIL** | No minify/shrink in release buildType |
| Network security config | **FAIL** | File doesn't exist |
| Global error boundary | **FAIL** | No runZonedGuarded/FlutterError.onError |
| SQL injection protection | PASS | Drizzle ORM parameterized queries everywhere |
| Input validation (Elysia `t`) | PASS | Bodies validated with type/length/range constraints |
| File upload security | PASS | Type whitelist + size limit + sharp resize + path traversal check |
| Auth middleware on all routes | PASS | All route files use authMiddleware |
| Sensitive data in logs | PASS | No tokens/passwords/PII logged |
| Error handler doesn't leak internals | PASS | Returns generic messages, logs errors server-side |
| Test routes guarded | PARTIAL | NODE_ENV check exists but routes always registered |
| Database indexes | PASS | 35+ indexes on frequently queried columns |
| Database connection pooling | PASS | max: 10, idle_timeout: 20 |
| Health endpoint | PASS | /api/v1/health with DB check |

---

## Test Coverage Summary

| Area | Count | Notes |
|------|-------|-------|
| Flutter unit tests | ~2120 | Scoring engine (333+), features, shared |
| Server tests | ~420 | Services, routes |
| E2E integration | 1 full T20 | Scorer + viewer dual-emulator, 254 deliveries |
| Manual device testing | 2 devices | OPPO CPH2691, OnePlus EB2101 |

---

*This scan is a point-in-time assessment. Re-run after fixes are applied.*
