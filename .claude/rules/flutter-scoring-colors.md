---
name: flutter-scoring-colors
description: >
  The M3 ColorScheme derives from one seed; cricket-semantic colors (four,
  six, wicket, etc.) are fixed AppColors constants that widgets must
  reference — never Colors.* or ad-hoc hex literals.
globs: ["apps/mobile/lib/src/core/theme/**/*.dart", "apps/mobile/lib/src/features/*/presentation/widgets/**/*.dart"]
synthesized: true
version: "1.0.0"
private: false
---

# Theme Seed and Cricket-Semantic Colors

The app's Material 3 `ColorScheme` is generated from exactly one seed, and
cricket-semantic colors are pinned constants that the M3 palette MUST NOT
replace. The single source of truth is
`apps/mobile/lib/src/core/theme/app_colors.dart`:

```dart
abstract final class AppColors {
  /// M3 seed color — blue.
  static const Color seed = Color(0xFF1976D2);

  // Semantic scoring colors (fixed, not from M3 palette)
  static const Color four = Color(0xFF1565C0);
  static const Color six = Color(0xFF6A1B9A);
  static const Color wicket = Color(0xFFC62828);
  static const Color dot = Color(0xFF757575);
  static const Color wide = Color(0xFFEF6C00);
  static const Color noBall = Color(0xFFD84315);
  static const Color bye = Color(0xFF00838F);
  static const Color legBye = Color(0xFF2E7D32);
  static const Color maiden = Color(0xFF1565C0);
}
```

## Why two color systems

- **M3-derived colors** (surface, primary, outline, ...) adapt to light/dark
  themes and come from `ColorScheme.fromSeed(seedColor: AppColors.seed)`.
  Use `Theme.of(context).colorScheme.*` for structural UI (backgrounds,
  cards, text, dividers).
- **Cricket-semantic colors** carry scoring meaning (a four is always THIS
  blue, a wicket always THIS red, across both themes and in every chart,
  chip, and ball indicator). They are deliberately NOT theme-derived so a
  dark-mode palette shift can never make a wicket look like a six.

## MUST / MUST NOT

- Widgets rendering scoring semantics (boundary chips, ball-by-ball dots,
  wicket markers, extras labels, over summaries, charts) MUST reference
  `AppColors.four`, `AppColors.wicket`, etc. — by name, not by value.
- MUST NEVER use `Colors.red`, `Colors.green`, `Colors.purple`, or any
  Material swatch for scoring semantics — they don't match the pinned values
  and drift per Material version.
- MUST NEVER inline ad-hoc hex (`Color(0xFFC62828)`) in a widget, even when
  the value happens to match an `AppColors` constant — a duplicated literal
  silently decouples from the SSOT when the constant changes.
- MUST NOT add a second `ColorScheme.fromSeed` seed or per-screen seeds —
  `AppColors.seed` (#1976D2) is the only seed.
- New semantic colors (e.g., a future "penalty runs" color) MUST be added as
  constants in `app_colors.dart` first, then referenced.

## Known debt — do not add to it

`manhattan_chart`, `mvp_ranking_widget`, and `run_rate_chart` still hardcode
hex values that duplicate `AppColors` constants. This is tracked debt:

- New code MUST NOT copy that pattern, including inside those three files —
  any new line in them references `AppColors`.
- When touching one of those widgets for another reason, migrating its
  hardcoded hex to `AppColors` is an encouraged Boy-Scout fix (small,
  behavior-preserving).

## CRITICAL RULES

- The M3 `ColorScheme` derives from `AppColors.seed` (#1976D2) ONLY — never
  add a second seed.
- Cricket-semantic colors are FIXED constants in
  `core/theme/app_colors.dart` — never M3-generated, never theme-dependent.
- Widgets MUST reference `AppColors.*` constants for scoring semantics —
  NEVER `Colors.*` swatches and NEVER inline hex literals, even
  value-matching ones.
- New semantic colors get an `AppColors` constant FIRST; the three
  known-debt chart widgets MUST NOT gain new hardcoded hex.
