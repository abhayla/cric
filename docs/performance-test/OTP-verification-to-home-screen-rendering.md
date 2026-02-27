# Cold Start Performance: OTP Verification to Home Screen Rendering

## Overview

This document captures performance measurements for the app's cold start flow — from Firebase initialization through OTP verification to the home screen fully rendering with data. All measurements taken on the `Resizable_Experimental` Android emulator running the `perf_basic_test.dart` integration test against the prod server (`cricscores.in`).

## Test Configuration

| Parameter | Value |
|-----------|-------|
| Test file | `integration_test/tests/perf_basic_test.dart` |
| Device | `emulator-5554` (Resizable_Experimental) |
| Build | `--flavor prod --dart-define=FLAVOR=prod` (debug APK) |
| Server | `cricscores.in` (VPS at `103.118.16.189`) |
| Firebase project | `cricapp-7403d` |
| Test phone | `9999999999` (Firebase test number, OTP: `123456`) |
| Teams used | Team3 / Team4 (11 players each, pre-created) |
| Match config | 5 overs, 6 players per side |
| Random seed | `42` (deterministic) |

---

## Run 1 — Baseline (2026-02-27, no instrumentation)

**Total test time:** 178.2s

### Cold Start: 19.6s (single aggregate number, no per-step breakdown)

### Full Performance Report

| Phase | Time | Details |
|-------|------|---------|
| Cold Start | 19.6s | Firebase init + login + home render |
| Team Verification | 2.5s | Navigate to Teams tab, tap "All", verify Team3/Team4 |
| Match Setup | 15.5s | Select teams, set overs/players, proceed to toss |
| Toss Wizard | 17.6s | 5-step wizard: toss winner, decision, XI-A, XI-B, openers |
| First Over (6 del) | 6.3s | Runs: [1, 0, 4, 2, 1, 0], avg 1047ms/del |
| Undo + Redo | 2.0s | Undo last ball + re-record as dot |
| Over Transition | 3.6s | Bowler selection sheet |
| 1st Innings Total | 51.7s | 29 deliveries, 43/1, avg 1782ms/del |
| Innings Transition | 8.0s | Modal + select openers + bowler |
| 2nd Innings Total | 47.7s | 32 deliveries, 38/0, avg 1491ms/del |
| Match Complete | 5.0s | Wait for modal, capture result, dismiss |
| Navigation Sweep | 5.0s | 6 screens, avg 831ms/screen |
| **TOTAL** | **178.2s** | |

### Navigation Sweep Detail

| Screen | Time |
|--------|------|
| Home | 0.1s |
| Teams | 1.1s |
| Matches | 1.2s |
| Live | 1.2s |
| Updates | 1.3s |
| Back to Home | 0.1s |

### Match Result
- **Team3 won by 5 runs** (43/1 vs 38/0)

---

## Run 2 — Instrumented (2026-02-27, per-step timing)

**Total test time:** 176.5s

### Cold Start Breakdown: 17.2s

Added `Stopwatch` instrumentation to each step of `pumpAppAndWaitForHome()` and `_loginWithTestPhone()`.

| Step | What Happens | Time | % of Cold Start |
|------|-------------|------|-----------------|
| 1 | `Firebase.initializeApp()` | **163ms** | 0.9% |
| 2 | `pumpWidget()` — build full widget tree + create in-memory Drift DB + mount `ProviderScope` + `CricScores` + `MaterialApp.router` + `GoRouter` | **1,906ms** | 11.1% |
| 3 | Splash → login redirect — polls 10 × 500ms for `GoRouter` auth guard to redirect from `/` (splash) to `/login` | **5,584ms** | 32.4% |
| 4 | Phone number entry — find `TextField`, enter `9999999999`, pump 300ms | **581ms** | 3.4% |
| 5 | Send OTP → OTP page — tap "Send OTP" button, Firebase `verifyPhoneNumber()` round-trip to Firebase servers, wait for `codeSent` callback, poll for OTP page UI | **4,440ms** | 25.8% |
| 6 | OTP digit entry — find 6 `TextField` widgets, enter digits 1-6 with 100ms delays between each | **2,044ms** | 11.9% |
| 7 | OTP verify → home redirect — Firebase `signInWithCredential()`, `authStateChanges` stream emits, `_AuthNotifier` fires, GoRouter redirect `/otp` → `/home`, `_registerWithServer()` fires | **1,965ms** | 11.4% |
| 8 | Home page poll — check if "My Cricket" text is visible (already there from step 7) | **0ms** | 0.0% |

### API Calls After Home Screen Renders

These fire in parallel once the home page widget tree builds and providers are watched:

| API Call | Endpoint | Time | Triggered By |
|----------|----------|------|-------------|
| `POST /auth/verify` | `/api/v1/auth/verify` | **1,206ms** | `AuthNotifier._registerWithServer()` — upserts Firebase user into PostgreSQL `users` table |
| `GET /auth/me` | `/api/v1/auth/me` | **1,056ms** | `currentUserIdProvider` — fetches server-assigned UUID for profile avatar link |
| `GET /teams` | `/api/v1/teams` | **1,398ms** | `teamsListProvider` (AsyncNotifier) — populates Teams sub-tab on My Cricket page |
| `GET /matches` | `/api/v1/matches` | **591ms** | `allMatchesProvider(1)` — populates Matches sub-tab (fired during nav sweep, not cold start) |
| `GET /tournaments` | `/api/v1/tournaments` | *not fired* | `tournamentsListProvider` — lazy, only fires when Tournaments tab is tapped |

### Full Performance Report

| Phase | Time | Details |
|-------|------|---------|
| Cold Start | 17.2s | Instrumented (see breakdown above) |
| Team Verification | 2.7s | Navigate to Teams tab, tap "All", verify Team3/Team4 |
| Match Setup | 15.6s | Select teams, set overs/players, proceed to toss |
| Toss Wizard | 17.5s | 5-step wizard |
| First Over (6 del) | 6.3s | avg 1047ms/del |
| Undo + Redo | 2.0s | |
| Over Transition | 3.6s | |
| 1st Innings Total | 51.8s | 29 del, 43/1, avg 1787ms/del |
| Innings Transition | 8.0s | |
| 2nd Innings Total | 47.9s | 32 del, 38/0, avg 1498ms/del |
| Match Complete | 5.0s | |
| Navigation Sweep | 5.1s | 6 screens, avg 845ms/screen |
| **TOTAL** | **176.5s** | |

### Navigation Sweep Detail

| Screen | Time |
|--------|------|
| Home | 0.1s |
| Teams | 1.2s |
| Matches | 1.3s |
| Live | 1.1s |
| Updates | 1.3s |
| Back to Home | 0.1s |

### Match Result
- **Team3 won by 5 runs** (43/1 vs 38/0)

---

## Architecture: What Happens During Cold Start

### Step-by-step flow

```
Firebase.initializeApp()
    │
    ▼
pumpWidget(ProviderScope(CricScores()))
    │   ├── AppDatabase(NativeDatabase.memory())     ← in-memory Drift DB
    │   ├── ProviderScope with database override
    │   ├── CricScores → MaterialApp.router
    │   └── GoRouter(initialLocation: '/')           ← starts on splash
    │
    ▼
Splash → Login Redirect
    │   ├── authStateProvider (StreamProvider<User?>)
    │   │     └── 5s timeout if Firebase doesn't emit
    │   ├── GoRouter.redirect() evaluates:
    │   │     isLoading=true → stay on splash
    │   │     isLoggedIn=false → redirect to /login
    │   └── 10 × pump(500ms) fixed polling
    │
    ▼
Login Page
    │   ├── Enter phone number into TextField
    │   └── Tap "Send OTP"
    │
    ▼
Firebase Phone Auth Round-trip
    │   ├── verifyPhoneNumber() → Firebase servers
    │   ├── codeSent callback fires
    │   └── OTP page renders
    │
    ▼
OTP Page
    │   ├── Enter 6 digits into 6 TextFields
    │   └── Auto-verify triggers signInWithCredential()
    │
    ▼
Auth State Change → Home Redirect
    │   ├── FirebaseAuth.signInWithCredential() succeeds
    │   ├── _registerWithServer() → POST /auth/verify (fire-and-forget-ish)
    │   ├── authStateChanges stream emits User
    │   ├── _AuthNotifier.notifyListeners()
    │   ├── GoRouter.redirect(): isLoggedIn=true, on auth route → /home
    │   └── ShellRoute builds _AppShell (4-tab bottom nav)
    │
    ▼
Home Page Renders
    │   ├── HomePage (ConsumerStatefulWidget)
    │   │     ├── TabController(length: 3) — Teams / Matches / Tournaments
    │   │     ├── AppBar with "My Cricket" title + profile avatar
    │   │     └── ExpandableFab (Start Match, Create Team, Create Tournament)
    │   │
    │   ├── Parallel API calls fire:
    │   │     ├── GET /auth/me        (currentUserIdProvider)   ~1.1s
    │   │     ├── POST /auth/verify   (_registerWithServer)     ~1.2s
    │   │     ├── GET /teams          (teamsListProvider)        ~1.4s
    │   │     └── GET /matches        (allMatchesProvider)       lazy*
    │   │
    │   └── Sub-tabs render data or loading spinners
    │
    ▼
Home Screen Ready
```

*`GET /matches` and `GET /tournaments` are lazy — they fire when their respective sub-tabs are first viewed.*

### Provider dependency chain

```
authStateProvider (StreamProvider<User?>)
    │
    ├── currentUserIdProvider (FutureProvider<String?>)
    │     └── GET /auth/me
    │
    ├── GoRouter.redirect (via _AuthNotifier)
    │     └── Navigates to /home when authenticated
    │
    └── Each feature's _dioProvider
          └── addAuthInterceptors(dio, firebaseAuthDatasource)
                ├── onRequest: inject Bearer token
                └── onError: 401 → FirebaseAuth.signOut() → redirect to login
```

---

## Analysis & Optimization Opportunities

### Biggest time sinks

| Rank | Step | Time | Potential Savings | Approach |
|------|------|------|-------------------|----------|
| 1 | Splash redirect polling | 5,584ms | ~5,000ms | Reduce from 10 to 2-3 pumps, or use event-driven wait instead of fixed polling |
| 2 | Firebase OTP round-trip | 4,440ms | Minimal | Network latency to Firebase servers — not controllable |
| 3 | OTP digit entry | 2,044ms | ~1,500ms | Enter all 6 digits at once instead of one-by-one with 100ms delays |
| 4 | OTP verify → home | 1,965ms | Minimal | Includes signInWithCredential + server registration + GoRouter redirect |
| 5 | pumpWidget | 1,906ms | Minimal | Widget tree construction — inherent cost of Flutter framework |

### Splash redirect polling (5.6s wasted)

The biggest optimization target. Current code:
```dart
// Wait for initial route to render (splash → login redirect)
for (var i = 0; i < 10; i++) {
  await tester.pump(const Duration(milliseconds: 500));
}
```

The login page appeared at "0ms" in both runs, meaning the auth state resolved immediately (Firebase was already initialized, no cached session). All 10 pumps are unnecessary waiting. This could be replaced with an event-driven wait:
```dart
// Wait for login page OR home page to appear
for (var i = 0; i < 20; i++) {
  await tester.pump(const Duration(milliseconds: 250));
  if (find.text('Send OTP').evaluate().isNotEmpty ||
      find.text('My Cricket').evaluate().isNotEmpty) break;
}
```

**Note:** This is test infrastructure overhead, not app performance. Real users don't experience this 5.6s — it only affects E2E test duration.

### Server API latency (~1-1.4s per call)

All API calls go to `cricscores.in` (VPS at `103.118.16.189` via Cloudflare). Latency breakdown:
- DNS resolution (Cloudflare edge)
- TLS handshake (Cloudflare Flexible SSL)
- HTTP request to Nginx reverse proxy on VPS
- Nginx → localhost:3005 (Bun server)
- PostgreSQL query
- Response back through the chain

For real users, this latency will vary based on their network. The ~1s average is reasonable for an Indian VPS serving Indian users.

---

## Known Issues Observed During Test

1. **Undo button hit-test warning** — The undo icon at `Offset(36.0, 850.3)` is partially obscured by a bottom sheet. The tap works but logs a Flutter warning.

2. **`Infinity` JSON serialization bug** — `[ScoringPersistenceService] WS publish error: Converting object to an encodable object failed: Infinity` — division by zero producing `Infinity` in JSON during WebSocket broadcast. Occurs in 2nd innings.

3. **Stale SelectBowlerSheet** — The bowler selection bottom sheet sometimes lingers after being dismissed, triggering "auto-clear" fallback logic multiple times per innings.

---

## Instrumentation Added

Timing instrumentation was added to 6 files (all guarded behind `kDebugMode` for production safety):

| File | What's Timed |
|------|-------------|
| `integration_test/core/app_bootstrap.dart` | 8 cold-start steps via Stopwatch |
| `lib/src/app/providers.dart` | `GET /auth/me` in `currentUserIdProvider` |
| `lib/src/features/auth/presentation/notifiers/auth_notifier.dart` | `POST /auth/verify` in `_registerWithServer()` |
| `lib/src/features/home/providers.dart` | `GET /matches` in `allMatchesProvider` |
| `lib/src/features/teams/providers.dart` | `GET /teams` in `_fetchTeams()` |
| `lib/src/features/tournaments/providers.dart` | `GET /tournaments` in `_fetchTournaments()` |
