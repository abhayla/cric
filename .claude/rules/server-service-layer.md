---
name: server-service-layer
description: >
  Route/service separation for the CricScores server: thin Elysia routes (TypeBox
  validation, one service call, direct return), services owning transactions and
  raising AppError, and the central error handler as the only error formatter.
globs: ["apps/server/src/routes/v1/*.ts", "apps/server/src/services/*.ts"]
synthesized: true
version: "1.0.0"
private: false
---

# Service Layer Rules

Routes live in `apps/server/src/routes/v1/*.ts`; business logic lives in `apps/server/src/services/*.service.ts`. The boundary is strict.

## Routes Are Thin — Validate, Call One Service, Return

A route handler does exactly three things: validate input via the TypeBox schema, call ONE service function, return its result directly. `apps/server/src/routes/v1/players.ts` (~lines 27-129) is the reference shape:

```ts
export const playerRoutes = new Elysia({ prefix: '/api/v1/players' })
  .use(authMiddleware)
  .get(
    '/:id',
    async (ctx) => {
      validateUuid(ctx.params.id, 'player id');
      const profile = await getPlayerProfile(ctx.params.id);
      return { player: profile };
    },
    { params: t.Object({ id: t.String() }) },
  )
```

- Routes MUST NOT contain `db.transaction()` calls or multi-step DB access. If a handler needs two queries or any write sequence, that logic moves into a service function and the route calls it once.
- Validation lives in the TypeBox schema object (`body:`/`params:`/`query:` — see the enum unions built from `BATTING_STYLES`/`PLAYER_ROLES` constants in players.ts ~lines 13-25), plus `validateUuid()` from `middleware/error-handler.ts` for path IDs. MUST NOT hand-roll field validation inside the handler body.
- Status codes other than 200 are set via `ctx.set.status = 201` before returning (players.ts ~line 69) — not by constructing Response objects.
- Light glue is allowed: resolving the authenticated user (`getUserByFirebaseUid(firebaseUser.uid)`) and coercing query strings to numbers. Anything touching domain state is service territory.

## Services Own Transactions and Raise AppError

Service functions (`player.service.ts`, `scoring.service.ts`, `match.service.ts`, ...) own ALL `db.transaction()` handles and signal failure by throwing `AppError` with a specific code:

```ts
throw new AppError('NOT_FOUND', 'Match not found', 404);
throw new AppError('VALIDATION_ERROR', 'Cannot record delivery in a completed innings', 400);
throw new AppError('FORBIDDEN', 'Only the scorer can record deliveries', 403);
throw new AppError('UNAUTHORIZED', 'User not found', 401);
```

- Use the established codes (`VALIDATION_ERROR`, `NOT_FOUND`, `UNAUTHORIZED`, `FORBIDDEN`) with the matching HTTP status. MUST NOT invent ad-hoc code strings per call site — clients switch on these codes.
- Services MUST NOT touch Elysia types (`ctx`, `set`, response shaping). A service returns domain data or throws — nothing HTTP-shaped.

## One Error Formatter — the Central onError Handler

`errorHandler` in `apps/server/src/middleware/error-handler.ts` (~lines 46-79) is the ONLY place errors become JSON. It converts `AppError` → `{ error: { code, message, details? } }`, maps Elysia `NOT_FOUND`/`VALIDATION` codes, catches PG `22P02` (bad UUID) as 400, and falls back to `INTERNAL_ERROR` 500:

```ts
.onError(({ error, set }) => {
  if (error instanceof AppError) {
    set.status = error.statusCode;
    return toErrorResponse(error.code, error.message, error.details);
  }
  // ... NOT_FOUND / VALIDATION / 22P02 / INTERNAL_ERROR fallthrough
})
.as('global');
```

- Handlers MUST NOT try/catch-and-format errors themselves. Let `AppError` propagate to the central handler. The ONLY acceptable try/catch shapes in routes are: (a) log-and-rethrow for diagnostics (`scoring.ts` ~lines 103-110), and (b) isolating fire-and-forget broadcasts via `broadcastStatus` (see `server-websocket.md`) — never swallowing a service error into a 200.
- MUST NOT wrap responses in ad-hoc envelopes (`{ success: true, data: ... }`, `{ ok: ... }`). Success responses return the domain payload keyed by resource name (`{ player }`, `{ players }`, `{ stats }`); errors are exclusively the central handler's `{ error: { code, message, details } }` shape.
- New cross-cutting error classes (e.g. a new PG error code worth a 4xx) go INTO `error-handler.ts` — never duplicated per route.

## Adding a New Endpoint — Checklist

1. Service function in the matching `*.service.ts`: takes plain args, owns any transaction, throws `AppError` on failure, returns domain data.
2. Route in `routes/v1/`: TypeBox schema, `validateUuid()` for path IDs, one service call, `{ resourceName: result }` return, `ctx.set.status` for 201/etc.
3. Registered in `apps/server/src/index.ts` on the single Elysia chain — after `errorHandler` so the global `onError` covers it.

## CRITICAL RULES

- Routes MUST NOT contain transaction logic or multi-step DB access — validate via TypeBox, call exactly ONE service function, return its result directly (`players.ts` is the reference shape).
- Services own ALL `db.transaction()` handles and raise `AppError` with the established codes (`VALIDATION_ERROR`, `NOT_FOUND`, `UNAUTHORIZED`, `FORBIDDEN`) — never HTTP/Elysia types inside services.
- The central `errorHandler` (`middleware/error-handler.ts` ~46-79) is the ONLY error formatter — handlers MUST NOT try/catch-and-format errors (log-and-rethrow and broadcast isolation are the only exceptions) and MUST NOT swallow a service error into a success response.
- MUST NOT wrap responses in ad-hoc envelopes — success is `{ resourceName: data }`; error is exclusively the central `{ error: { code, message, details } }` shape.
- New error mappings go into `error-handler.ts`, never duplicated per route.
