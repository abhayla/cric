# Project Management

---

## Part 1: Documentation Structure

### Documentation Map

| File Path | Purpose | Update Frequency |
|-----------|---------|-----------------|
| `CLAUDE.md` | Claude Code project instructions, code principles, architecture | Rarely (protected) |
| `README.md` | Project overview, tech stack, doc links for external visitors | Per phase completion |
| `.claude/rules.md` | File placement rules, folder structure, naming conventions | Rarely (protected) |
| `docs/CONTINUE_PROMPT.md` | Session handoff context and next steps | Every session |
| `docs/planning/PDR.md` | Product requirements, user stories, success metrics | Per phase completion |
| `docs/planning/IMPLEMENTATION_PLAN.md` | Phased roadmap, architecture, packages | Per phase completion |
| `docs/planning/DATABASE.md` | 28 tables, 5 views, indexes, local SQLite schema | When schema changes |
| `docs/planning/API.md` | REST endpoints, WebSocket protocol | When API changes |
| `docs/planning/SCORING_RULES.md` | Match state machine, delivery pipeline, cricket rules | When rules change |
| `docs/planning/blueprint.html` | Interactive wireframes, architecture diagrams | Per phase completion |
| `docs/planning/CRICHEROES_REFERENCE.md` | CricHeroes competitive analysis knowledge base | When starting a new CricApp phase |
| `docs/process/PROJECT_MANAGEMENT.md` | This file — doc map, maintenance rules, codebase structure enforcement | When docs added/moved or structure rules change |
| `docs/process/CODE_STANDARDS.md` | Single reference for all coding conventions: naming, API design, state management, error handling, testing, performance, logging, linting, tooling | When conventions change |
| `docs/process/IMPLEMENTATION_PRACTICES.md` | Feature workflow, offline-first, state management, testing | When practices evolve |
| `docs/process/CODE_FIXES.md` | Debugging workflow, common issues, fix protocol | When patterns discovered |
| `docs/process/GITHUB_ISSUES.md` | Issue templates, labels, milestones, workflow | When process changes |
| `docs/process/CLAUDE_CODE_CONFIG.md` | Sub-agent specs, skill definitions | When agents/skills change |

### Folder Structure

```
docs/
├── planning/               # WHAT to build — product specs, architecture, schema
│   ├── PDR.md
│   ├── IMPLEMENTATION_PLAN.md
│   ├── DATABASE.md
│   ├── API.md
│   ├── SCORING_RULES.md
│   ├── blueprint.html
│   └── CRICHEROES_REFERENCE.md
├── process/                # HOW to build — workflows, standards, practices
│   ├── PROJECT_MANAGEMENT.md
│   ├── CODE_STANDARDS.md
│   ├── IMPLEMENTATION_PRACTICES.md
│   ├── CODE_FIXES.md
│   ├── GITHUB_ISSUES.md
│   └── CLAUDE_CODE_CONFIG.md
└── CONTINUE_PROMPT.md      # Session handoff (root for quick access)
```

### Documentation Rules

1. **No duplication.** If information exists in another doc, cross-reference it with a relative link. Example: "See [SCORING_RULES.md](../planning/SCORING_RULES.md) Section 2 for the delivery pipeline."
2. **Every new doc must be added to the Documentation Map** in this file before it is considered complete.
3. **Use Markdown ATX headings** (`#`, `##`, `###`) — not setext (underline) style.
4. **Use relative paths** for all cross-references between docs (e.g., `../planning/DATABASE.md`).
5. **Tables over prose** for structured data (schemas, endpoints, feature lists).
6. **Code blocks with language hints** for all code snippets (e.g., ` ```dart`, ` ```typescript`).

### When to Create a New Doc vs Extend an Existing One

```
Is the topic a new concern that doesn't fit any existing doc?
├── YES → Does it belong to "what to build" or "how to build"?
│         ├── What to build → Create in docs/planning/
│         └── How to build → Create in docs/process/
│         Then add to the Documentation Map above.
└── NO → Extend the existing doc.
         ├── Add a new section (##) if the topic is distinct
         └── Extend an existing section if the topic is closely related
```

**Threshold:** A new doc is warranted when the topic would add more than ~100 lines to an existing doc and is conceptually independent.

### Protected Files

The following files require explicit user approval before modification:

- `CLAUDE.md` — Project-wide instructions and code principles
- `.claude/rules.md` — File placement rules and folder structure

Changes to these files should be proposed with a clear rationale and specific diffs. Never weaken the YAGNI/KISS/DRY rules or the anti-patterns list without user consent.

---

## Part 2: Codebase Structure

This part defines HOW codebase structure rules are enforced. For WHAT the rules are, see [.claude/rules.md](../../.claude/rules.md).

### Section 1: Structure Governance

**Single source of truth:** `.claude/rules.md` defines the placement rules, decision trees, naming conventions, and anti-patterns. This document defines how those rules are enforced, validated, and evolved.

**Protected status:** `rules.md` is locked via `.claude/settings.json` deny rules. Changes require explicit user approval — Claude Code cannot modify it autonomously.

**Change proposal process:**
1. Create a GitHub issue with: current limitation, proposed change, specific diffs to `rules.md`, migration path for existing files, and rationale
2. User reviews and either approves or requests changes
3. If approved, user grants temporary edit permission
4. Apply changes to `rules.md` and commit with justification in the commit message

**Ownership model:**

| Role | Who | Responsibility |
|------|-----|----------------|
| Architect | User | Owns structure rules, approves all changes |
| Enforcer | Claude Code | Follows rules exactly as written, flags violations |
| Advisors | Research agents | Investigate and recommend, never modify |

### Section 2: Enforcement Layers

Five layers of defense, from earliest to latest:

| Layer | Mechanism | When | Bypassable? | Status |
|-------|-----------|------|-------------|--------|
| 1. Instructions | `CLAUDE.md` mandate to follow `rules.md` | Session start | No | Active now |
| 2. Research agents | `ui-researcher`, `api-researcher` validate placement | Before implementation | Yes (optional) | Active now |
| 3. Pre-commit hook | Custom validation script in `scripts/validate-structure/` | Before `git commit` | Yes (`--no-verify`) | Implement in Phase 1 |
| 4. CI pipeline | GitHub Actions `structure-check.yml` | On PR / push to main | No (blocks merge) | Implement in Phase 1 |
| 5. Code review | PR checklist item for structure compliance | PR review | Yes (human override) | Implement when PRs start |

**Key principle:** Catch violations at the earliest possible point — fixing a planned path is cheaper than `git mv` on an implemented file.

**Cross-references:** [CLAUDE_CODE_CONFIG.md](CLAUDE_CODE_CONFIG.md) (agents), [GITHUB_ISSUES.md](GITHUB_ISSUES.md) (PR template)

### Section 3: Validation Workflow

#### Manual Validation (before creating any file)

Use this 5-step checklist before creating any new file:

1. Open [.claude/rules.md](../../.claude/rules.md) Section 3 (Decision Tree)
2. Ask "What am I creating?" — follow the decision tree to the correct path
3. Verify naming convention matches [.claude/rules.md](../../.claude/rules.md) Section 5
4. Check anti-patterns in [.claude/rules.md](../../.claude/rules.md) Section 4
5. Create the file in the validated location

#### Automated Validation (implement when code exists)

**What to validate:**

Flutter (`apps/mobile/`):
- Feature modules have required subdirectories (`domain/entities/`, `data/datasources/`, `presentation/pages/`, `providers.dart`, etc.)
- No widgets in `core/` (widgets belong in `shared/widgets/` or feature `presentation/widgets/`)
- All Dart files use `snake_case` naming (excluding generated `*.g.dart`, `*.freezed.dart`, `*.gr.dart`)
- No cross-feature `data/` or `domain/` imports (features must communicate through shared providers or shared modules)

Server (`apps/server/`):
- Services named `*.service.ts`
- No route file imports in service files (dependency direction: routes → services → db)
- Route files in `src/routes/v1/`, services in `src/services/`, schemas in `src/db/schema/`

**Where scripts live:** `scripts/validate-structure/` (created in Phase 1 when code exists)

**Called by:** Pre-commit hook (layer 3) and CI pipeline (layer 4)

**Cross-reference:** [.claude/rules.md](../../.claude/rules.md) Sections 3-5 for the complete rule definitions

### Section 4: Violation Handling

#### Severity Levels

| Severity | Example | Action |
|----------|---------|--------|
| Critical | Business logic in `presentation/`, circular dependency between features | Fix immediately, block PR merge |
| High | Cross-feature `data/` or `domain/` import, widget placed in `core/` | Fix before merge |
| Medium | File in wrong subfolder within a feature (e.g., model in `entities/`) | Fix in same PR or immediate follow-up |
| Low | Naming inconsistency (e.g., missing `_notifier` suffix) | Fix opportunistically |

#### Correction Rules

- Always use `git mv` to move files — never delete + recreate (preserves git history and blame)
- After moving a file: grep for the old import path, update all occurrences
- Run tests after every move to catch broken imports
- Commit message format: `refactor: move <file> to <correct path> per rules.md`

#### Temporary Violations (during prototyping only)

- Mark with `// TODO(structure): Move to <correct path>` and link a GitHub issue
- Must be resolved before merging to `main`
- Never allow temporary violations to accumulate — each gets its own tracking issue

### Section 5: New Feature Folder

Do not duplicate the decision tree or feature template here. Use these cross-references:

- **Placement rules:** [.claude/rules.md](../../.claude/rules.md) Section 3 (Decision Tree)
- **Canonical feature template:** [.claude/rules.md](../../.claude/rules.md) Section 1 (Flutter App structure)
- **Implementation workflow:** [IMPLEMENTATION_PRACTICES.md](IMPLEMENTATION_PRACTICES.md) Section 1, Steps 4-5

### Section 6: Structure Evolution

#### When to Evolve the Structure

- A new architectural pattern is needed that the current structure doesn't accommodate
- A scaling issue makes the current structure unwieldy (e.g., a feature module growing past ~30 files)
- A technology change requires different conventions (e.g., migrating state management)

#### When NOT to Evolve

- Mid-phase (finish the current phase first)
- To accommodate lazy coding or skip the decision tree
- Without a clear, measurable improvement over the current structure
- Under time pressure (structural changes need careful migration)

#### Proposal Process

Same governance as Section 1: create a GitHub issue with the current limitation, proposed change, specific diffs to `rules.md`, migration path for existing files, and a rollback plan.

#### Migration Strategy (4 phases)

1. **Deprecate** — Add `@Deprecated` annotations to old patterns, document the migration in the GitHub issue
2. **Introduce** — Create the new pattern in parallel (both old and new coexist temporarily)
3. **Migrate** — Move files incrementally, feature by feature, running tests after each move
4. **Remove** — Delete the old pattern, update `rules.md` (with user approval), clean up any remaining references

#### Communication

- Announce the change in [CONTINUE_PROMPT.md](../CONTINUE_PROMPT.md) so the next session is aware
- Update `rules.md` only after user approval (protected file)
- Use a clear commit message with rationale: `refactor: migrate <pattern> — <why>`

### Section 7: CI Integration

> **Status:** Concepts only — actual YAML created in Phase 1 when code and CI exist.

A GitHub Actions workflow (`structure-check.yml`) should validate:

- Feature modules have required subdirectories (`domain/entities/`, `providers.dart`, etc.)
- No widgets in `core/`
- `snake_case` naming for all Dart files (excluding generated `*.g.dart`, `*.freezed.dart`, `*.gr.dart`)
- No cross-feature `data/` or `domain/` imports
- Server services named `*.service.ts`
- No route imports in service files

**Triggers:** On PR to `main` + push to `main`

**Blocks merge:** Yes (required status check)

**Actual implementation:** Created in Phase 1 when code exists to validate against. The validation scripts in `scripts/validate-structure/` are shared between the pre-commit hook (layer 3) and this CI workflow (layer 4).

### Section 8: Claude Code Integration

The enforcement layers connect to existing Claude Code tooling:

- **Agents (layer 2):** See [CLAUDE_CODE_CONFIG.md](CLAUDE_CODE_CONFIG.md) — `ui-researcher` validates widget placement against `rules.md`, `api-researcher` validates route/service structure
- **Skills:** `/build-check` catches analyzer errors from misplaced imports. A future `/structure-check` skill will be added when validation scripts in `scripts/validate-structure/` exist.
- **Workflow integration:** See [IMPLEMENTATION_PRACTICES.md](IMPLEMENTATION_PRACTICES.md) Section 1, Step 4 for how structure validation fits into the feature implementation workflow
