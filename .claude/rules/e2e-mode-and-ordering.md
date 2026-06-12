---
name: e2e-mode-and-ordering
description: >
  E2E runs MUST pick exactly one flavor (dev vs prod) per run and respect the
  numbered test ordering — file numbers encode a load-bearing dependency chain.
globs: ["apps/mobile/integration_test/tests/*.dart"]
synthesized: true
version: "1.0.0"
private: false
---

# E2E Modes and Test Ordering

## Modes — one flavor per run, never mixed

Every test file header documents both invocations (see
`01_team_setup_test.dart`, lines 19-28):

```bash
# Dev — local Bun server on port 3001 (emulator reaches it as 10.0.2.2:3001)
flutter test --flavor dev integration_test/tests/01_team_setup_test.dart -d emulator-5554

# Prod — cricscores.in
flutter test --flavor prod --dart-define=FLAVOR=prod \
  integration_test/tests/01_team_setup_test.dart -d emulator-5554
```

- MUST NOT mix flavors within one run/sequence — dev and prod hit different
  databases, so cross-flavor state assumptions silently fail.
- Signal endpoints (`/api/v1/test/signal/*`, `/api/v1/test/reset-match-data`)
  exist ONLY against a `NODE_ENV=test` server. A prod run cannot rely on them.
- Multi-device tests add `--dart-define=ROLE=scorer|viewer`; the spectator
  test additionally accepts `--dart-define=VIEWER_PHONE=<phone>`.
- Real devices cannot reach `10.0.2.2` — they need
  `--dart-define=API_BASE_URL=http://<LAN_IP>:3001/api/v1` and
  `--dart-define=WS_BASE_URL=ws://<LAN_IP>:3001/ws`. Do not hand-roll these:
  `scripts/multi-device-e2e.sh` detects the LAN IP and injects them into the
  real-device role only (script lines 180-239).

## Ordering — numbers are a dependency DAG, not decoration

Files `01`–`11` share one server/DB state. The canonical chain (documented in
`01_team_setup_test.dart`, lines 6-17):

```
01 → 02 → 03 → {04, 05, 06} → 07 → 08 → 09
```

- **01** creates the 12 standard teams — required by everything after it. It
  is idempotent check-then-skip setup: it verifies existing rosters via API
  and only creates what is missing, so re-running it is always safe.
- Even-numbered "do" tests feed odd-numbered "verify" tests: 03 verifies the
  match 02 scored; 07 sweeps screens populated by 01-06.
- Running a verify test without its producer yields false failures, not
  errors — e.g., 03's `verifyMatchesTab(minAllCount: 1)` fails on an empty DB.

Every test file MUST carry a `## Test Ordering Dependencies` doc-comment
naming its prerequisites (today only 01 and 10 have the section — new and
edited files MUST add it, using the block in `01_team_setup_test.dart` lines
6-17 as the template).

## Alternatives when you cannot run the full chain

- Need only one test mid-chain? Run `01` first (cheap when teams exist —
  check-then-skip), then your target test.
- Need pristine state on a test server? `POST /api/v1/test/reset-match-data`
  then run from 01 (this is what `scripts/multi-device-e2e.sh` does, line 280).
- Writing a test with no dependency on shared teams? Claim an isolated team
  range per the e2e-test-data-naming rule instead of joining the chain.

## CRITICAL RULES

- MUST run an entire E2E sequence under a single flavor; dev = `--flavor dev`,
  prod = `--flavor prod --dart-define=FLAVOR=prod`.
- MUST NOT depend on `/api/v1/test/*` endpoints outside a `NODE_ENV=test`
  server.
- MUST let `scripts/multi-device-e2e.sh` inject `API_BASE_URL`/`WS_BASE_URL`
  for real devices rather than hardcoding LAN IPs in test files.
- MUST respect the 01→…→09 ordering and document prerequisites in a
  `## Test Ordering Dependencies` comment in every test file.
- Test 01 MUST stay idempotent (check-then-skip) — never convert it to
  unconditional creation.
