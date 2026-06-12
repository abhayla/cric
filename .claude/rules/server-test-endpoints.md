---
name: server-test-endpoints
description: >
  Rules for the two classes of test routes on the CricScores server: DB-touching
  testVerifyRoutes (double-guarded, test-env only) and always-registered DB-free
  testSignalRoutes. Defines the registration guard + handler guard contract.
globs: ["apps/server/src/routes/v1/test-verify.routes.ts", "apps/server/src/index.ts"]
synthesized: true
version: "1.0.0"
private: true
---

# Test Endpoint Rules

`apps/server/src/routes/v1/test-verify.routes.ts` exports TWO route groups with very different safety contracts. Never blur the line between them.

## Class (a): testVerifyRoutes — DB Access, Double-Guarded

`testVerifyRoutes` (prefix `/api/v1/test`) exposes direct DB query/mutation endpoints for E2E assertions (`/deliveries/:matchId`, `/reset-db`, ...). It MUST be protected by BOTH guards — registration AND handler:

**Guard 1 — conditional registration** in `apps/server/src/index.ts` (~lines 59-64). The module is not even imported outside test:

```ts
if (process.env.NODE_ENV === 'test') {
  const { testVerifyRoutes } =
    await import('./routes/v1/test-verify.routes.ts');
  app.use(testVerifyRoutes);
}
```

**Guard 2 — per-request re-guard** in `test-verify.routes.ts` (~lines 21-30). Even if the routes somehow get registered, every handler 403s outside test:

```ts
.onBeforeHandle(({ set, path }) => {
  if (path.endsWith('/health')) return;       // health check allowed anywhere
  if (process.env.NODE_ENV !== 'test') {
    set.status = 403;
    return { error: 'Test endpoints only available in test environment' };
  }
})
```

- BOTH guards are required. MUST NOT remove either one because "the other already covers it" — they defend against different failure modes (a refactor that registers unconditionally vs. an env var flipping at runtime).
- NEVER add a migration, truncation, seeding, or any other data-mutation endpoint outside this double-guarded class. If a test needs to mutate the DB, the endpoint goes inside `testVerifyRoutes`, behind both guards.
- New endpoints added to `testVerifyRoutes` inherit the `.onBeforeHandle` guard automatically — keep them in the SAME Elysia instance; do not create a sibling instance that bypasses it.

## /reset-db Seeds the Auth Test User

`POST /api/v1/test/reset-db` (~line 437) truncates data tables, re-seeds master data, AND seeds the test user with `firebaseUid: 'test-user-e2e-001'` (~lines 477-479) — matching `authMiddleware`'s TEST_USER and the WebSocket test bypass identity. If the test-user identity ever changes, it MUST change in all three places in the same commit: auth middleware, WebSocket handler (`apps/server/src/websocket/handler.ts`), and the `/reset-db` seed.

## Class (b): testSignalRoutes — Always Registered, MUST Stay DB-Free

`testSignalRoutes` (~lines 564-584) is registered unconditionally in `index.ts` (`.use(testSignalRoutes)`, ~line 57) — including production — because multi-device E2E tests coordinate against the prod server:

```ts
export const testSignalRoutes = new Elysia({ prefix: '/api/v1/test' })
  .post('/signal/:name', ({ params, body }) => {
    const value = (body as any)?.value ?? 'true';
    testSignals.set(name, { value, timestamp: Date.now() });
    return { signal: name, value, set: true };
  })
  .get('/signal/:name', ({ params }) => { /* read from Map */ })
```

Because it is always live, its contract is strict:

- MUST stay DB-free: signals live ONLY in the in-memory `testSignals` Map (~line 14) — ephemeral, cleared on restart. MUST NOT import `db` into a signal handler or persist signals.
- Signal operations MUST be idempotent per test (set/read/clear semantics) — no counters or side effects another test run could trip over.
- MUST NOT add authentication-bypassing, data-reading, or data-mutating behavior here. If an endpoint needs the DB, it belongs in class (a) behind the double guard — there is no third class.

## Adding a New Test Endpoint — Decision Table

| Need | Class | Where |
|---|---|---|
| Read/assert DB state in E2E | (a) | inside `testVerifyRoutes`, after the `.onBeforeHandle` guard |
| Reset/seed DB between tests | (a) | inside `testVerifyRoutes` (`/reset-db` pattern) |
| Cross-device coordination flag | (b) | inside `testSignalRoutes`, in-memory Map only |
| Anything mutating data in prod | NONE | forbidden — no exceptions |

## CRITICAL RULES

- MUST keep `testVerifyRoutes` behind BOTH the `NODE_ENV === 'test'` conditional import (index.ts ~59-64) AND the per-handler 403 re-guard (test-verify.routes.ts ~21-30) — never remove either.
- NEVER add a migration or data-mutation endpoint outside class (a)'s double guard.
- MUST keep `testSignalRoutes` DB-free (in-memory `testSignals` Map only) and idempotent — it is always registered, including production.
- MUST keep `/reset-db`'s seeded test user (`test-user-e2e-001`) in sync with authMiddleware's TEST_USER and the WebSocket test bypass — change all three together or none.
- MUST add new DB-touching test endpoints to the existing `testVerifyRoutes` Elysia instance so they inherit the guard — never a sibling instance.
