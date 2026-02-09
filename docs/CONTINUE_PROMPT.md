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
- Free hit tracking on no-balls
- Byes/leg-byes don't break maidens
- No SUPER_OVER — tied match → COMPLETED with "Match Tied"
- No DLS calculations or shot types tables (deferred / not needed for MVP)
- Teams use soft delete (`is_active` boolean)
- WebSocket heartbeat via protocol-level ping/pong (30s interval, 5s timeout)
- Sync ordering: match → innings → deliveries → stats
- Server-wins conflict resolution (silent overwrite)
- Local ID → server ID mapping table (no mass FK updates)

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
