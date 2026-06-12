---
name: e2e-signal-handshake
description: >
  Multi-device E2E tests MUST synchronize scorer and viewer roles via the
  server's HTTP signal endpoints — never via sleeps or blind timeouts.
globs: ["apps/mobile/integration_test/tests/*_live_test.dart", "apps/mobile/integration_test/tests/spectator_live_test.dart"]
synthesized: true
version: "1.0.0"
private: false
---

# E2E Signal Handshake — HTTP signals, never sleeps

Two devices running the same test file (selected by `--dart-define=ROLE=scorer|viewer`)
MUST coordinate through the test server's signal endpoints:

- `POST /api/v1/test/signal/:name` with body `{"value": "..."}` — set a signal
- `GET /api/v1/test/signal/:name` — read a signal (poll until `value != null`)
- `DELETE /api/v1/test/signals` — clear ALL signals

These endpoints exist only on a `NODE_ENV=test` server. The canonical
implementations are `08_viewer_live_test.dart` (scorer: lines ~115-143,
viewer: lines ~292-328) and `spectator_live_test.dart` (lines ~122-150).

## The handshake protocol

1. **Stale-signal clear (scorer only).** The scorer calls `clearTestSignals()`
   from `core/app_bootstrap.dart` (lines 79-94) at test start. The viewer MUST
   NOT clear signals — it could race and wipe a `scorer-ready` already posted.
2. **Scorer** finishes match setup + toss, posts `scorer-ready`, then polls
   `viewer-ready` every 2s with a 300s deadline.
3. **Viewer** polls `scorer-ready` (2s interval, 300s deadline), navigates to
   the Live page, connects via WebSocket, then posts `viewer-ready`.
4. **Milestones** are context-named and strictly ordered:
   `score-innings1-complete` → `score-match-complete`. The spectator variant
   prefixes every signal: `spectator-scorer-ready`, `spectator-viewer-ready`,
   `spectator-score-match-complete` — never reuse the unprefixed names, or a
   concurrent 08 run will cross-trigger.
5. **Payloads carry data.** `score-match-complete` carries a serialized score
   checkpoint; the viewer parses it via `ScoreCheckpoint.fromSignalValue()`
   for cross-device score verification (08, lines ~377-381).

## Failure semantics are asymmetric — copy them exactly

- **Scorer waiting on `viewer-ready`: non-fatal.** Log a WARNING and proceed
  scoring (08, lines 137-143). The scorer's match data is valuable even if the
  viewer never launched.
- **Viewer waiting on `scorer-ready`: FATAL.** `fail('[VIEWER] Scorer not
  ready after 300s')` (08, lines 311-313) — a viewer with no scorer has
  nothing to observe.
- **Posting a signal: non-fatal.** Wrap in try/catch and proceed; the endpoint
  may not exist against a non-test server.
- **Viewer waiting on `score-match-complete`:** poll inside the observation
  loop (8-minute deadline), then `expect(matchSignalValue, isNotNull)` — the
  assertion is the failure point, not the poll.

## CRITICAL RULES

- MUST synchronize via `/api/v1/test/signal/:name` polling (2s interval,
  explicit deadline). MUST NOT use `Future.delayed` sleeps or blind timeouts
  as a substitute for a signal wait.
- MUST clear stale signals at start — from the scorer role only, via
  `clearTestSignals()` in `core/app_bootstrap.dart`.
- MUST name milestone signals by context (`score-innings1-complete`, not
  `step1`) and post them in strict order; spectator tests MUST prefix all
  signal names with `spectator-`.
- MUST keep scorer-side waits non-fatal (warn + proceed) and viewer-side
  `scorer-ready` waits fatal — do not invert this.
- SHOULD pass verification data through signal values (checkpoint payloads)
  instead of re-querying the API on the other device.
