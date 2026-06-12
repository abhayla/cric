---
name: flutter-model-entity-mapping
description: >
  Every @freezed data model must ship a companion X-extension with toEntity()
  so the domain layer never consumes raw API models. 20/20 model files follow
  this convention; a model without its mapper is a defect.
globs: ["apps/mobile/lib/src/features/*/data/models/*.dart"]
synthesized: true
version: "1.0.0"
private: false
---

# Model → Entity Mapping (X-Extension Convention)

Every `@freezed` data model in `apps/mobile/lib/src/features/*/data/models/`
MUST have a companion extension named `<ModelName>X` that provides
`toEntity()`, converting the JSON-shaped model into its domain entity.
All 20 model files in this codebase comply — new models MUST NOT break the streak.

## The pattern

From `apps/mobile/lib/src/features/scoring/data/models/match_model.dart`
(lines 43–76):

```dart
@freezed
abstract class MatchModel with _$MatchModel {
  const factory MatchModel({
    required String id,
    @JsonKey(name: 'homeTeamId') required String homeTeamId,
    // ...
  }) = _MatchModel;

  factory MatchModel.fromJson(Map<String, dynamic> json) =>
      _$MatchModelFromJson(json);
}

extension MatchModelX on MatchModel {
  Match toEntity() => Match(
        id: id,
        homeTeamId: homeTeamId,
        format: MatchFormat.fromApiValue(format),
        status: MatchStatus.fromApiValue(status),
        createdAt:
            createdAt != null ? DateTime.parse(createdAt!) : DateTime.now(),
        // ...
      );
}
```

A single model file MAY contain multiple model classes — each gets its own
X-extension (e.g., `PlayingXIModelX` lives in the same `match_model.dart`,
lines 99–110). Other compliant examples: `player_profile_model.dart`,
`team_model.dart`.

## Why the extension, not a method on the class

Freezed 3.x models are `abstract class ... with _$Mixin` — custom methods in
the class body conflict with code generation. The X-extension keeps the mapper
out of the generated surface (see also `.claude/rules/flutter.md`, "Generated
Code": custom methods go in extensions, not the class body).

## Where conversion responsibilities live

| Concern | Belongs in |
|---|---|
| Wire format (`@JsonKey`, `@Default`, nullable raw strings) | The `@freezed` model |
| Enum parsing (`MatchFormat.fromApiValue(format)`) | `toEntity()` in the X-extension |
| String → `DateTime` parsing, null fallbacks, default values for optional API fields | `toEntity()` in the X-extension |
| Business logic, computed display values | The domain entity (`apps/mobile/lib/src/features/*/domain/entities/`) |

## Rules

- Every new `@freezed` model MUST get an `extension <ModelName>X on <ModelName>`
  with `Entity toEntity()` in the same file, directly below the model class.
- Repositories MUST call `.toEntity()` before returning data to the domain
  layer. Domain entities and presentation code MUST NEVER import a
  `data/models/*.dart` file directly — they consume entities from
  `domain/entities/` only.
- Type conversions (string enums → typed enums, ISO strings → `DateTime`,
  nullable API fields → defaulted entity fields) MUST happen inside
  `toEntity()` — NOT scattered through notifiers or widgets. Example: 
  `magicOverRunMultiplier: magicOverRunMultiplier ?? 2` lives in
  `MatchModelX.toEntity()`, so every consumer sees the defaulted value.
- The reverse direction (entity → request payload) is NOT this extension's
  job — request bodies are built where the API call is made.

## CRITICAL RULES

- Every `@freezed` model MUST have a companion `<ModelName>X` extension
  providing `toEntity()` — a model without one is a defect, not a style choice.
- Domain and presentation layers MUST NOT consume raw models — convert via
  `toEntity()` at the repository boundary.
- Mapping logic (enum parsing, date parsing, null defaults) MUST live inside
  `toEntity()`, never in the Freezed class body and never in widgets/notifiers.
- MUST NOT add custom methods to the Freezed class body — Freezed 3.x requires
  extensions for custom behavior.
