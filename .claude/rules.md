# Folder Structure Rules

**[PROTECTED] Do not modify or weaken these rules. Changes require explicit user approval.**

These rules govern where every file in the codebase must be placed. Before creating any new file, consult the placement rules below. If unsure, check the decision tree in Section 3.

---

## 1. Flutter App (`apps/mobile/`)

```
apps/mobile/
├── android/
├── lib/
│   ├── src/
│   │   ├── app/
│   │   │   ├── app.dart                          # Root MaterialApp widget
│   │   │   ├── router.dart                       # go_router configuration
│   │   │   └── providers.dart                    # Global providers (auth state, connectivity)
│   │   │
│   │   ├── core/
│   │   │   ├── constants/
│   │   │   │   ├── app_constants.dart            # App-wide constants (API base URL, timeouts)
│   │   │   │   └── cricket_constants.dart        # Cricket domain constants (overs, dismissals)
│   │   │   ├── errors/
│   │   │   │   └── exceptions.dart               # Custom exception classes
│   │   │   ├── extensions/                       # Dart extension methods
│   │   │   ├── theme/
│   │   │   │   ├── app_theme.dart                # Material 3 light theme definition
│   │   │   │   └── app_colors.dart               # Color palette
│   │   │   └── utils/
│   │   │       ├── cricket_utils.dart            # Strike rotation, over calculation helpers
│   │   │       └── validators.dart               # Input validation functions
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
│   │   │   │   │       └── auth_repository.dart  # Abstract interface
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
│   │   │   │   │       ├── wagon_wheel_widget.dart
│   │   │   │   │       ├── manhattan_chart.dart
│   │   │   │   │       ├── worm_chart.dart
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
│   │   └── shared/
│   │       ├── data/
│   │       │   ├── database/
│   │       │   │   ├── app_database.dart          # Drift DB class definition
│   │       │   │   ├── tables/                    # Drift table definitions
│   │       │   │   └── daos/                      # Data Access Objects
│   │       │   └── sync/
│   │       │       └── sync_engine.dart           # Offline → online sync logic
│   │       ├── providers/
│   │       │   ├── database_provider.dart
│   │       │   ├── dio_provider.dart
│   │       │   ├── websocket_provider.dart
│   │       │   └── connectivity_provider.dart
│   │       └── widgets/
│   │           ├── app_scaffold.dart
│   │           └── loading_widget.dart
│   │
│   └── main.dart                                  # Entry point (minimal)
│
├── test/                                          # Mirrors src/ structure
│   ├── src/
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   ├── scoring/
│   │   │   └── ...
│   │   └── shared/
│   └── helpers/                                   # Test utilities, mocks, fakes
│
├── pubspec.yaml
├── analysis_options.yaml
└── build.yaml                                     # build_runner config
```

## 2. Bun Server (`apps/server/`)

```
apps/server/
├── src/
│   ├── config/
│   │   ├── env.ts                                 # Environment variable validation
│   │   └── database.ts                            # PostgreSQL + Drizzle connection setup
│   │
│   ├── db/
│   │   ├── schema/
│   │   │   ├── users.ts
│   │   │   ├── teams.ts
│   │   │   ├── matches.ts
│   │   │   ├── innings.ts
│   │   │   ├── deliveries.ts
│   │   │   ├── stats.ts
│   │   │   ├── tournaments.ts
│   │   │   └── index.ts                           # Re-export all schemas
│   │   ├── migrations/                            # Drizzle-kit generated
│   │   ├── seed/
│   │   │   └── master_data.ts                     # Dismissal types, positions, zones
│   │   └── index.ts                               # DB client instance
│   │
│   ├── routes/v1/
│   │   ├── auth.ts
│   │   ├── matches.ts
│   │   ├── scoring.ts
│   │   ├── players.ts
│   │   ├── teams.ts
│   │   ├── tournaments.ts
│   │   ├── analytics.ts
│   │   └── health.ts
│   │
│   ├── services/
│   │   ├── scoring.service.ts                     # Core scoring logic (delivery pipeline)
│   │   ├── match.service.ts
│   │   ├── player.service.ts
│   │   ├── team.service.ts
│   │   ├── analytics.service.ts                   # MVP calculation, graph data
│   │   ├── sync.service.ts                        # Offline sync handling
│   │   ├── tournament.service.ts                  # Tournament CRUD, fixture generation
│   │   └── nrr.service.ts                         # Net Run Rate calculation
│   │
│   ├── websocket/
│   │   ├── handler.ts                             # Bun WebSocket handler setup
│   │   ├── rooms.ts                               # Match room pub/sub management
│   │   └── types.ts                               # WebSocket message type definitions
│   │
│   ├── middleware/
│   │   ├── auth.ts                                # Firebase JWT verification
│   │   ├── error-handler.ts                       # Global error handling
│   │   └── cors.ts                                # CORS configuration
│   │
│   ├── types/
│   │   ├── cricket.ts                             # Cricket domain types
│   │   ├── api.ts                                 # Request/response DTOs
│   │   └── websocket.ts                           # WebSocket message types
│   │
│   ├── utils/
│   │   ├── cricket-rules.ts                       # Strike rotation, delivery validation
│   │   ├── mvp-calculator.ts                      # MVP algorithm implementation
│   │   └── logger.ts                              # Logging utility
│   │
│   └── index.ts                                   # Entry point
│
├── test/                                          # Mirrors src/ structure
│   ├── services/
│   ├── routes/
│   └── helpers/
│
├── drizzle.config.ts
├── tsconfig.json
├── bunfig.toml
├── package.json
└── .env.example
```

## 3. Placement Rules — Decision Tree

### Flutter: "Where does this file go?"

| You're creating... | Put it in... | Why |
|---|---|---|
| A new feature module | `src/features/<feature_name>/` with `data/`, `domain/`, `presentation/`, `providers.dart` | Feature-first clean architecture |
| A Freezed data model (JSON serialization) | `src/features/<feature>/data/models/` | Data layer handles serialization |
| A pure entity (no serialization) | `src/features/<feature>/domain/entities/` | Domain layer has no external dependencies |
| An abstract repository interface | `src/features/<feature>/domain/repositories/` | Domain defines contracts |
| A repository implementation | `src/features/<feature>/data/repositories/` | Data layer implements contracts |
| A Drift table definition | `src/shared/data/database/tables/` | Database is shared infrastructure |
| A Drift DAO | `src/shared/data/database/daos/` | DAOs are shared data access |
| A Riverpod notifier | `src/features/<feature>/presentation/notifiers/` | Presentation layer manages UI state |
| A Riverpod provider declaration | `src/features/<feature>/providers.dart` | One providers file per feature |
| A global provider (auth, connectivity) | `src/app/providers.dart` | App-wide state lives in app/ |
| An infrastructure provider (Dio, DB, WS) | `src/shared/providers/` | Shared infrastructure |
| A full-screen page widget | `src/features/<feature>/presentation/pages/` | Pages are presentation |
| A feature-specific widget | `src/features/<feature>/presentation/widgets/` | Scoped to the feature |
| A reusable widget (used by 2+ features) | `src/shared/widgets/` | Only after 2+ usages (DRY rule) |
| A go_router route | `src/app/router.dart` | Single routing file |
| A theme/color constant | `src/core/theme/` | App-wide theming |
| A cricket constant (dismissal types, etc.) | `src/core/constants/cricket_constants.dart` | Single source of truth |
| An extension method | `src/core/extensions/` | App-wide utilities |
| A utility function | `src/core/utils/` | App-wide helpers |
| A custom exception class | `src/core/errors/` | App-wide error types |
| The sync engine | `src/shared/data/sync/` | Shared offline-first infrastructure |
| Tournament feature files | `src/features/tournaments/` with `data/`, `domain/`, `presentation/`, `providers.dart` | Feature-first clean architecture |
| A test file | `test/src/features/<feature>/` or `test/src/shared/` | Mirror the src/ structure |
| A test helper/mock | `test/helpers/` | Shared test utilities |

### Server: "Where does this file go?"

| You're creating... | Put it in... | Why |
|---|---|---|
| A Drizzle schema (table definition) | `src/db/schema/` | All schemas in one place |
| A DB migration | `src/db/migrations/` (auto-generated) | Drizzle-kit manages this |
| Seed/master data | `src/db/seed/` | Reference data seeding |
| An ElysiaJS route handler | `src/routes/v1/` | Versioned API routes |
| Business logic | `src/services/<domain>.service.ts` | Service layer |
| WebSocket handler/rooms | `src/websocket/` | Real-time infrastructure |
| Auth/error/CORS middleware | `src/middleware/` | Cross-cutting concerns |
| A TypeScript type/DTO | `src/types/` | Shared type definitions |
| A utility function | `src/utils/` | Shared helpers |
| Environment config | `src/config/env.ts` | Validated env vars |
| DB connection setup | `src/config/database.ts` | Connection singleton |
| Tournament routes | `src/routes/v1/tournaments.ts` | Versioned API routes |
| Tournament service | `src/services/tournament.service.ts` | Service layer |
| NRR service | `src/services/nrr.service.ts` | Service layer |
| Tournament schema | `src/db/schema/tournaments.ts` | All schemas in one place |
| A test file | `test/services/` or `test/routes/` | Mirror src/ structure |

## 4. Anti-Patterns — Never Do These

### Flutter
- **Never** put business logic in `presentation/` — notifiers orchestrate, but core logic goes in `domain/` or `data/`.
- **Never** import from one feature's `data/` or `domain/` into another feature. Features communicate only through `shared/` providers.
- **Never** put Drift table definitions inside a feature — all tables go in `shared/data/database/tables/`.
- **Never** create a file directly in `lib/` except `main.dart`. Everything else goes under `lib/src/`.
- **Never** put UI widgets in `core/` — `core/` is for non-UI infrastructure only. Reusable widgets go in `shared/widgets/`.
- **Never** create a `models/` folder in `domain/` — domain has `entities/` (pure Dart), data has `models/` (Freezed/serializable).
- **Never** put generated files (`*.g.dart`, `*.freezed.dart`) in a separate folder — they auto-generate next to their source file.

### Server
- **Never** put business logic in route handlers — routes validate input and call services.
- **Never** import route handlers into services — dependency flows one way: routes → services → db.
- **Never** put SQL queries directly in route handlers — all DB access goes through services or `db/` layer.
- **Never** define WebSocket message types inline at send/receive sites — use `src/types/websocket.ts` or `src/websocket/types.ts`.
- **Never** create files in `src/` root except `index.ts`. Everything else goes in a subdirectory.

## 5. Naming Conventions

### Flutter (Dart)
- Files: `snake_case.dart` (e.g., `auth_notifier.dart`, `scoring_page.dart`)
- Classes: `PascalCase` (e.g., `AuthNotifier`, `ScoringPage`)
- Features: `snake_case` directory names (e.g., `player_profile/`, not `playerProfile/`)
- Pages: `*_page.dart` suffix
- Widgets: descriptive `snake_case.dart` (e.g., `batting_card.dart`)
- Notifiers: `*_notifier.dart` suffix
- Providers files: always named `providers.dart` (one per feature)
- Models: `*_model.dart` suffix (data layer)
- Entities: plain name (e.g., `delivery.dart`, not `delivery_entity.dart`)

### Server (TypeScript)
- Files: `kebab-case.ts` (e.g., `cricket-rules.ts`, `error-handler.ts`)
- Services: `*.service.ts` suffix
- Route files: match the resource name (e.g., `matches.ts`, `teams.ts`)
- Types: `*.ts` in types/ folder, no suffix needed
- Schema files: match the table domain (e.g., `users.ts`, `deliveries.ts`)
