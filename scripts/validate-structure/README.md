# Structure Validation Scripts

These scripts enforce the file placement rules defined in `.claude/rules.md`. They are used by both the CI pipeline (`.github/workflows/ci.yml`) and can be run manually during development.

## Scripts

### `flutter-validator.js`

Validates Flutter app structure in `apps/mobile/`.

**Checks:**
1. No files directly in `lib/` except `main.dart`
2. `snake_case.dart` naming for all Dart files (excluding generated `*.g.dart`, `*.freezed.dart`, `*.gr.dart`)
3. No widgets in `core/` (must be in `shared/widgets/` or feature `presentation/widgets/`)
4. No cross-feature `data/` or `domain/` imports
5. Feature modules have required subdirectories (`domain/entities/`, `data/datasources/`, `presentation/pages/`, etc.) and `providers.dart`

### `server-validator.js`

Validates Bun server structure in `apps/server/`.

**Checks:**
1. Service files have `.service.ts` suffix
2. No route imports in service files (dependency direction: routes -> services -> db)
3. `kebab-case` naming for TypeScript files (dot-notation allowed for services)
4. Only expected directories in `src/` (`routes`, `services`, `db`, `middleware`, `types`, `websocket`, `utils`)
5. No files in `src/` root except `index.ts`
6. Route files use `kebab-case` naming

## Running Manually

```bash
node scripts/validate-structure/flutter-validator.js
node scripts/validate-structure/server-validator.js
```

## Exit Codes

- `0` — All checks passed (or target directory doesn't exist yet)
- `1` — Violations found (listed in output)

## Violation Severities

| Severity | Description | Action |
|----------|-------------|--------|
| Critical | Business logic in wrong layer, circular dependencies | Fix immediately, blocks merge |
| High | Cross-feature imports, widgets in core/ | Fix before merge |
| Medium | Wrong subfolder, missing required directories | Fix in same PR |
| Low | Naming inconsistencies | Fix opportunistically |
