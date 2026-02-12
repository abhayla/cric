# CricApp - Implementation Plan

## 1. Architecture Overview

```text
┌─────────────────────────────────────────────────┐
│                 FLUTTER APP                      │
│  ┌───────────┐  ┌──────────┐  ┌──────────────┐ │
│  │  Screens  │→ │ Riverpod │→ │ Repositories │ │
│  │  (UI)     │  │ Notifiers│  │              │ │
│  └───────────┘  └──────────┘  └──────┬───────┘ │
│                                       │         │
│                          ┌────────────┼────┐    │
│                          │            │    │    │
│                   ┌──────▼──┐  ┌──────▼──┐ │   │
│                   │  Drift  │  │   Dio   │ │   │
│                   │ (SQLite)│  │ (HTTP)  │ │   │
│                   └─────────┘  └─────────┘ │   │
│                                    │       │   │
│                          ┌─────────▼───┐   │   │
│                          │ WebSocket   │   │   │
│                          │ Channel     │   │   │
│                          └─────────────┘   │   │
│                   ┌────────────────────┐   │   │
│                   │   Sync Engine      │   │   │
│                   │ (Offline→Online)   │   │   │
│                   └────────────────────┘   │   │
└────────────────────────────────────────────┘   │
                         │                        │
                    HTTPS / WSS                   │
                         │                        │
┌────────────────────────▼────────────────────────┘
│                  BUN SERVER                      │
│  ┌──────────┐  ┌────────────┐  ┌─────────────┐ │
│  │ ElysiaJS │→ │ Services   │→ │ Drizzle ORM │ │
│  │ (Routes) │  │ (Logic)    │  │             │ │
│  └──────────┘  └────────────┘  └──────┬──────┘ │
│  ┌──────────┐  ┌────────────┐         │        │
│  │ Firebase │  │ WebSocket  │  ┌──────▼──────┐ │
│  │ Auth MW  │  │ Manager    │  │ PostgreSQL  │ │
│  └──────────┘  └────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────┘
```

### Data Flow - Live Scoring

1. Scorer taps ball outcome on Flutter UI
2. App saves to local Drift DB immediately (offline-safe, all writes in single transaction)
3. App syncs delivery data to Bun server via **REST** (`POST /matches/:id/deliveries` or `POST /sync/push`)
4. Bun server validates, persists to PostgreSQL
5. Bun server **broadcasts** update to all match subscribers via **WebSocket** pub/sub (read-only broadcast)
6. All viewers' Flutter apps receive update, refresh scorecard UI

> **Important:** REST is the primary write path. WebSocket is broadcast-only (no client→server scoring messages). This eliminates duplicate delivery risk from dual write paths.

---

## 2. Monorepo Folder Structure

### Android Configuration

| Setting | Value | Notes |
|---------|-------|-------|
| minSdkVersion | **23** (Android 6.0) | Covers 97%+ of Indian Android devices |
| Server port | **3000** | Nginx reverse proxies to this |

### 2.1 Flutter App (`apps/mobile/`)

```text
apps/mobile/
├── android/
├── lib/
│   ├── src/
│   │   ├── app/
│   │   │   ├── app.dart                             # Root widget
│   │   │   ├── router.dart                          # go_router config
│   │   │   └── providers.dart                       # App-wide providers
│   │   ├── core/
│   │   │   ├── constants/
│   │   │   │   ├── app_constants.dart
│   │   │   │   └── cricket_constants.dart       # Overs, dismissals, etc.
│   │   │   ├── errors/
│   │   │   │   └── exceptions.dart
│   │   │   ├── extensions/
│   │   │   ├── theme/
│   │   │   │   ├── app_theme.dart               # M3 light theme
│   │   │   │   └── app_colors.dart
│   │   │   └── utils/
│   │   │       ├── cricket_utils.dart           # Strike rotation, over calc
│   │   │       └── validators.dart
│   │   │
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   │   ├── data/
│   │   │   │   │   ├── datasources/
│   │   │   │   │   │   └── firebase_auth_datasource.dart
│   │   │   │   │   └── repositories/
│   │   │   │   │       └── auth_repository_impl.dart
│   │   │   │   ├── domain/
│   │   │   │   │   ├── entities/
│   │   │   │   │   │   └── app_user.dart
│   │   │   │   │   └── repositories/
│   │   │   │   │       └── auth_repository.dart
│   │   │   │   ├── presentation/
│   │   │   │   │   ├── notifiers/
│   │   │   │   │   │   └── auth_notifier.dart
│   │   │   │   │   ├── pages/
│   │   │   │   │   │   ├── login_page.dart
│   │   │   │   │   │   ├── otp_page.dart
│   │   │   │   │   │   └── profile_setup_page.dart
│   │   │   │   │   └── widgets/
│   │   │   │   └── providers.dart
│   │   │   │
│   │   │   ├── scoring/
│   │   │   │   ├── data/
│   │   │   │   │   ├── datasources/
│   │   │   │   │   │   ├── scoring_local_datasource.dart
│   │   │   │   │   │   └── scoring_remote_datasource.dart
│   │   │   │   │   ├── models/
│   │   │   │   │   │   ├── delivery_model.dart
│   │   │   │   │   │   ├── innings_model.dart
│   │   │   │   │   │   └── match_model.dart
│   │   │   │   │   └── repositories/
│   │   │   │   ├── domain/
│   │   │   │   │   ├── entities/
│   │   │   │   │   │   ├── delivery.dart
│   │   │   │   │   │   ├── innings.dart
│   │   │   │   │   │   ├── match.dart
│   │   │   │   │   │   ├── over.dart
│   │   │   │   │   │   └── wicket.dart
│   │   │   │   │   └── repositories/
│   │   │   │   ├── presentation/
│   │   │   │   │   ├── notifiers/
│   │   │   │   │   │   ├── scoring_notifier.dart          # Core scoring state
│   │   │   │   │   │   └── match_setup_notifier.dart
│   │   │   │   │   ├── pages/
│   │   │   │   │   │   ├── match_setup_page.dart
│   │   │   │   │   │   ├── toss_page.dart
│   │   │   │   │   │   ├── scoring_page.dart              # Main scoring UI
│   │   │   │   │   │   └── scorecard_page.dart
│   │   │   │   │   └── widgets/
│   │   │   │   │       ├── scoring_controls.dart
│   │   │   │   │       ├── extras_panel.dart
│   │   │   │   │       ├── wicket_dialog.dart
│   │   │   │   │       ├── batting_card.dart
│   │   │   │   │       ├── bowling_card.dart
│   │   │   │   │       └── over_summary.dart
│   │   │   │   └── providers.dart
│   │   │   │
│   │   │   ├── analytics/
│   │   │   │   ├── data/
│   │   │   │   ├── domain/
│   │   │   │   ├── presentation/
│   │   │   │   │   ├── notifiers/
│   │   │   │   │   │   └── analytics_notifier.dart
│   │   │   │   │   ├── pages/
│   │   │   │   │   │   └── match_analytics_page.dart
│   │   │   │   │   └── widgets/
│   │   │   │   │       ├── wagon_wheel_widget.dart        # CustomPainter
│   │   │   │   │       ├── manhattan_chart.dart           # fl_chart BarChart
│   │   │   │   │       ├── worm_chart.dart                # fl_chart LineChart
│   │   │   │   │       └── mvp_card.dart
│   │   │   │   └── providers.dart
│   │   │   │
│   │   │   ├── player_profile/
│   │   │   │   ├── data/
│   │   │   │   ├── domain/
│   │   │   │   ├── presentation/
│   │   │   │   │   ├── notifiers/
│   │   │   │   │   ├── pages/
│   │   │   │   │   │   ├── profile_page.dart
│   │   │   │   │   │   └── stats_page.dart
│   │   │   │   │   └── widgets/
│   │   │   │   │       ├── batting_stats_card.dart
│   │   │   │   │       ├── bowling_stats_card.dart
│   │   │   │   │       └── fielding_stats_card.dart
│   │   │   │   └── providers.dart
│   │   │   │
│   │   │   ├── teams/
│   │   │   │   ├── data/
│   │   │   │   ├── domain/
│   │   │   │   ├── presentation/
│   │   │   │   │   ├── notifiers/
│   │   │   │   │   ├── pages/
│   │   │   │   │   │   ├── teams_list_page.dart
│   │   │   │   │   │   ├── team_detail_page.dart
│   │   │   │   │   │   ├── create_team_page.dart
│   │   │   │   │   │   └── manage_roster_page.dart
│   │   │   │   │   └── widgets/
│   │   │   │   └── providers.dart
│   │   │   │
│   │   │   ├── tournaments/
│   │   │   │   ├── data/
│   │   │   │   │   ├── datasources/
│   │   │   │   │   │   ├── tournament_local_datasource.dart
│   │   │   │   │   │   └── tournament_remote_datasource.dart
│   │   │   │   │   ├── models/
│   │   │   │   │   │   ├── tournament_model.dart
│   │   │   │   │   │   ├── fixture_model.dart
│   │   │   │   │   │   └── standing_model.dart
│   │   │   │   │   └── repositories/
│   │   │   │   │       └── tournament_repository_impl.dart
│   │   │   │   ├── domain/
│   │   │   │   │   ├── entities/
│   │   │   │   │   │   ├── tournament.dart
│   │   │   │   │   │   ├── fixture.dart
│   │   │   │   │   │   └── standing.dart
│   │   │   │   │   └── repositories/
│   │   │   │   │       └── tournament_repository.dart
│   │   │   │   ├── presentation/
│   │   │   │   │   ├── notifiers/
│   │   │   │   │   │   ├── tournament_notifier.dart
│   │   │   │   │   │   └── standings_notifier.dart
│   │   │   │   │   ├── pages/
│   │   │   │   │   │   ├── tournaments_list_page.dart
│   │   │   │   │   │   ├── create_tournament_page.dart
│   │   │   │   │   │   ├── tournament_detail_page.dart
│   │   │   │   │   │   ├── standings_page.dart
│   │   │   │   │   │   ├── knockout_bracket_page.dart
│   │   │   │   │   │   └── tournament_leaderboard_page.dart
│   │   │   │   │   └── widgets/
│   │   │   │   │       ├── standings_table.dart
│   │   │   │   │       ├── bracket_widget.dart
│   │   │   │   │       └── fixture_card.dart
│   │   │   │   └── providers.dart
│   │   │   │
│   │   │   └── home/
│   │   │       └── presentation/
│   │   │           └── pages/
│   │   │               └── home_page.dart
│   │   │
│   │   ├── shared/
│   │   │   ├── data/
│   │   │   │   ├── database/
│   │   │   │   │   ├── app_database.dart                  # Drift DB definition
│   │   │   │   │   ├── tables/                            # Drift table defs
│   │   │   │   │   └── daos/                              # Data Access Objects
│   │   │   │   └── sync/
│   │   │   │       └── sync_engine.dart                   # Offline sync logic
│   │   │   ├── providers/
│   │   │   │   ├── database_provider.dart
│   │   │   │   ├── dio_provider.dart
│   │   │   │   ├── websocket_provider.dart
│   │   │   │   └── connectivity_provider.dart
│   │   │   └── widgets/
│   │   │       ├── app_scaffold.dart
│   │   │       └── loading_widget.dart
│   │   │
│   └── main.dart
│
├── test/
├── pubspec.yaml
└── analysis_options.yaml
```

### 2.2 Bun Server (`apps/server/`)

```text
apps/server/
├── src/
│   ├── db/
│   │   ├── schema/
│   │   │   ├── users.ts
│   │   │   ├── teams.ts
│   │   │   ├── matches.ts
│   │   │   ├── innings.ts
│   │   │   ├── deliveries.ts
│   │   │   ├── stats.ts
│   │   │   ├── tournaments.ts
│   │   │   └── index.ts                    # Re-export all schemas
│   │   ├── migrations/
│   │   ├── seed/
│   │   │   └── master_data.ts              # Dismissal types, positions, zones
│   │   └── index.ts                        # DB connection
│   │
│   ├── routes/v1/
│   │   ├── auth.ts
│   │   ├── matches.ts
│   │   ├── scoring.ts
│   │   ├── players.ts
│   │   ├── teams.ts
│   │   ├── analytics.ts
│   │   ├── tournaments.ts
│   │   └── health.ts
│   │
│   ├── services/
│   │   ├── scoring.service.ts              # Core scoring logic
│   │   ├── match.service.ts
│   │   ├── player.service.ts
│   │   ├── team.service.ts
│   │   ├── analytics.service.ts            # MVP calc, graph data
│   │   ├── tournament.service.ts           # Tournament CRUD, fixtures, standings
│   │   ├── nrr.service.ts                  # Net Run Rate calculation
│   │   └── sync.service.ts                 # Offline sync handling
│   │
│   ├── websocket/
│   │   ├── handler.ts                      # WebSocket message router
│   │   ├── rooms.ts                        # Match room management
│   │   └── types.ts
│   │
│   ├── middleware/
│   │   ├── auth.ts                         # Firebase JWT verification
│   │   ├── error-handler.ts
│   │   └── cors.ts
│   │
│   ├── types/
│   │   ├── cricket.ts                      # Cricket domain types
│   │   ├── api.ts
│   │   └── websocket.ts
│   │
│   ├── utils/
│   │   ├── cricket-rules.ts                # Strike rotation, validation
│   │   ├── mvp-calculator.ts               # MVP algorithm
│   │   └── logger.ts
│   │
│   └── index.ts                            # Entry point
│
├── drizzle.config.ts
├── tsconfig.json
├── bunfig.toml
├── package.json
└── .env.example
```

---

## 3. Flutter Packages (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^3.0.0
  riverpod_annotation: ^3.0.0

  # Database (Offline-first)
  drift: ^2.15.0
  sqlite3: ^3.11.0
  sqlite3_flutter_libs: ^0.5.25

  # Networking
  dio: ^5.4.0
  web_socket_channel: ^3.0.0

  # Firebase Auth (Phone OTP only — no Google/Email for MVP)
  firebase_core: ^26.0.0
  firebase_auth: ^5.0.0

  # Navigation
  go_router: ^14.0.0

  # UI & Charts
  fl_chart: ^0.68.0
  google_fonts: ^6.2.0
  flutter_svg: ^2.0.0

  # Utilities
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0
  shared_preferences: ^2.2.0
  connectivity_plus: ^6.0.0
  uuid: ^4.0.0
  flutter_secure_storage: ^9.0.0
  image_picker: ^1.0.0
  logger: ^2.0.0

  # Crash Reporting
  firebase_crashlytics: ^4.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0
  drift_dev: ^2.15.0
  riverpod_generator: ^3.0.0
  mocktail: ^1.4.0
  integration_test:
    sdk: flutter
```

## 4. Bun Server Packages (package.json)

```json
{
  "name": "cricapp-server",
  "version": "0.1.0",
  "dependencies": {
    "elysia": "^1.2.0",
    "drizzle-orm": "^0.35.0",
    "postgres": "^3.4.0",
    "firebase-admin": "^12.0.0",
    "@elysiajs/cors": "^1.1.0"
  },
  "devDependencies": {
    "drizzle-kit": "^0.26.0",
    "typescript": "^5.5.0",
    "@types/bun": "latest"
  }
}
```

---

## 5. Phased Development Roadmap

### Phase 1: Foundation (Week 1-2)
- [ ] Initialize Flutter project with folder structure
- [ ] Initialize Bun server with folder structure
- [ ] Set up PostgreSQL database with Drizzle schema + migrations
- [ ] Seed master data (dismissal types, fielding positions, wagon wheel zones, ball types)
- [ ] Set up Firebase project + configure Flutter Firebase
- [ ] Implement Firebase Auth (Phone OTP only — no Google/Email for MVP)
- [ ] Implement auth middleware on Bun (Firebase JWT verification)
- [ ] Set up Material 3 light theme
- [ ] Set up go_router with auth guards
- [ ] Build: Splash, Login, OTP, Profile Setup screens

### Phase 2: Teams & Match Setup (Week 3-4)
- [ ] Implement Teams CRUD (API + Flutter)
- [ ] Build: Teams List, Create Team, Team Detail, Manage Roster screens
- [ ] Implement Match creation (API + Flutter)
- [ ] Build: Match Setup, Toss screens
- [ ] Set up Drift local database (mirror PostgreSQL schema)
- [ ] Implement basic offline data caching

### Phase 2.5: Tournament Management (Week 4-5)
- [ ] Implement Tournament CRUD with 5 template fields (API + Flutter) — players_per_side, max_overs_per_bowler, wide_runs, no_ball_runs, powerplay_overs
- [ ] Build: Tournaments List, Create Tournament screens (include template fields in create form)
- [ ] Implement open team registration with organizer approval flow (POST register, GET requests, PUT approve/reject)
- [ ] Implement roster size validation at registration time (min players_per_side)
- [ ] Implement organizer direct-add team (existing POST teams endpoint, now with roster validation)
- [ ] Implement fixture auto-generation algorithms (round-robin, knockout, group+knockout)
- [ ] Implement fixture scheduling with time-of-day + estimated duration + venue conflict detection
- [ ] Build: Tournament Detail screen (status, teams, fixtures, registration requests tabs)
- [ ] Build: Standings/Points Table screen (sortable, group tabs)
- [ ] Build: Knockout Bracket visualization
- [ ] Implement NRR calculation engine (server-side)
- [ ] Implement standings recalculation on match completion
- [ ] Build: Tournament Leaderboard screen (runs, wickets, avg, economy tabs)
- [ ] Implement match creation from fixture ("Start Match" on unplayed fixture, inherits tournament template rules)
- [ ] Update Match Setup screen with optional tournament context (locked fields when tournament match)
- [ ] Update Home screen with "My Tournaments" section
- [ ] Implement super over for knockout ties (trigger detection, super over innings, repeat on tie, result recording)
- [ ] Super over UI: batter/bowler selection, scoring controls reuse, scorecard section
- [ ] Super over stats exclusion from career stats and tournament leaderboard

### Phase 3: Scoring Engine (Week 6-8) -- THE CRITICAL PHASE
- [ ] Implement delivery recording logic (server-side)
- [ ] Implement scoring state machine (Flutter - Riverpod notifier)
- [ ] Build Scoring Page UI (run buttons, extras, wicket dialog)
- [ ] Implement cricket rules (strike rotation, extras, over completion, all out)
- [ ] Implement undo functionality
- [ ] Set up Bun Native WebSocket server with room management
- [ ] Implement WebSocket client in Flutter
- [ ] Real-time score broadcasting (scorer to viewers)
- [ ] Build Scorecard Page (batting + bowling cards)
- [ ] Implement innings transition flow
- [ ] Implement match completion flow
- [ ] Full offline scoring with sync queue

### Phase 4: Analytics & Visualizations (Week 9-10)
- [ ] Build Wagon Wheel widget (CustomPainter - cricket field + shot zones)
- [ ] Build Manhattan Chart (fl_chart BarChart - runs per over)
- [ ] Build Worm Graph (fl_chart LineChart - cumulative runs comparison)
- [ ] Implement MVP algorithm (server-side calculation)
- [ ] Build MVP Card widget
- [ ] Build Match Analytics Page (tabbed: wagon wheel, manhattan, worm, MVP)

### Phase 5: Player Profiles & Stats (Week 11-12)
- [ ] Implement career stats aggregation (server-side, materialized views)
- [ ] Build Player Profile Page
- [ ] Build Stats Page (batting, bowling, fielding tabs)
- [ ] Build Match History Page
- [ ] Implement stats refresh after each match completion

### Phase 6: Polish & Testing (Week 13-14)
- [ ] Unit tests for scoring engine (critical path)
- [ ] Unit tests for cricket rules (strike rotation, extras, overs)
- [ ] Widget tests for Scoring Page
- [ ] Integration tests for full match scoring flow
- [ ] Offline scoring to online sync end-to-end test
- [ ] Performance testing on low-end Android devices
- [ ] Bug fixes and UI polish
- [ ] Home Page dashboard (recent matches, quick actions)

### Phase 7: Deployment & Launch (Week 15)

#### Infrastructure (existing VPS)

| Component | Details |
|-----------|---------|
| VPS | Windows Server 2022, AMD EPYC 32-core, IP 103.118.16.189 |
| Database | PostgreSQL 16.8, self-hosted on VPS, localhost:5432 |
| Process manager | PM2 (Node.js/Bun apps) |
| Reverse proxy | Nginx 1.26.2 on port 80 |
| SSL/CDN | Cloudflare (Flexible SSL mode, DDoS protection) |
| CI/CD | GitHub Actions with self-hosted runner on VPS |
| Firebase | **Single project for MVP** (no staging/production split). Post-MVP: create separate projects per environment. |
| Domain | TBD — register domain, add Cloudflare A record → 103.118.16.189 |
| Monitoring | Existing VPS health check script (every 5 min) — add CricApp to `$sites` array |
| Backups | Daily `pg_dump` cron to `C:\Apps\backups\` with 7-day retention |

#### Development API URL (D1)

- **Default:** `http://10.0.2.2:3000/api/v1` (Android emulator routes to host machine's localhost)
- **Physical device override:** `flutter run --dart-define=API_BASE_URL=http://192.168.x.x:3000/api/v1`
- **Store in:** `core/constants/app_constants.dart` with `String.fromEnvironment` fallback
- **Production URL:** Configured at Phase 7 deployment time (domain TBD)

#### PostgreSQL Setup (D2)

- **Server:** Use existing VPS PostgreSQL 16.8 (already installed, localhost:5432)
- **Development database:** `cricapp_dev`
- **Production database:** `cricapp`
- **Credentials:** Stored in `.env` file, never committed to git
- **Setup command:** `CREATE DATABASE cricapp_dev; CREATE USER cricapp_user WITH PASSWORD '...'; GRANT ALL PRIVILEGES ON DATABASE cricapp_dev TO cricapp_user;`
- **`.env.example`** created with placeholder values during Phase 1 init

#### Environment Variables (`.env.example`)

Create `apps/server/.env.example` during Phase 1 initialization with these 12 variables:

```
DATABASE_URL=postgresql://user:password@localhost:5432/cricapp
JWT_SECRET=your-jwt-secret-here
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
PORT=3000
WS_PORT=3001
CORS_ORIGIN=*
UPLOADS_DIR=./uploads
MAX_UPLOAD_SIZE_MB=2
LOG_LEVEL=info
NODE_ENV=development
SYNC_BATCH_SIZE=50
WS_HEARTBEAT_INTERVAL_MS=30000
```

#### Deployment tasks

- [ ] Create PostgreSQL database + user for CricApp (`cricapp` / `cricapp_user`)
- [ ] Deploy Bun server via PM2 (`ecosystem.config.js`)
- [ ] Create Nginx site config (`C:\Apps\nginx\conf\sites\cricapp.conf`) — HTTP proxy to port 3000 + WebSocket upgrade headers. SSL via Cloudflare (Nginx on HTTP). For development: use direct port 3000 access (no Nginx needed).
- [ ] Register domain, configure Cloudflare DNS (A record → VPS IP, proxied)
- [ ] Set up GitHub Actions self-hosted runner for CricApp repo
- [ ] Create `.github/workflows/deploy.yml` for auto-deploy on push to main
- [ ] Add CricApp to VPS health monitoring (`health-check.ps1` `$sites` array)
- [ ] Configure daily `pg_dump` backup for `cricapp` database
- [ ] Set up Firebase project (Auth provider: Phone OTP only)
- [ ] Build release APK, sign with upload key
- [ ] Google Play Store listing (app name, description, screenshots, privacy policy — details TBD at pre-launch)
- [ ] Launch

---

## 6. Verification Plan

| After Phase | Verification |
|-------------|-------------|
| Phase 1 | Login with Phone OTP, see home screen, navigate between screens |
| Phase 2 | Create team, add players, create match, complete toss |
| Phase 2.5 | Create tournament (all 3 formats) with template fields (custom players_per_side, wide_runs, etc.), test team self-registration + organizer approval flow, test roster size validation, add 4+ teams, generate fixtures with scheduling, complete one match (verify inherited rules are locked), verify standings update with correct NRR and points, verify knockout bracket auto-populates, test super over trigger on knockout tie, verify super over stats excluded from career/leaderboard |
| Phase 3 | Score a complete T20 match ball-by-ball, verify scorecard accuracy, test undo, test offline scoring |
| Phase 4 | View wagon wheel for a batter, manhattan for an innings, worm comparing both innings, MVP rankings |
| Phase 5 | View player career stats, verify they match aggregate of individual match performances |
| Phase 6 | Run full test suite, all tests pass, no crashes on low-end device |
| Phase 7 | App installable from Play Store, backend accessible, WebSocket connections stable |

### Critical Validation for Phase 3 (Scoring Engine)

- Score a full T20 match (40 overs total)
- Verify: total runs = sum of all deliveries
- Verify: wickets count matches dismissals recorded
- Verify: strike rotation is correct after each delivery
- Verify: extras are attributed correctly (wide/NB to bowler, bye/LB to extras)
- Verify: over changes happen after 6 legal deliveries
- Verify: maiden overs detected correctly
- Verify: all-out triggers innings completion
- Verify: scoring works fully offline and syncs when reconnected

---

## 7. Testing Strategy

| Type | Coverage Target | Focus Areas |
|------|----------------|-------------|
| Unit Tests | 60% | Scoring engine, cricket rules, MVP algorithm, sync engine |
| Widget Tests | 30% | Scoring controls, scorecard rendering, wagon wheel, chart data binding |
| Integration Tests | 10% | Full match scoring flow, offline sync, auth flow |
| Manual Testing | - | Low-end Android (2GB RAM), airplane mode mid-match, WebSocket reconnection |

---

## 8. Key Screens (MVP) - 24 Total

1. Splash Screen
2. Login Page (Phone OTP only)
3. OTP Verification Page
4. Profile Setup Page
5. Home Page (Dashboard)
6. Teams List Page
7. Create Team Page
8. Team Detail Page
9. Manage Roster Page
10. Match Setup Page
11. Toss Page
12. **Scoring Page** (most critical)
13. Wicket Dialog
14. Extras Panel
15. Scorecard Page
16. Match Analytics Page
17. Player Profile Page
18. Match History Page
19. Tournaments List Page
20. Create Tournament Page
21. Tournament Detail Page
22. Standings / Points Table Page
23. Knockout Bracket Page
24. Tournament Leaderboard Page
