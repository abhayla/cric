# CricApp - Continue Prompt

## Context for Resuming Work

**Project:** CricApp - Cricket scoring mobile app (CricHeroes competitor)
**Status:** Planning complete, implementation not yet started
**Working Directory:** `C:\Abhay\VideCoding\cric\`

## Tech Stack

See [CLAUDE.md](../CLAUDE.md#tech-stack) for tech stack.

## Documentation

See [PROJECT_MANAGEMENT.md](process/PROJECT_MANAGEMENT.md) for the full documentation map with all planning and process docs.

## What to Do Next

Start with **Phase 1: Foundation** as described in `docs/planning/IMPLEMENTATION_PLAN.md`:

1. Initialize Flutter project (`apps/mobile/`) with the folder structure from Section 2.1
2. Initialize Bun server (`apps/server/`) with the folder structure from Section 2.2
3. Set up PostgreSQL + Drizzle schema using tables from `docs/planning/DATABASE.md`
4. Seed master data (dismissal types, fielding positions, wagon wheel zones, ball types)
5. Set up Firebase project + configure Flutter Firebase
6. Implement Firebase Auth (phone OTP + Google sign-in)
7. Implement auth middleware on Bun (Firebase JWT verification)
8. Set up Material 3 dark theme
9. Set up go_router with auth guards
10. Build screens: Splash, Login, OTP, Profile Setup

## Key Design Decisions Already Made

- Ball-by-ball granularity (every delivery stored)
- UUIDs for all primary keys (sync-friendly)
- 12-zone wagon wheel system (30-degree segments)
- Pre-computed stats per innings + career aggregates
- JSONB for graph data in match_analytics
- Offline-first with sync queue in local SQLite
- Scorer = publisher, viewers = subscribers in WebSocket rooms
- Anonymous WebSocket viewers (no auth required for read-only)
- Free hit tracking on no-balls; free hit persists through wides
- Byes/leg-byes don't break maidens
- No SUPER_OVER — tied match → COMPLETED with "Match Tied"
- No DLS calculations or shot types tables (deferred / not needed for MVP)
- Partnerships deferred to post-MVP (compute from deliveries later)
- Teams use soft delete (`is_active` boolean)
- WebSocket heartbeat via protocol-level ping/pong (30s interval, 5s timeout)
- Sync ordering: match → innings → deliveries → stats
- Server-wins conflict resolution (silent overwrite)
- Local ID → server ID mapping table (no mass FK updates)
- Offset-based pagination (`?page=1&limit=20`) on all endpoints
- Every table has `created_at` + `updated_at`
- `match_players` table for Playing XI (replaces inline approach)
- `innings_stats` dropped — 3 computed columns moved to `innings` table
- Firebase JWT directly (no server-issued JWT)
- scorer_id lock for concurrent scoring prevention
- Scorer picks crossed/not-crossed explicitly on run out
- Wicket on last ball order: Wicket → New Batter → New Bowler
- Bowler over limit: `ceil(totalOvers / 5)` per bowler
- Declaration behind "Set" button; abandonment stats DO count in career
- 5-run penalty supported with full UI flow
- Custom run input (overthrows) + custom extras input
- M3 dark theme: seed color #2E7D32, Roboto, Material Symbols, portrait lock
- 8dp grid spacing system, M3 default transitions only
- Scoring page: fixed header (top) + scrollable middle + fixed buttons (bottom)
- Initials-only avatar for MVP; simple file picker for team logo (no crop)
- Minimal settings in Profile (logout + app version)
- Single login screen with tabs: Phone OTP | Google | Email
- Home dashboard: recent matches, quick actions, my stats card
- Deployment: existing VPS (Win Server 2022, PostgreSQL 16.8, Nginx, PM2, Cloudflare, GitHub Actions)
- WebSocket delivery message matches REST fields; reconnect via REST snapshot (no replay)
- `total_runs` computed at application level; overs decimal notation utility on both platforms

## Completed Work

### Step 0: Planning Doc Updates (Gap Analysis)
A comprehensive gap analysis resolved 120 decisions across 22 rounds of Q&A. All planning docs have been updated:
- **DATABASE.md:** Dropped `dls_calculations` and `shot_types` tables. Added `is_retired_hurt` to `batting_stats`, `is_active` to `teams`. Removed `super_over` from match status enum and `match_result.result_type`. Added full `sync_queue` and `local_preferences` schemas in Local-Only Tables section.
- **API.md:** Added `GET /api/v1/players/search` (player search by name) and `DELETE /api/v1/teams/:id` (soft delete team) endpoints.
- **SCORING_RULES.md:** Removed SUPER_OVER state from state machine. Tied match → COMPLETED with "Match Tied".
- **IMPLEMENTATION_PRACTICES.md:** Updated match state machine test list (6 states, no SUPER_OVER).
- **CLAUDE.md:** Updated match state machine description to reflect tied match handling.

### Step 0b: Missed Q1-Q18 Doc Fixes
4 decisions from Q1-Q18 that were missed in the original Step 0 have now been applied to DATABASE.md:
- **ball_types seed values:** Added "other" → now `leather, tennis, tape, other` (Gap 77)
- **bowling_style enum:** Replaced vague "etc." with full 9-value enum: `right_arm_fast, right_arm_medium, right_arm_off_spin, right_arm_leg_spin, left_arm_fast, left_arm_medium, left_arm_orthodox, left_arm_chinaman, none` (Gap 74)
- **Custom overs range:** Added "Valid range: 1-50" note on `matches.total_overs` column (Gap 11)
- **Max roster size:** Added "25 players per team (enforced at application level)" note on `team_rosters` section (Gap 53)

### Step 0c: Full 62-Question Pre-Implementation Gap Analysis
A second, more comprehensive gap analysis identified 62 questions across 7 categories. All 62 resolved and applied to docs (commit `d4013ae`). Working document at `docs/debug/gap-analysis-working.md`, full resolution log at plan file `mellow-seeking-crown.md`.

**Category 1 — Document Contradictions (Q1-7):** Fixed pagination to offset-based, added `updated_at` to 8 tables, anonymous WebSocket viewers, standardized wagon wheel zone to int FK, added `match_players` table, removed stale `shot_types` reference, removed SUPER_OVER from blueprint.

**Category 2 — Missing DB Infrastructure (Q8-10):** Deferred partnerships to post-MVP, dropped `innings_stats` table (moved 3 columns to `innings`), deferred materialized view SQL to Phase 5.

**Category 3 — Missing API Endpoints (Q11-16):** Expanded toss endpoint with opening player selection, added Playing XI endpoint, completed 4 incomplete endpoint specs, removed server JWT from auth/verify, defined sync pull response shapes.

**Category 4 — Scoring Engine Logic (Q17-31):** Specified run out crossed/not-crossed rules, retired hurt/out flow, stumped-off-wide UI, no-ball+byes interaction, wicket-on-last-ball order, new batter position by dismissal type, free hit through wides, custom run input (overthrows), custom extras input, declaration flow, abandonment rules, bowler over limit validation, concurrent scoring lock (scorer_id), 5-run penalty rules.

**Category 5 — UI/Design Gaps (Q32-50):** Added complete Section 10 "UI Design Tokens & Patterns" to CODE_STANDARDS.md covering M3 seed color (#2E7D32), Roboto font, Material Symbols icons, 8dp grid spacing, typography scale, dark surface hierarchy, loading/empty/error state patterns, M3 transitions, app bar pattern, snackbar patterns, scoring page fixed-scroll-fixed layout, team logo spec, initials-only avatar, minimal settings in Profile, email auth tab on login, home dashboard content.

**Category 6 — Deployment & Infrastructure (Q51-58):** Expanded IMPLEMENTATION_PLAN.md Phase 7 with existing VPS details (Windows Server 2022, PostgreSQL 16.8, Nginx, PM2, Cloudflare, GitHub Actions self-hosted runner), domain TBD, health monitoring integration, daily pg_dump backups.

**Category 7 — Server Architecture (Q59-62):** Fixed WebSocket delivery message to match REST fields, added reconnection/catch-up strategy (REST snapshot, no replay), documented overs decimal notation utility, clarified `total_runs` as application-level computation.

### Interactive Architectural Blueprint
- **`docs/planning/blueprint.html`** — Comprehensive single-file HTML blueprint (1763 lines) with:
  - All 18 screens wireframed (Splash, Login, OTP, Profile Setup, Home, Teams List, Create Team, Team Detail, Manage Roster, Match Setup, Toss, Scoring Page, Scorecard, Analytics, Player Profile, Player Stats, Match History)
  - 5 scoring dialogs orbiting the Scoring Page (Extras Panel, Wicket Dialog, Select Next Bowler, Select New Batter, Innings Transition)
  - Backend architecture band (API Layer, WebSocket Protocol, Database ER, Offline Sync swim-lane)
  - Cricket domain overlays (10-step delivery pipeline, match state machine, strike rotation decision tree, extras comparison table, undo mechanism, ScoringState shape, widget-to-state mapping)
  - Interactive pan/zoom (mouse drag + scroll wheel + touch pinch)
  - Navigation sidebar with animated pan-to-section
  - Minimap showing viewport position
  - Glossary of cricket terms
  - Hub-and-spoke layout with Scoring Page as gravitational center

### Best Practices Documentation
- Reorganized `docs/` into `planning/` and `process/` subdirectories
- Created Product Development Requirements (`docs/planning/PDR.md`)
- Created 6 process docs covering code standards, implementation workflow, debugging, issue management, and Claude Code config

## Repository Structure

See [CLAUDE.md](../CLAUDE.md#monorepo-layout) for the folder structure and [.claude/rules.md](../.claude/rules.md) for file placement rules.

## Instructions for Next Session

Read this file first, then read `docs/planning/IMPLEMENTATION_PLAN.md` Phase 1 section. Follow the workflow in `docs/process/IMPLEMENTATION_PRACTICES.md`. Begin implementation from step 1. Refer to `docs/planning/DATABASE.md` for schema, `docs/planning/API.md` for endpoints, `docs/planning/SCORING_RULES.md` for cricket logic, and `docs/planning/blueprint.html` for visual architecture reference.
