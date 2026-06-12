---
name: flutter-feature-boundaries
description: >
  Cross-feature import boundaries: a feature may consume another feature's
  domain entities and presentation widgets/pages, but never its data layer or
  repository interfaces. Enforced deterministically by a Write-time hook.
globs: ["apps/mobile/lib/src/features/**/*.dart"]
synthesized: true
version: "1.0.0"
private: false
---

# Cross-Feature Import Boundaries

Features under `apps/mobile/lib/src/features/` are vertical slices
(`scoring/`, `teams/`, `tournaments/`, `auth/`, ...), each with
`data/` → `domain/` → `presentation/` layers. Cross-feature coupling is
allowed only at the surfaces designed for sharing. All 8 existing
cross-feature imports comply; there are 0 data-layer violations — keep it
that way.

## What a feature MAY import from another feature

| Surface | Allowed? | Why |
|---|---|---|
| `features/<other>/domain/entities/*.dart` | YES | Entities are the shared vocabulary (e.g., scoring consumes team/player entities) |
| `features/<other>/presentation/widgets/*.dart` | YES | Reusable rendered components |
| `features/<other>/presentation/pages/*.dart` | YES | Navigation targets |
| `features/<other>/domain/repositories/*.dart` | **NEVER** | Repository interfaces are internal contracts between a feature's own data and presentation layers |
| `features/<other>/data/**` (models, datasources, repositories impl) | **NEVER** | The data layer is private; raw models bypass the `toEntity()` boundary (`flutter-model-entity-mapping.md`) |

## Exception: auth entities are app-wide

`auth` domain entities (notably `AppUser`) are shared across the whole app —
any feature MAY import
`features/auth/domain/entities/...`. This is the only blanket exception; do
not generalize it to other features' internals.

## How to get data from another feature (the alternative)

When feature B needs data that feature A's data layer owns, do NOT import
A's datasource or repository. Instead:

1. **Consume A's providers** — each feature exposes its state through its
   `providers.dart` (e.g., `apps/mobile/lib/src/features/scoring/providers.dart`).
   Watch/read the provider; receive domain entities.
2. **Receive entities via navigation args** — scoring receives
   `PlayingXIPlayer` lists through `ScoringPageArgs` rather than re-fetching
   from the teams data layer.
3. **Promote to shared** — if infrastructure is genuinely cross-feature
   (database, sync, websocket), it belongs in `apps/mobile/lib/src/shared/`
   (e.g., `shared/data/sync/sync_service.dart`), not in any single feature.

## Deterministic enforcement

`.claude/hooks/guard-cross-feature-imports.ps1` blocks violating imports at
Write-time. This rule documents the boundary and its exceptions so you design
within it up front instead of discovering it when the hook rejects your edit.
If the hook blocks you, the fix is to restructure per the alternatives above —
NEVER to bypass or weaken the hook.

## CRITICAL RULES

- A feature MUST NEVER import another feature's `data/` layer (models,
  datasources, repository implementations) or `domain/repositories/`
  interfaces.
- A feature MAY import another feature's `domain/entities/` and
  `presentation/widgets|pages/` — these are the only sanctioned sharing
  surfaces.
- `auth` domain entities (`AppUser`) are the single app-wide exception —
  importable from anywhere; do NOT extend this exception to other features.
- Cross-feature data needs MUST be met via the other feature's
  `providers.dart`, navigation args, or promotion to
  `apps/mobile/lib/src/shared/` — never by reaching into its data layer.
- MUST NOT weaken or bypass `guard-cross-feature-imports.ps1` to land a
  change — restructure the dependency instead.
