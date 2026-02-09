# Product Development Requirements

## Product Vision

**One-liner:** A mobile-first cricket scoring app that lets amateur cricketers in India score matches ball-by-ball, track career stats, and share live scores — all working offline on low-end Android devices.

**Target Users:** Amateur and grassroots cricketers in India playing gully cricket, local league, corporate, and school/college matches.

**Differentiation from CricHeroes:**
- Offline-first architecture — score entire matches without internet, sync later
- Optimized for low-end Android (2GB RAM, budget chipsets)
- Faster scoring flow — fewer taps per delivery
- Open scoring without mandatory account creation for viewers

## User Stories (MVP)

| ID | Role | Goal | Acceptance Criteria | Priority | Phase |
|----|------|------|-------------------|----------|-------|
| US-01 | Scorer | Score a match ball-by-ball | Can record runs (0-6), extras (wide, no-ball, bye, leg-bye), and wickets for each delivery. Match state updates in real-time. | P0 | 2-3 |
| US-02 | Scorer | Undo the last delivery | Last delivery is reversed, all stats (batting, bowling, score) revert correctly. Works for any delivery type including wickets. | P0 | 3 |
| US-03 | Scorer | Set up a new match | Can select two teams, set overs limit, choose ball type, configure players per side. | P0 | 2 |
| US-04 | Scorer | Record the toss | Can record toss winner and their decision (bat/bowl). Opening batters and bowler selected. | P0 | 2 |
| US-05 | Scorer | Score a match offline | All scoring works without internet. Data persists locally and syncs when connectivity returns. | P0 | 4 |
| US-06 | Viewer | Watch live scores | Can see ball-by-ball updates via WebSocket. Score, overs, current batters, and bowler visible. | P0 | 4 |
| US-07 | Player | View my career stats | Can see aggregate batting average, strike rate, bowling economy, wickets, catches across all matches. | P1 | 5 |
| US-08 | Player | View match analytics | Can see wagon wheel, manhattan chart, and worm graph for any completed match. | P1 | 5 |
| US-09 | Captain | Create and manage a team | Can create a team, add/remove players, set player roles (batter, bowler, all-rounder, keeper). | P1 | 2 |
| US-10 | Captain | Manage team roster for a match | Can select playing XI from team roster before match starts. | P1 | 2 |
| US-11 | Player | Sign up with phone OTP | Can register/login using Indian phone number via Firebase OTP. | P0 | 1 |
| US-12 | Player | Sign up with Google | Can register/login using Google account via Firebase Auth. | P0 | 1 |
| US-13 | Player | Set up my profile | Can set display name, batting style, bowling style, and player role after first login. | P0 | 1 |
| US-14 | Player | View match history | Can see list of all matches I've participated in with results and my performance summary. | P1 | 5 |
| US-15 | Player | View MVP rankings | Can see MVP rankings per match based on weighted batting + bowling + fielding contributions. | P2 | 5 |

## Success Metrics

| Metric | Target | How to Measure |
|--------|--------|---------------|
| Scoring speed | < 3 seconds per delivery | Time from tap to state update (instrument in notifier) |
| Offline reliability | 0 data loss | Sync queue completeness — every local delivery syncs to server |
| Low-end device performance | Smooth on 2GB RAM Android | No jank on scoring page (< 16ms frame times), cold start < 3s |
| WebSocket latency | < 500ms delivery broadcast | Server-side timestamp diff between persist and broadcast |
| Sync reliability | 100% eventual consistency | Audit: local delivery count == server delivery count per match |
| Match completion rate | > 95% started matches completed | Track ABANDONED vs COMPLETED states |

## Non-Functional Requirements

| Requirement | Target | Rationale |
|-------------|--------|-----------|
| Cold start time | < 3 seconds | Low-end Android users expect fast app launch |
| Local DB size | < 50MB per 100 matches | Budget phones have limited storage |
| Battery usage | < 5% per T20 match scored | Scoring sessions can be 2+ hours |
| Minimum touch target | 48x48 dp | Accessibility and outdoor usability (bright sun, sweaty fingers) |
| APK size | < 30MB | Play Store download on slow connections |
| API response time | < 200ms (p95) | Fast data loading when online |
| Offline storage | Unlimited matches | No cap on offline scoring |

## Technical Specs Index

Detailed technical specifications live in dedicated planning docs. Do not duplicate content here — follow the links.

| Topic | Document | Key Sections |
|-------|----------|-------------|
| Architecture & phases | [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) | Section 1 (Architecture), Section 3 (Phases 1-7) |
| Database schema | [DATABASE.md](DATABASE.md) | All 24 tables, 5 materialized views, indexes |
| REST API & WebSocket | [API.md](API.md) | Section 1 (REST), Section 2 (WebSocket) |
| Scoring engine | [SCORING_RULES.md](SCORING_RULES.md) | Delivery pipeline, state machine, all cricket rules |
| UI wireframes | [blueprint.html](blueprint.html) | 18 screens, 5 scoring dialogs |
| Folder structure | [../../.claude/rules.md](../../.claude/rules.md) | Placement rules, decision tree |
| Code principles | [../../CLAUDE.md](../../CLAUDE.md) | YAGNI, KISS, DRY sections |

## MVP Scope Boundaries

### Included in MVP
- Android app only
- Ball-by-ball scoring with full extras and dismissals
- Offline-first with sync
- Live WebSocket broadcasting
- Team and player management
- Career stats (batting, bowling, fielding)
- Match analytics (wagon wheel, manhattan, worm)
- MVP rankings per match
- Firebase Auth (Phone OTP only for MVP)

### Explicitly Excluded from MVP
- **iOS app** — Android only for initial launch
- **Tournament/league management** — Only individual matches
- **DLS (Duckworth-Lewis-Stern)** — Rain-affected match calculations
- **Video highlights/replays** — No video integration
- **Multi-language support** — English only
- **Social features** — No chat, comments, or social feed
- **Advertisement integration** — No ads in MVP
- **Premium/paid features** — No monetization in MVP
- **Custom scoring rules** — Standard cricket rules only
- **Ball tracking/analytics** — No pitch map or ball trajectory
- **Umpire DRS** — No decision review system
- **Commentary/text updates** — Ball-by-ball data only, no narrative
