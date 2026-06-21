---
name: server-bun-test-db-errors
description: >
  How to assert on rejected promises in the CricScores Bun server tests: DB-touching
  promises MUST use the expectToReject() try/catch helper (Bun's .rejects.toThrow()
  hangs on postgres.js promises), and fail-fast validation MUST sit before
  db.transaction() so it never runs inside the hanging path.
globs: ["apps/server/test/**/*.test.ts", "apps/server/src/services/*.service.ts"]
synthesized: true
version: "1.0.0"
private: false
---

# Bun Test DB-Error Assertions

The Bun test runner (confirmed v1.3.9) **hangs indefinitely** when `.rejects.toThrow()`
wraps a promise that performs a Drizzle / `postgres.js` database operation. The hang is
specific to promises holding a DB connection — plain `Error` throws are unaffected. This
rule encodes the two patterns the codebase uses to live with that bug.

## DB-touching rejections MUST use `expectToReject()`

When the code under test reaches the database before throwing (any service call that runs a
query inside `db.transaction()` or against `postgres.js`), assert with the local
`expectToReject()` helper — a plain `try/catch` wrapper — NOT `await expect(fn()).rejects.toThrow()`.

The helper is defined inline at the top of each test file that needs it (e.g.
`test/services/player.service.test.ts` ~line 23, `test/integration/player-stats-e2e.test.ts` ~line 32):

```ts
async function expectToReject(fn: () => Promise<unknown>, msgSubstring?: string) {
  let threw = false;
  try {
    await fn();
  } catch (err) {
    threw = true;
    if (msgSubstring) expect((err as Error).message).toContain(msgSubstring);
  }
  expect(threw).toBe(true);
}

// usage — a service call that touches the DB before rejecting:
await expectToReject(() => recordDelivery(badInput), 'match is not live');
```

- MUST use `expectToReject()` for any assertion on a service function that opens a transaction or queries Postgres.
- MUST NOT replace it with `.rejects.toThrow()` / `.rejects.toThrowError()` for those calls — the suite will hang, not fail, and CI will time out.
- The helper is intentionally duplicated per test file (top-level function). This is the project's accepted exception to DRY for tests — do NOT hoist it into a shared import; keeping it inline avoids a cross-file test dependency.

## Plain (non-DB) throws MAY keep `.rejects.toThrow()`

`.rejects.toThrow()` is still correct — and used ~29 times across the suite — for promises
that reject **before** any DB access (input-shape validation, guard clauses, pure helpers).
Do NOT mass-rewrite those. The deciding question is: *does the awaited code reach the database
on the failing path?* If yes → `expectToReject()`. If no → either form is fine.

## Fail-fast validation MUST precede `db.transaction()`

Move match-status, scorer-auth, and input-shape checks **above** the `db.transaction()` call
(see `src/services/scoring.service.ts` ~lines 451-478 — pre-validation, then the transaction
opens at ~line 480). Two reasons: (1) fail-fast avoids opening a transaction only to roll it
back, and (2) a throw raised before the transaction is a plain rejection, sidestepping the Bun
hang entirely. Only re-fetch genuinely race-sensitive state (the match row, the innings cache)
*inside* the transaction.

## Running the suite

Always run the full suite with `bun run test` (not `bun test`) — the script sets
`--max-concurrency=1` and `ENABLE_TEST_AUTH=true` to avoid DB contention. For a single file:
`NODE_ENV=test ENABLE_TEST_AUTH=true bun test path/to.test.ts`.
