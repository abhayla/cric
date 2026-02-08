# CricApp - Implementation Plan

## 1. Architecture Overview

```
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
2. App saves to local Drift DB immediately (offline-safe)
3. App sends delivery data via WebSocket to Bun server
4. Bun server validates, persists to PostgreSQL
5. Bun server broadcasts update to all match subscribers via WebSocket pub/sub
6. All viewers' Flutter apps receive update, refresh scorecard UI

---

## 2. Monorepo Folder Structure

### 2.1 Flutter App (`apps/mobile/`)

```
apps/mobile/
├── android/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart
│   │   │   └── cricket_constants.dart       # Overs, dismissals, etc.
│   │   ├── errors/
│   │   │   └── exceptions.dart
│   │   ├── extensions/
│   │   ├── theme/
│   │   │   ├── app_theme.dart               # M3 dark theme
│   │   │   └── app_colors.dart
│   │   └── utils/
│   │       ├── cricket_utils.dart           # Strike rotation, over calc
│   │       └── validators.dart
│   │
│   ├── src/
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
│   │   └── routing/
│   │       └── app_router.dart                            # go_router config
│   │
│   └── main.dart
│
├── test/
├── pubspec.yaml
└── analysis_options.yaml
```

### 2.2 Bun Server (`apps/server/`)

```
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
│   │   └── health.ts
│   │
│   ├── services/
│   │   ├── scoring.service.ts              # Core scoring logic
│   │   ├── match.service.ts
│   │   ├── player.service.ts
│   │   ├── team.service.ts
│   │   ├── analytics.service.ts            # MVP calc, graph data
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

  # Firebase Auth
  firebase_core: ^26.0.0
  firebase_auth: ^5.0.0
  google_sign_in: ^6.2.0

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
- [ ] Implement Firebase Auth (phone OTP + Google sign-in)
- [ ] Implement auth middleware on Bun (Firebase JWT verification)
- [ ] Set up Material 3 dark theme
- [ ] Set up go_router with auth guards
- [ ] Build: Splash, Login, OTP, Profile Setup screens

### Phase 2: Teams & Match Setup (Week 3-4)
- [ ] Implement Teams CRUD (API + Flutter)
- [ ] Build: Teams List, Create Team, Team Detail, Manage Roster screens
- [ ] Implement Match creation (API + Flutter)
- [ ] Build: Match Setup, Toss screens
- [ ] Set up Drift local database (mirror PostgreSQL schema)
- [ ] Implement basic offline data caching

### Phase 3: Scoring Engine (Week 5-7) -- THE CRITICAL PHASE
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

### Phase 4: Analytics & Visualizations (Week 8-9)
- [ ] Build Wagon Wheel widget (CustomPainter - cricket field + shot zones)
- [ ] Build Manhattan Chart (fl_chart BarChart - runs per over)
- [ ] Build Worm Graph (fl_chart LineChart - cumulative runs comparison)
- [ ] Implement MVP algorithm (server-side calculation)
- [ ] Build MVP Card widget
- [ ] Build Match Analytics Page (tabbed: wagon wheel, manhattan, worm, MVP)

### Phase 5: Player Profiles & Stats (Week 10-11)
- [ ] Implement career stats aggregation (server-side, materialized views)
- [ ] Build Player Profile Page
- [ ] Build Stats Page (batting, bowling, fielding tabs)
- [ ] Build Match History Page
- [ ] Implement stats refresh after each match completion

### Phase 6: Polish & Testing (Week 12-13)
- [ ] Unit tests for scoring engine (critical path)
- [ ] Unit tests for cricket rules (strike rotation, extras, overs)
- [ ] Widget tests for Scoring Page
- [ ] Integration tests for full match scoring flow
- [ ] Offline scoring to online sync end-to-end test
- [ ] Performance testing on low-end Android devices
- [ ] Bug fixes and UI polish
- [ ] Home Page dashboard (recent matches, quick actions)

### Phase 7: Deployment & Launch (Week 14)
- [ ] Set up VPS (PostgreSQL + Bun server)
- [ ] Configure SSL/HTTPS
- [ ] Set up CI/CD pipeline
- [ ] Build release APK
- [ ] Google Play Store listing
- [ ] Launch

---

## 6. Verification Plan

| After Phase | Verification |
|-------------|-------------|
| Phase 1 | Login with phone OTP, see home screen, navigate between screens |
| Phase 2 | Create team, add players, create match, complete toss |
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

## 8. Key Screens (MVP) - 18 Total

1. Splash Screen
2. Login Page (Phone OTP / Google / Email)
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
