---
name: bracket-prefixed-logging
description: >
  CricScores logs MUST carry a bracketed [Subsystem] prefix on both platforms, and every
  Flutter log MUST be guarded by if (kDebugMode) and emitted via debugPrint — never a bare
  print() and never an unguarded log that ships in a release build.
globs: ["apps/mobile/lib/**/*.dart", "apps/server/src/**/*.ts"]
synthesized: true
version: "1.0.0"
private: false
---

# Bracket-Prefixed Logging

Every diagnostic log line in this codebase opens with a `[Tag]` that names the subsystem
emitting it, so logs can be grep-filtered by area. This holds across both the Flutter app
(44+ call sites) and the Bun server. New logging MUST follow the same shape.

## Flutter: `if (kDebugMode) debugPrint('[Tag] …')`

```dart
if (kDebugMode) {
  debugPrint('[AuthNotifier] OTP verification failed: $e');
}
```

- MUST wrap every log in `if (kDebugMode)` (40+ existing guards) so nothing logs in a release
  build. The guard is the rule even for one-liners.
- MUST use `debugPrint` (it throttles to avoid dropped lines on Android), never `print()`.
- MUST open the message with a `[Tag]`. Established tags include `[CricScores]` (app-level /
  uncaught errors — see `lib/main.dart` ~lines 19-32), `[AuthNotifier]`, `[Router]`,
  `[API-timing]`, `[CreateTeam]`. Reuse an existing tag when one fits; introduce a new
  `[Feature]` tag named after the feature directory otherwise.
- MUST NOT introduce a logging package or `Logger` abstraction — the project deliberately uses
  guarded `debugPrint` only.

## Server: `console.<level>('[Subsystem] …')`

```ts
console.error('[Scoring] recordDeliveryBatch failed', err);
console.warn('[Broadcast error after delivery]', err);
```

- MUST prefix server logs with a `[Subsystem]` tag: `[Scoring]`, `[ActivityFeed]`,
  `[Broadcast error after …]`, `[postgres]`, `[database]` are in use (see
  `src/routes/v1/scoring.ts` ~lines 108/119/399, `src/index.ts`).
- Broadcast/side-effect failures MUST be logged with their context tag and then swallowed so
  they do not fail the HTTP response (the route still returns its result with a
  `broadcastStatus` field). Logging is the recovery signal — see `server-websocket` for the
  fire-and-forget broadcast contract.

## Why

The bracketed prefix is the only structured-logging convention the project relies on. A log
line without a `[Tag]`, or an unguarded Flutter log, breaks `grep`-based triage and risks
leaking diagnostics into a shipped APK. When in doubt, match the nearest existing log in the
same file.
