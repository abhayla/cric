# Flutter App — CricScores Mobile

## Architecture
Feature-first clean architecture with Riverpod 3.0 state management.

## Feature Structure
Each feature in `lib/src/features/<feature>/` has:
- `data/datasources/` — Local (Drift) and remote (Dio) data sources
- `data/models/` — Freezed data models (serialization layer)
- `data/repositories/` — Repository implementations
- `domain/entities/` — Pure Dart entity classes
- `domain/repositories/` — Abstract repository interfaces
- `presentation/notifiers/` — Riverpod notifiers (state management)
- `presentation/pages/` — Full-screen page widgets
- `presentation/widgets/` — Feature-specific reusable widgets
- `providers.dart` — All Riverpod provider declarations for this feature

## Naming Conventions
- Files: `snake_case.dart` (e.g., `scoring_notifier.dart`)
- Classes/enums: `PascalCase` (e.g., `ScoringNotifier`)
- Variables/functions: `camelCase` (e.g., `currentInnings`)
- Pages: `*_page.dart` suffix
- Notifiers: `*_notifier.dart` suffix
- Models: `*_model.dart` suffix (data layer)
- Entities: plain name (e.g., `delivery.dart`, not `delivery_entity.dart`)

## Code Generation
Files matching `*.g.dart`, `*.freezed.dart`, `*.gr.dart` are auto-generated.
Run: `dart run build_runner build --delete-conflicting-outputs`

## State Management
- Use `@riverpod` annotation (code generation) for providers
- Prefer `Notifier` + `Freezed` state class for feature state
- Split only when provider exceeds ~200 lines
- Use `switch` expressions for cricket logic

## Build Flavors

Two Android product flavors configured in `android/app/build.gradle.kts`:

| Flavor | applicationId | Firebase | Usage |
|--------|--------------|----------|-------|
| `dev` | `com.cricapp.cricapp` | Existing `cricapp-7403d` project | Daily development, testing |
| `prod` | `in.cricscores.app` | Separate prod project (TBD) | Production releases |

**Dev builds (default):** `flutter run --flavor dev` — uses existing Firebase config, no extra flags needed.
**Prod builds:** `flutter run --flavor prod --dart-define=FLAVOR=prod` — requires prod `google-services.json` in `android/app/src/prod/`.

Flavor-specific `google-services.json` files live in `android/app/src/<flavor>/`.

Dart-side flavor detection via `AppConstants.flavor` and `AppConstants.isProduction` (in `lib/src/core/constants/app_constants.dart`). API/WS URLs auto-switch based on flavor.

`flutter test` and `flutter analyze` don't need `--flavor` — they bypass the Android build system.

## Testing
- Test files mirror `src/` structure in `test/`
- Use `mocktail` for mocking
- TDD: write tests BEFORE implementation per PLAYBOOK.md
