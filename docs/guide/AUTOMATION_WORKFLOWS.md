# Automation Workflows Reference

A comprehensive guide to the CricScores automation ecosystem: hooks, agents, skills, CI/CD, and workflow integrations. Designed as a reusable reference for replicating this system in new projects.

**Project:** CricScores (Cricket Scoring Mobile App)
**Stack:** Flutter + Riverpod | Bun + ElysiaJS + Drizzle | PostgreSQL | Firebase Auth
**Maturity:** Built across Phases 1-4 over 6 months (1,600+ Flutter tests, 200+ server tests)

---

## Table of Contents

1. [Quick Start & Priority Tiers](#1-quick-start--priority-tiers)
2. [Prerequisites & Concepts](#2-prerequisites--concepts)
3. [Hook Automations](#3-hook-automations)
4. [Agent Automations](#4-agent-automations)
5. [Skill Automations](#5-skill-automations)
6. [Settings & Permissions](#6-settings--permissions)
7. [CI/CD Pipeline](#7-cicd-pipeline)
8. [Code Generation Workflow](#8-code-generation-workflow)
9. [TDD Workflow Automation](#9-tdd-workflow-automation)
10. [Session Management](#10-session-management)
11. [Debugging Workflow](#11-debugging-workflow)
12. [Integration Patterns](#12-integration-patterns)
13. [Customization Guide](#13-customization-guide)

---

## 1. Quick Start & Priority Tiers

### Purpose

This document captures every automation pattern in CricScores so the system can be replicated in new projects without reverse-engineering the original config files. It is structured in layers:

- **Newcomers** — Read Sections 1-2 for concepts, then jump to the tier you need
- **Experienced users** — Jump directly to any section; each is self-contained
- **Adapting for a new project** — Read Section 13 after understanding the patterns

### Priority Tiers

Set up automations in this order. Each tier builds on the previous one.

| Tier | Automation | Type | Purpose | Setup Effort |
|------|-----------|------|---------|-------------|
| **1 (Essential)** | protect-sensitive-files | Hook | Block writes to .env, credentials, keys | 30 min |
| | quality-gate | Hook | Block session end without handoff doc update | 30 min |
| | auto-format | Hook | Auto-format code after every edit | 30 min |
| | load-session-context | Hook | Inject session context at startup | 15 min |
| | guard-bash-commands | Hook | Block destructive git/file operations | 15 min |
| **2 (Recommended)** | validate-file-placement | Hook | Enforce project structure rules on every write | 1 hr |
| | guard-cross-feature-imports | Hook | Prevent architecture violations in imports | 30 min |
| | CI validation scripts | CI | Server-side mirror of hook validations | 2 hr |
| | code-reviewer | Agent | Post-implementation quality assessment | 30 min |
| | planner-researcher | Agent | Pre-implementation research and planning | 30 min |
| | tester | Agent | Test suite analysis and coverage review | 30 min |
| **3 (Domain)** | scoring-researcher | Agent | Cricket-specific rule verification | 30 min |
| | cricket-domain | Skill | Domain rules reference (auto-loaded) | 15 min |
| | cricheroes-comparator | Agent | Competitive feature comparison | 30 min |
| | reinject-after-compaction | Hook | Recover context after compaction | 30 min |
| | remind-schema-parity | Hook | Schema drift detection | 15 min |

### Recommended Setup Sequence

1. **Day 1:** Install Tier 1 hooks (protect-sensitive-files, quality-gate, auto-format, guard-bash-commands, load-session-context)
2. **Day 2:** Install Tier 2 hooks (validate-file-placement, guard-cross-feature-imports) + settings.json permissions
3. **Week 1:** Set up CI pipeline mirroring hook validations + configure research agents
4. **Week 2:** Add domain-specific agents and skills + schema parity hook
5. **Ongoing:** Tune rules as the project evolves; add accumulated knowledge to agent memory files

---

## 2. Prerequisites & Concepts

### Claude Code Fundamentals

Claude Code is an autonomous coding agent that uses a tool-based architecture. Three extension mechanisms allow you to customize its behavior:

| Mechanism | What It Does | When It Runs | Can Block? |
|-----------|-------------|-------------|-----------|
| **Hooks** | Shell scripts that intercept tool calls | Automatically on matching events | Yes (exit 2) |
| **Agents** | Specialized sub-agents with focused prompts | When explicitly invoked via `Task()` | No |
| **Skills** | Guided workflows with step-by-step instructions | When user types `/skill-name` | No |

**MCP Servers** provide additional tool capabilities (database queries, browser automation) but are not automations themselves.

### Hook Lifecycle

```
Session Start
  |
  v
SessionStart hooks fire
  (startup | resume | compact)
  |
  v
  +---> User request arrives
  |       |
  |       v
  |     Claude plans tool call
  |       |
  |       v
  |     PreToolUse hooks fire (matched by tool name)
  |       |
  |       +--[exit 0]--> Tool executes
  |       |                  |
  |       |                  v
  |       |              PostToolUse hooks fire
  |       |                  |
  |       |                  v
  |       |              Continue processing
  |       |
  |       +--[exit 2]--> Tool BLOCKED, Claude sees error message
  |
  v
Session Stop
  |
  v
Stop hooks fire
  (can block with exit 2 to prevent session end)
```

**Exit codes:**
- `exit 0` — Allow (for PreToolUse) or success (for PostToolUse/SessionStart/Stop)
- `exit 2` — Block the operation (for PreToolUse/Stop only)
- `stdout` — Message shown to Claude as informational context
- `stderr` — Message shown to Claude as error/warning context

### Agent vs Skill Decision Matrix

| Criterion | Use an Agent | Use a Skill |
|-----------|-------------|------------|
| Invoked by | Main agent via `Task()` | User via `/skill-name` |
| Autonomy | Runs independently, returns findings | Guides the main agent step-by-step |
| Context | Gets its own fresh context window | Runs within main conversation context |
| Writes code? | Never (research only in CricScores) | Indirectly (guides main agent to write) |
| Model | Can specify different model (haiku/sonnet) | Uses main conversation model |
| Best for | Research, analysis, review | Multi-step workflows, guided processes |
| Example | `code-reviewer` analyzes code quality | `/tdd auth domain` guides TDD workflow |

### `.claude/` Directory Structure

```
.claude/
  settings.json          # Permissions (allow/deny) + hook configuration
  rules.md               # File placement rules (protected)
  agents/                # Agent definition files (.md)
    memory/              # Accumulated knowledge per agent
  skills/                # Skill definition files
    <skill-name>/
      SKILL.md           # Skill instructions
  hooks/                 # Hook scripts (.ps1 / .sh)
```

---

## 3. Hook Automations

### Overview

The `.claude/hooks/` directory contains 11 hook scripts. 10 are active (referenced in `settings.json`), and 1 is a deprecated predecessor. Five active hooks are blocking (can prevent operations), five are non-blocking (informational only).

| # | Hook | Event | Matcher | Blocks? | Purpose |
|---|------|-------|---------|---------|---------|
| 1 | validate-file-placement | PreToolUse | Edit\|Write | Yes | Enforce project structure rules |
| 2 | protect-sensitive-files | PreToolUse | Edit\|Write | Yes | Block writes to .env, credentials, keys |
| 3 | guard-cross-feature-imports | PreToolUse | Write | Yes | Prevent cross-feature data/domain imports |
| 4 | guard-bash-commands | PreToolUse | Bash | Yes | Block destructive git/file operations |
| 5 | auto-invoke-cricheroes-comparator | PreToolUse | Write | No | Remind to run competitor comparison |
| 6 | load-session-context | SessionStart | startup\|resume | No | Inject "What to Do Next" from handoff doc |
| 7 | reinject-after-compaction | SessionStart | compact | No | Re-inject critical rules + git state |
| 8 | auto-format | PostToolUse | Edit\|Write | No | Auto-format .dart and .ts files |
| 9 | remind-schema-parity | PostToolUse | Edit\|Write | No | Remind to check Drift/Drizzle alignment |
| 10 | quality-gate | Stop | (all) | Yes | Block session end without handoff update |

> **Deprecated:** `remind-session-handoff.ps1` still exists in `.claude/hooks/` but is not referenced in `settings.json`. It was replaced by `quality-gate.ps1`, which is a superset (adds uncommitted source changes check on top of the original handoff doc check).

---

### 3.1 PreToolUse Hooks

#### validate-file-placement

**Problem Solved:** Without enforcement, files end up in wrong directories (widgets in `core/`, models in `domain/`, files with wrong naming conventions). Mistakes are expensive to fix after tests depend on incorrect paths.

**How It Works:**
```
ON PreToolUse(Edit | Write):
  PARSE tool input for file_path
  NORMALIZE path separators (\ -> /)

  SKIP if path matches non-validated areas:
    .claude/, docs/, test/, node_modules/, build/,
    android/, .github/, scripts/, generated files (*.g.dart)

  IF path is in apps/mobile/:
    BLOCK if file directly in lib/ (except main.dart)
    BLOCK if Dart filename is not snake_case
    BLOCK if widget class found in core/
    BLOCK if models/ folder found under domain/
    BLOCK if page file lacks _page.dart suffix
    BLOCK if notifier file lacks _notifier.dart suffix
    BLOCK if model file lacks _model.dart suffix

  IF path is in apps/server/:
    BLOCK if TypeScript filename is not kebab-case (except dot-notation services)
    BLOCK if service file lacks .service.ts suffix
    BLOCK if file placed in src/ root (except index.ts)
```

**Configuration:**
```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "powershell -ExecutionPolicy Bypass -File .claude/hooks/validate-file-placement.ps1"
      }]
    }]
  }
}
```

**Customization:** Replace the naming rules with your project's conventions. The pattern of "skip non-validated paths, then apply platform-specific rules" is universally applicable.

---

#### protect-sensitive-files

**Problem Solved:** AI agents can accidentally write to `.env` files or credential files, exposing secrets in version control.

**How It Works:**
```
ON PreToolUse(Edit | Write):
  PARSE file_path from tool input

  ALLOW .env.example, files in docs/, files in test/

  BLOCK if filename matches:
    .env*           -> "Use .env.example for templates"
    *credentials*   -> "Cannot write to credentials file"
    *service-account* -> "Cannot write to service account file"
    google-services.json -> "Contains Firebase credentials"
    *.key, *.pem, *.p12  -> "Cannot write to key/certificate file"
```

**Customization:** Add your project's sensitive file patterns (e.g., `*.keystore`, `firebase-config.json`, `*.pfx`).

---

#### guard-cross-feature-imports

**Problem Solved:** In a feature-first architecture, features must communicate through shared providers, not by importing each other's `data/` or `domain/` layers. Without enforcement, architecture erodes incrementally.

**How It Works:**
```
ON PreToolUse(Write):
  SKIP if not a .dart file in features/
  SKIP if generated file or test file

  EXTRACT current feature name from path:
    features/<CURRENT_FEATURE>/...

  FOR EACH import statement in file content:
    IF import path matches features/<OTHER_FEATURE>/(data|domain)/:
      BLOCK: "Cross-feature import detected. Feature 'X' imports from 'Y/data/'.
              Features communicate only through shared/ providers."
```

**Customization:** Adjust the import pattern regex for your architecture. The same pattern applies to any modular architecture (feature slices, bounded contexts, microservices).

---

#### guard-bash-commands

**Problem Solved:** Destructive git and file operations can cause irreversible damage. Even experienced developers occasionally `rm -rf` the wrong path or `git push --force` to main.

**How It Works:**
```
ON PreToolUse(Bash):
  PARSE command from tool input

  BLOCK with specific message if command matches:
    rm -rf / rm -fr        -> "Remove files individually"
    git push --force       -> "Use --force-with-lease"
    git push -f            -> "Use --force-with-lease"
    git reset --hard       -> "Stage changes or stash first"
    git clean -f / -fd     -> "Permanently deletes untracked files"
    git branch -D          -> "Use git branch -d for safe deletion"
    --no-verify            -> "Run with hooks enabled"
```

**Customization:** Add project-specific dangerous commands (e.g., `docker system prune -a`, `DROP TABLE`, production deployment commands).

---

#### auto-invoke-cricheroes-comparator

**Problem Solved:** Competitive analysis should happen before implementation, not after. This hook detects when a new page file is being created and reminds to run the comparison agent first.

**How It Works:**
```
ON PreToolUse(Write):
  IF file_path matches features/*/presentation/pages/*_page.dart:
    EXTRACT feature name from path
    OUTPUT (non-blocking): "REMINDER: New page detected in '<feature>' feature.
      Before implementing, invoke the cricheroes-comparator agent."

  EXIT 0 (never blocks)
```

**Customization:** Replace with your competitor comparison trigger. The pattern of "detect new feature file creation, remind to run analysis" works for any competitive analysis workflow.

---

### 3.2 SessionStart Hooks

#### load-session-context

**Problem Solved:** Each new session starts with zero context about what was accomplished in the last session. Without this hook, the agent wastes time re-discovering project state.

**How It Works:**
```
ON SessionStart(startup | resume):
  READ docs/CONTINUE_PROMPT.md

  IF file exists:
    EXTRACT "## What to Do Next" section using regex
    OUTPUT:
      "=== SESSION CONTEXT (from CONTINUE_PROMPT.md) ==="
      "WHAT TO DO NEXT:"
      <extracted next steps>
      "=== Read full context: docs/CONTINUE_PROMPT.md ==="
```

**Customization:** Adapt the section heading and file path for your project's handoff document.

---

#### reinject-after-compaction

**Problem Solved:** When Claude Code compacts its context window (to stay within token limits), critical rules are lost. This hook re-injects the most important rules so the agent doesn't violate them after compaction.

**How It Works:**
```
ON SessionStart(compact):
  OUTPUT condensed critical rules:
    - File placement rules (10 rules, one line each)
    - TDD workflow reminder
    - Delivery processing pipeline (10 steps)
    - Match state machine
    - Critical cricket rules (5 key rules)

  READ git state:
    - Current branch
    - Last commit
    - Modified files (unstaged)
    - Staged files

  READ CONTINUE_PROMPT.md:
    - Current phase
    - Current screen being worked on
    - Checklist progress (X done, Y pending)
    - "What to Do Next" first 5 lines
```

**Customization:** This is the most project-specific hook. Replace the domain rules with your own critical rules, but keep the pattern of: (1) condensed rules, (2) git state, (3) current task context.

---

### 3.3 PostToolUse Hooks

#### auto-format

**Problem Solved:** Code formatting inconsistency between manual edits and agent edits. Auto-formatting on every write ensures consistent style without manual intervention.

**How It Works:**
```
ON PostToolUse(Edit | Write):
  PARSE file_path from tool input (PostToolUse receives JSON with tool_input)

  SKIP if generated file (*.g.dart, *.freezed.dart, *.gr.dart)

  IF .dart file:
    RUN: dart format --fix "<file_path>"

  IF .ts file:
    IF .prettierrc exists:
      RUN: npx prettier --write "<file_path>"
    ELSE:
      RUN: npx prettier --write --single-quote --trailing-comma all "<file_path>"

  EXIT 0 always (formatting failure never blocks)
```

**Key Design Decision:** The hook never blocks on formatting failure (`exit 0` always). A formatting failure should never prevent the agent from continuing its work.

**PostToolUse Input Format:** PostToolUse hooks receive different JSON than PreToolUse:
```json
{
  "tool_input": {
    "file_path": "/path/to/file.dart",
    "content": "..." // for Write
  }
}
```

**Customization:** Replace `dart format` and `prettier` with your project's formatters (e.g., `black` for Python, `gofmt` for Go, `rustfmt` for Rust).

---

#### remind-schema-parity

**Problem Solved:** When a Drizzle (server) schema is modified, the corresponding Drift (mobile) schema must be updated too (and vice versa). Without a reminder, schema drift accumulates.

**How It Works:**
```
ON PostToolUse(Edit | Write):
  PARSE file_path from tool input

  IF file matches apps/server/src/db/schema/*.ts (Drizzle):
    OUTPUT: "SCHEMA MODIFIED: Run /schema-parity to check Drift/Drizzle alignment.
      Also run: cd apps/server && bunx drizzle-kit generate"

  IF file matches apps/mobile/lib/src/shared/data/database/tables/*.dart (Drift):
    OUTPUT: "SCHEMA MODIFIED: Run /schema-parity to check Drift/Drizzle alignment.
      Also run: cd apps/mobile && dart run build_runner build --delete-conflicting-outputs"

  EXIT 0 always (never blocks)
```

**Customization:** Replace with your own schema locations. The pattern applies to any project with dual schema sources (e.g., Prisma + Realm, TypeORM + Room).

---

### 3.4 Stop Hooks

#### quality-gate

**Problem Solved:** Sessions ending without updating the handoff document leave the next session with stale context. Uncommitted source changes can be lost between sessions.

**How It Works:**
```
ON Stop:
  IF no git changes at all:
    EXIT 0 (pure research session, skip all checks)

  CHECK for source file changes (apps/, scripts/, .claude/hooks|skills):
    IF no source changes:
      EXIT 0 (pure doc/config session, skip checks)

  CHECK 1 - CONTINUE_PROMPT.md updated:
    READ git diff for docs/CONTINUE_PROMPT.md (staged + unstaged)
    IF no diff: FAIL "Session handoff doc not updated"

  CHECK 2 - Uncommitted source changes:
    SCAN git status for modified/untracked files in apps/
    IF found: FAIL "Uncommitted source changes in apps/"

  IF any failures:
    OUTPUT failure messages to stderr
    EXIT 2 (block session end)
```

**Key Design Decisions:**
1. Research-only sessions (no git changes) are never blocked
2. Doc-only sessions (no source file changes) are never blocked
3. Only blocks when source files changed but handoff doc wasn't updated
4. Warns (but still blocks) when source changes are uncommitted

**Customization:** Replace `CONTINUE_PROMPT.md` with your project's session handoff document. The pattern of "check if handoff doc was updated when source files changed" is universally applicable.

---

## 4. Agent Automations

### Overview

CricScores uses 14 agents across 3 categories. All agents are research-only (Read/Grep/Glob tools) and never write code. The main agent reads their findings and implements changes.

### Agent Categories

| Category | Agents | Purpose |
|----------|--------|---------|
| **Research** (6) | scoring-researcher, database-researcher, ui-researcher, api-researcher, planner-researcher, cricheroes-comparator | Gather domain-specific context before implementation |
| **Review** (5) | code-reviewer, tester, reviewer, system-architect, debugger | Verify quality after implementation |
| **Management** (3) | docs-manager, git-manager, database-admin | Operational tasks (docs, git, DB) |

### Model Assignment Strategy

Different agents have different cost/quality needs. Assigning cheaper models to simpler tasks saves cost without losing quality.

| Model | Cost | Quality | Assigned Agents | Rationale |
|-------|------|---------|----------------|-----------|
| **haiku** | Low | Good | ui-researcher, docs-manager, git-manager | Pattern matching + structured output; don't need deep reasoning |
| **sonnet** | Medium | Very Good | database-researcher, api-researcher, planner-researcher, code-reviewer, tester, cricheroes-comparator, database-admin | Technical analysis requiring moderate reasoning |
| **inherit** (main model) | High | Best | scoring-researcher, system-architect, debugger, reviewer | Complex domain logic, architectural decisions, root cause analysis |

**Decision Rule:** Use the cheapest model that produces acceptable output for the agent's task. Upgrade only when you see quality issues in agent results.

### Knowledge Accumulation Pattern

Six agents maintain persistent memory files in `.claude/agents/memory/`:

```
.claude/agents/memory/
  scoring-researcher.md    # Cricket rule edge cases, implementation pitfalls
  database-researcher.md   # Schema evolution decisions, migration gotchas
  code-reviewer.md         # Recurring patterns, common issues
  debugger.md              # Root cause patterns, debugging techniques
  system-architect.md      # Architectural trade-offs, design decisions
  reviewer.md              # Requirement gaps by feature type, recurring issues
```

**How it works:** Each agent's prompt includes instructions to:
1. Read its memory file at the start of every task
2. Append new insights at the end of every task
3. Keep entries concise: `- YYYY-MM-DD: <one-line insight>`

**Why this matters:** Over time, agents build project-specific knowledge that improves their analysis. A code-reviewer that has seen 20 previous reviews knows the project's recurring issues.

---

### 4.1 Research Agents

#### scoring-researcher

| Field | Value |
|-------|-------|
| Model | inherit (main) |
| Purpose | Analyze cricket scoring logic, delivery pipeline, strike rotation, undo mechanics |
| When to Invoke | Investigating scoring bugs, planning scoring features, verifying cricket rule correctness |
| Pre-reads | `SCORING_RULES.md`, `DATABASE.md`, `.claude/skills/cricket-domain/SKILL.md` |
| Output | Relevant rules, file paths, edge cases, test scenarios, potential issues |
| Has Memory | Yes |

#### database-researcher

| Field | Value |
|-------|-------|
| Model | sonnet |
| Purpose | Analyze schemas, migrations, sync engine, data access patterns |
| When to Invoke | Planning database changes, investigating sync issues, verifying schema correctness |
| Pre-reads | `DATABASE.md`, `API.md` (sync endpoints) |
| Output | Schema discrepancies, missing indexes, parity issues, sync edge cases |
| Has Memory | Yes |

#### ui-researcher

| Field | Value |
|-------|-------|
| Model | haiku |
| Purpose | Analyze Flutter UI implementation, widget structure, theme compliance |
| When to Invoke | Planning new screens, investigating UI bugs, verifying M3 Light theme |
| Pre-reads | `.claude/rules.md` (widget placement), wireframe HTML files |
| Output | Layout discrepancies, theme violations, accessibility issues, wireframe comparison |
| Has Memory | No |

#### api-researcher

| Field | Value |
|-------|-------|
| Model | sonnet |
| Purpose | Analyze REST API routes, service layer, WebSocket protocol, middleware |
| When to Invoke | Planning new endpoints, investigating API bugs, verifying API.md spec compliance |
| Pre-reads | `API.md`, `DATABASE.md` |
| Output | Spec mismatches, missing validation, service layer issues, WebSocket issues, auth gaps |
| Has Memory | No |

#### planner-researcher

| Field | Value |
|-------|-------|
| Model | sonnet |
| Purpose | Technical research, codebase analysis, system design, task decomposition |
| When to Invoke | Researching best practices, designing architectures, breaking down complex requirements |
| Pre-reads | Contextual (searches web + codebase based on task) |
| Output | Technical plans with architecture diagrams, implementation steps, risk assessment |
| Has Memory | No |

#### cricheroes-comparator

| Field | Value |
|-------|-------|
| Model | sonnet |
| Purpose | Compare features against CricHeroes (market leader, 40M+ users) |
| When to Invoke | Before implementing any new feature, screen, or significant UI component |
| Pre-reads | `CRICHEROES_REFERENCE.md`, relevant planning doc |
| Output | UI comparison table, UX flow comparison, feature gaps with ADOPT/SKIP/DEFER recommendations |
| Has Memory | No |

**Behavioral rules:** Always identifies at least one CricScores advantage. Never recommends ADOPT for features excluded from MVP. Suggests which phase DEFER items belong to.

---

### 4.2 Review Agents

#### code-reviewer

| Field | Value |
|-------|-------|
| Model | sonnet |
| Purpose | Comprehensive code quality assessment across 5 areas: quality, type safety, build, performance, security |
| When to Invoke | After implementing features, before merging PRs, investigating code quality |
| Output | Prioritized findings (Critical/High/Medium/Low) with specific code fix examples |
| Has Memory | Yes |

#### tester

| Field | Value |
|-------|-------|
| Model | sonnet |
| Purpose | Test execution analysis, coverage review, error scenario testing, build verification |
| When to Invoke | After implementing features, validating test suites, checking coverage |
| Pre-reads | `.claude/skills/tdd/SKILL.md`, `.claude/skills/cricket-domain/SKILL.md` |
| Output | Test results overview, coverage metrics, failed tests detail, performance metrics |
| Has Memory | No |

#### reviewer

| Field | Value |
|-------|-------|
| Model | inherit (main) |
| Purpose | Requirements verification, acceptance criteria traceability, final pass/fail verdict |
| When to Invoke | At PLAYBOOK Step 11 (Stage 3), after code-reviewer and tester have run |
| Pre-reads | GitHub issue, planning docs, wireframe, `CODE_STANDARDS.md`, `CLAUDE.md` |
| Output | Requirements Traceability Matrix with PASS/PASS WITH WARNINGS/BLOCK verdict |
| Has Memory | Yes |

**Core principle:** Every acceptance criterion must be traceable to working code AND a passing test.

**Review phases:**
1. Load the requirement (from GitHub issue)
2. Trace requirements to code (for each acceptance criterion: find implementation + find test)
3. Cross-domain verification (schema parity, API alignment, domain rules, wireframe, architecture)
4. Produce Requirements Traceability Matrix

#### system-architect

| Field | Value |
|-------|-------|
| Model | inherit (main) |
| Purpose | Architectural decisions, system design reviews, offline-first patterns, WebSocket protocol |
| When to Invoke | Proactively for architectural decisions; reactively for design reviews |
| Evaluation Lens | Offline-first, low-end Android (2GB RAM), intermittent connectivity, cricket rules, cross-layer impact |
| Output | Decision matrices, Mermaid diagrams, risk analysis with mitigations |
| Has Memory | Yes |

#### debugger

| Field | Value |
|-------|-------|
| Model | inherit (main) |
| Purpose | Issue investigation, system behavior analysis, log analysis, test failure debugging |
| When to Invoke | When fix iterations reach Tier 2 (6-7 attempts), complex multi-system issues |
| Process | Initial assessment, data collection, analysis, root cause identification, solution development |
| Output | Executive summary, technical analysis timeline, actionable recommendations with evidence |
| Has Memory | Yes |

---

### 4.3 Management Agents

#### docs-manager

| Field | Value |
|-------|-------|
| Model | haiku |
| Purpose | Documentation creation, maintenance, synchronization with code changes |
| When to Invoke | Creating/updating docs, establishing standards, syncing docs with code changes |
| Output | Documentation state assessment, changes made, gaps identified, recommendations |

#### git-manager

| Field | Value |
|-------|-------|
| Model | haiku |
| Purpose | Safe git operations: staging, committing, pushing |
| When to Invoke | When committing completed work with proper conventional commit messages |
| Security | Scans for confidential files before any git operation; blocks if found |
| Output | Summary of actions taken (staged files, commit message, push result) |

#### database-admin

| Field | Value |
|-------|-------|
| Model | sonnet |
| Purpose | Performance optimization, index management, query analysis, backup planning |
| When to Invoke | Diagnosing bottlenecks, optimizing DB structures, health assessments |
| Output | Diagnostic report with EXPLAIN ANALYZE results, optimization recommendations, SQL scripts |

---

## 5. Skill Automations

### Overview

CricScores uses 16 skills organized into 4 categories. All skills except `cricket-domain` have `disable-model-invocation: true`, meaning they must be explicitly invoked by the user via `/skill-name`.

### Skill Categories

| Category | Skills | Count |
|----------|--------|-------|
| **Test & Build** | score-test, server-test, sync-test, build-check, analyze | 5 |
| **Database** | db-migrate, drift-migrate, schema-parity | 3 |
| **Workflow** | session-handoff, tdd, commit-draft, issue-create, phase-gate, debug-log | 6 |
| **Verification** | screenshot-verify, cricket-domain | 2 |

### `disable-model-invocation: true` Pattern

**Rationale:** Skills contain detailed step-by-step instructions that could confuse the main agent if auto-loaded. By requiring explicit invocation (`/skill-name`), the user controls when the guided workflow activates.

**Exception:** `cricket-domain` does not have this flag because it's a reference skill (loaded automatically when scoring features are being worked on), not a workflow skill.

---

### 5.1 Test & Build Skills

#### /score-test

| Field | Value |
|-------|-------|
| Arguments | Optional: specific test file path |
| What It Does | Runs scoring engine test suite; reports pass/fail; suggests source files for failures |
| Commands | `flutter test test/src/features/scoring/` or `flutter test test/src/features/scoring/<path>` |

#### /server-test

| Field | Value |
|-------|-------|
| Arguments | Optional: specific test file path |
| What It Does | Runs Bun server test suite; reports pass/fail; reads failing tests to suggest fixes |
| Commands | `bun test` or `bun test <path>` |

#### /sync-test

| Field | Value |
|-------|-------|
| Arguments | Optional: "server" or "mobile" to filter |
| What It Does | Tests offline sync round-trip by running both server and client sync tests |
| Commands | `bun test test/services/sync.service.test.ts` + `flutter test test/src/shared/data/sync/` |

#### /build-check

| Field | Value |
|-------|-------|
| Arguments | None |
| What It Does | Runs build_runner for code generation, then flutter analyze for static analysis |
| Commands | `dart run build_runner build --delete-conflicting-outputs` + `flutter analyze` |

#### /analyze

| Field | Value |
|-------|-------|
| Arguments | None |
| What It Does | Faster alternative to /build-check — runs only flutter analyze without code generation |
| Commands | `flutter analyze` |

---

### 5.2 Database Skills

#### /db-migrate

| Field | Value |
|-------|-------|
| Arguments | None |
| What It Does | Generates Drizzle migrations from schema changes, reviews SQL, applies migration |
| Commands | `bunx drizzle-kit generate` + `bunx drizzle-kit migrate` + `bun run src/db/seed/master_data.ts` |

#### /drift-migrate

| Field | Value |
|-------|-------|
| Arguments | Optional: "apply" to write changes (default is read-only) |
| What It Does | Manages Drift schema version bumps. Default mode is safe/read-only (shows scaffold). "apply" mode writes migration code and runs build_runner. |
| Commands | `dart run build_runner build --delete-conflicting-outputs` (only in apply mode) |

#### /schema-parity

| Field | Value |
|-------|-------|
| Arguments | None |
| What It Does | Read-only comparison of Drift (Flutter) and Drizzle (server) schemas with structured diff report |
| Output | Matched tables, column mismatches, server-only tables, local-only tables, type mapping validation |

---

### 5.3 Workflow Skills

#### /session-handoff

| Field | Value |
|-------|-------|
| Arguments | Optional: additional context string |
| What It Does | Updates CONTINUE_PROMPT.md with current session progress, completed work, next steps, files changed, blockers, test status |
| Integration | quality-gate hook blocks session end if this doc not updated |

#### /tdd

| Field | Value |
|-------|-------|
| Arguments | Required: `<feature> <layer>` (e.g., `auth domain`, `scoring all`, `teams data`) |
| What It Does | Guides through strict Red-Green-Refactor cycle with context isolation (don't read implementation during RED phase) |
| Key Rule | During RED phase, write tests against interfaces/specs only, not against existing implementation |

#### /commit-draft

| Field | Value |
|-------|-------|
| Arguments | None |
| What It Does | Analyzes staged changes, drafts conventional commit message. Does NOT commit — only drafts for review. |
| Checks | Verifies tests were run, analyzes diff for type/scope, checks recent commit style |

#### /issue-create

| Field | Value |
|-------|-------|
| Arguments | Required: phase number (e.g., "1", "2", "3") |
| What It Does | Creates GitHub Issues for all screens/features in a phase with full acceptance criteria, technical notes, and TDD/agent checklists |
| Commands | `gh issue list` (check existing) + `gh issue create` (create new) |

#### /phase-gate

| Field | Value |
|-------|-------|
| Arguments | Required: phase number |
| What It Does | Verifies 6 exit criteria: issues closed, tests pass, screenshots compared, CI green, code quality clean, coverage meets threshold |
| Commands | `gh issue list` + `flutter test` + `bun test` + `gh run list` + `flutter analyze` + `bunx tsc --noEmit` |

#### /debug-log

| Field | Value |
|-------|-------|
| Arguments | Required: issue name (e.g., "undo-strike-swap") |
| What It Does | Creates/updates `docs/debug/<issue-name>.md` with iteration tracking table (hypothesis, fix, result, finding). Adds escalation reminders at iterations 4, 6, 8, 10. |

---

### 5.4 Verification Skills

#### /screenshot-verify

| Field | Value |
|-------|-------|
| Arguments | Required: screen number (e.g., "12" for scoring) |
| What It Does | Screenshots wireframe (via Playwright) and running Flutter app, compares against 6 criteria (layout, components, spacing, M3 theme, content, touch targets) |
| Commands | `python -m http.server 9123` + `flutter screenshot` |

#### cricket-domain

| Field | Value |
|-------|-------|
| Arguments | None (reference skill) |
| Auto-loaded | Yes (no disable-model-invocation flag) |
| Contents | Full cricket rules: 10-step delivery pipeline, 7 strike rotation scenarios, 12 dismissal types, extras table, maiden/innings rules, undo logic, MVP algorithm |

---

## 6. Settings & Permissions

### Allow Rules Strategy (47 Rules)

CricScores uses a whitelist approach: only explicitly allowed commands can run without user confirmation. Rules are organized by category:

```
Flutter Development (12 rules)
  flutter test, build_runner, flutter analyze, dart format,
  flutter run, flutter pub (add/get/remove), flutter clean,
  flutter build, flutter create, flutter screenshot

Server Development (7 rules)
  bun test, drizzle-kit, bun install, bun add, bun remove,
  bun run, bun init

Code Formatting (2 rules)
  npx prettier, cd apps/server && npx prettier

Git Operations (12 rules)
  git status, log, diff, add, commit, push, pull, fetch,
  checkout, switch, branch, merge, stash, tag

GitHub CLI (4 rules)
  gh issue, gh pr, gh repo, gh api

File System (5 rules)
  ls, dir, tree, pwd, mkdir

Other (5 rules)
  python -m http.server, adb, node scripts, npx prettier
```

**Design principle:** Allow rules use wildcard matching (`*` suffix) so `Bash(cd apps/mobile && flutter test:*)` matches any test command variation. This reduces rule count while covering all legitimate uses.

### Deny Rules Strategy (11 Rules)

Deny rules override allow rules. They block operations that should never happen:

```
Protected Files (3 rules)
  Edit(CLAUDE.md)         # Core project instructions — block editing
  Write(CLAUDE.md)        # Core project instructions — block overwriting
  Edit(.claude/rules.md)  # File placement rules — protected

Destructive Git (6 rules)
  git push --force / -f   # Can destroy remote history
  git reset --hard        # Discards all uncommitted changes
  git clean -f / -fd      # Permanently deletes untracked files
  git branch -D           # Force-deletes branch
  git checkout .          # Discards all working tree changes
  *--no-verify*           # Skips pre-commit hooks

Destructive File (2 rules)
  rm -rf / rm -fr         # Recursive force delete
```

**Defense in depth:** Deny rules in settings.json are the first line of defense. The `guard-bash-commands` hook is the second line (catches patterns that deny rules might miss due to argument variations). The `protect-sensitive-files` hook is the third line (blocks sensitive file writes that deny rules don't cover).

### Protected Files Pattern

Some files are too important to modify accidentally:

| File | Protection Layer 1 (Deny Rule) | Protection Layer 2 (Hook) | Protection Layer 3 |
|------|-------------------------------|--------------------------|-------------------|
| `CLAUDE.md` | `Edit(CLAUDE.md)` + `Write(CLAUDE.md)` deny rules | — | Git review on commit |
| `.claude/rules.md` | `Edit(.claude/rules.md)` deny rule | — | Git review on commit |
| `.env` files | — | `protect-sensitive-files` hook | `.gitignore` entry |
| `*.key`, `*.pem` | — | `protect-sensitive-files` hook | `.gitignore` entry |

### Annotated Settings Template

```json
{
  "permissions": {
    "allow": [
      // --- Test & Build ---
      "Bash(cd apps/mobile && flutter test:*)",     // Run any Flutter test
      "Bash(cd apps/mobile && dart run build_runner:*)", // Code generation
      "Bash(cd apps/mobile && flutter analyze:*)",  // Static analysis
      "Bash(cd apps/server && bun test:*)",          // Run server tests
      "Bash(cd apps/server && bunx drizzle-kit:*)",  // DB migrations

      // --- Package Management ---
      "Bash(cd apps/mobile && flutter pub add:*)",   // Add Flutter packages
      "Bash(cd apps/mobile && flutter pub get:*)",   // Install Flutter deps
      "Bash(cd apps/server && bun install:*)",       // Install server deps
      "Bash(cd apps/server && bun add:*)",           // Add server packages

      // --- Git (read-only + standard operations) ---
      "Bash(git status:*)",
      "Bash(git log:*)",
      "Bash(git diff:*)",
      "Bash(git add:*)",
      "Bash(git commit:*)",
      "Bash(git push:*)",

      // --- GitHub CLI ---
      "Bash(gh issue:*)",
      "Bash(gh pr:*)",

      // --- Formatting ---
      "Bash(npx prettier:*)",

      // --- File System ---
      "Bash(mkdir:*)"
    ],
    "deny": [
      // --- Protected files (NEVER modify) ---
      "Edit(CLAUDE.md)",
      "Write(CLAUDE.md)",
      "Edit(.claude/rules.md)",

      // --- Destructive git (NEVER without explicit user request) ---
      "Bash(git push --force:*)",
      "Bash(git push -f:*)",
      "Bash(git reset --hard:*)",
      "Bash(git clean -f:*)",
      "Bash(git branch -D:*)",
      "Bash(git checkout .:*)",
      "Bash(*--no-verify:*)",

      // --- Destructive file operations ---
      "Bash(rm -rf:*)",
      "Bash(rm -fr:*)"
    ]
  },
  "hooks": {
    // See Section 3 for full hook configuration
  }
}
```

---

## 7. CI/CD Pipeline

### 5-Job Architecture

CricScores uses GitHub Actions with a self-hosted Windows runner. The pipeline has 5 jobs organized in 2 dependency chains plus 1 standalone job:

```
                    push/PR to main|develop
                           |
              +------------+------------+
              |            |            |
              v            v            v
     structure-validate  flutter-analyze  server-lint
              |            |            |
              |            v            v
              |      flutter-test   server-test
              |            |            |
              +------------+------------+
                           |
                       All passed
```

| Job | Depends On | Runs When | What It Does |
|-----|-----------|-----------|-------------|
| **structure-validate** | — | Always | Runs `flutter-validator.js` + `server-validator.js` to enforce folder placement |
| **flutter-analyze** | — | `hashFiles('apps/mobile/pubspec.yaml') != ''` | `flutter pub get` + `build_runner build` + `flutter analyze` |
| **flutter-test** | flutter-analyze | Same condition | `flutter pub get` + `build_runner build` + `flutter test` |
| **server-lint** | — | `hashFiles('apps/server/package.json') != ''` | `bun install` + `bunx tsc --noEmit` |
| **server-test** | server-lint | Same condition | `bun install` + `bun test` (with test DB env vars) |

### Hook-CI Parity Pattern

**Key design principle:** The same validation rules run both locally (via hooks) and in CI (via validation scripts). This ensures violations are caught early and never reach the repository.

| Validation | Local (Hook) | CI (Script) |
|-----------|-------------|------------|
| File placement | `validate-file-placement.ps1` | `flutter-validator.js` + `server-validator.js` |
| Cross-feature imports | `guard-cross-feature-imports.ps1` | `flutter-validator.js` (rule 4) |
| Naming conventions | `validate-file-placement.ps1` | Both validators (snake_case/kebab-case checks) |
| Auto-format | `auto-format.ps1` | N/A (assumed formatted before push) |
| Sensitive files | `protect-sensitive-files.ps1` | `.gitignore` entries |

**Why duplicate?** Hooks protect during development with Claude Code. CI protects when code is pushed by other tools or contributors. Together they form a safety net.

### Validation Script Architecture

Both validators follow the same pattern:

```
1. DEFINE violation severity levels (critical, high, medium, low)
2. SCAN directory tree for files matching extension
3. FOR EACH rule:
     CHECK condition against file path or content
     IF violated: addViolation(severity, file, message)
4. GROUP violations by severity
5. IF any violations: print report + exit 1
   ELSE: "All checks passed" + exit 0
```

**Flutter validator (6 rules):**
1. No files directly in `lib/` except `main.dart` (critical)
2. `snake_case.dart` naming (low)
3. No widget classes in `core/` (high)
4. No cross-feature `data/` or `domain/` imports (high)
5. Feature modules have required subdirectories (medium)
6. `providers.dart` exists in each feature (medium)

**Server validator (6 rules):**
1. Services must have `.service.ts` suffix (medium)
2. No route imports in service files (critical — enforces dependency direction)
3. `kebab-case.ts` naming (low)
4. Only expected directories in `src/` (medium)
5. No files in `src/` root except `index.ts` (medium)
6. Route files use kebab-case (low)

### Conditional Execution

Jobs only run when their respective directories have files:

```yaml
if: hashFiles('apps/mobile/pubspec.yaml') != ''  # Flutter jobs
if: hashFiles('apps/server/package.json') != ''   # Server jobs
```

This prevents CI failures in early project phases when one app directory might not exist yet.

---

## 8. Code Generation Workflow

### Flutter build_runner

CricScores uses three code generators that produce `.g.dart`, `.freezed.dart`, and `.gr.dart` files:

| Generator | Output | Trigger |
|-----------|--------|---------|
| **Freezed** | `*.freezed.dart` | Modifying `@freezed` annotated classes |
| **Drift** | `*.g.dart` | Modifying Drift table definitions or DAOs |
| **Riverpod Generator** | `*.g.dart` | Modifying `@riverpod` annotated providers |

**Command:**
```bash
cd apps/mobile && dart run build_runner build --delete-conflicting-outputs
```

**Hook integration:**
- `auto-format` hook **skips** generated files (matches `*.g.dart`, `*.freezed.dart`, `*.gr.dart`)
- `validate-file-placement` hook **skips** generated files
- Flutter validator in CI **skips** generated files for naming checks

**Rule:** Never edit generated files manually. Always modify the source and re-run `build_runner`.

### Server Drizzle Kit

Drizzle Kit generates SQL migration files from schema changes:

```bash
cd apps/server && bunx drizzle-kit generate  # Generate migration SQL
cd apps/server && bunx drizzle-kit migrate   # Apply migration
```

**Hook integration:** `remind-schema-parity` hook fires when Drizzle schema files are modified, reminding to generate migrations and check Drift parity.

### Generated File Safety

The automation stack ensures generated files are never accidentally edited or mis-formatted:

```
Write *.g.dart → validate-file-placement hook SKIPs
                → auto-format hook SKIPs
                → flutter-validator.js SKIPs

Write *.ts schema → remind-schema-parity hook REMINDS
                   → auto-format formats with prettier
```

---

## 9. TDD Workflow Automation

### Red-Green-Refactor Cycle

CricScores enforces strict TDD per architectural layer, building from the inside out:

```
  DOMAIN LAYER          DATA LAYER          PRESENTATION LAYER
  +-----------+         +-----------+       +-----------+
  |  1. RED   |         |  3. RED   |       |  5. RED   |
  | Write     |         | Write     |       | Write     |
  | domain    |    -->  | data      |  -->  | widget +  |
  | tests     |         | tests     |       | notifier  |
  +-----------+         +-----------+       | tests     |
  |  2. GREEN |         |  4. GREEN |       +-----------+
  | Implement |         | Implement |       |  6. GREEN |
  | entities  |         | datasrc + |       | Implement |
  | + refactor|         | repos +   |       | UI +      |
  +-----------+         | refactor  |       | notifiers |
                        +-----------+       | + refactor|
                                            +-----------+
```

### PLAYBOOK Step Mapping

| PLAYBOOK Step | TDD Phase | What Happens |
|--------------|-----------|-------------|
| Step 3 | RED (domain) | Write failing domain entity tests |
| Step 4 | GREEN+REFACTOR (domain) | Implement entities to pass tests, refactor |
| Step 5 | RED (data) | Write failing repository/datasource tests |
| Step 6 | GREEN+REFACTOR (data) | Implement data layer to pass tests, refactor |
| Step 7 | RED (presentation) | Write failing notifier/widget tests |
| Step 8 | GREEN+REFACTOR (presentation) | Implement UI to pass tests, refactor |

### Context Isolation Rule

**During RED phase:** Write tests against interfaces and specs only. Do NOT read existing implementation code. This ensures tests verify behavior, not implementation details.

**During GREEN phase:** Read existing code freely. Implement the minimum code needed to make tests pass.

### /tdd Skill Integration

The `/tdd <feature> <layer>` skill guides through the TDD cycle with strict enforcement:

```
/tdd scoring domain     → Guides through domain entity RED-GREEN-REFACTOR
/tdd scoring data       → Guides through data layer RED-GREEN-REFACTOR
/tdd scoring all        → Guides through all three layers in sequence
```

### TDD Exit Criteria

Phase gate checklists require "TDD coverage verified":
- Domain tests written BEFORE domain implementation
- Data tests written BEFORE data implementation
- Presentation tests written BEFORE presentation implementation

### TDD Exceptions

Not everything needs TDD:
- Generated code (`*.g.dart`, `*.freezed.dart`)
- Static UI (simple layout without logic)
- Config files
- Third-party wrappers (use `/screenshot-verify` for visual verification instead)

---

## 10. Session Management

### Session Lifecycle

```
SESSION START
  |
  v
load-session-context hook fires
  (shows "What to Do Next" from CONTINUE_PROMPT.md)
  |
  v
Agent reads full CONTINUE_PROMPT.md
  (current phase, last issue, test status, next steps)
  |
  v
WORK PHASE
  |
  +--[Context compaction occurs]---> reinject-after-compaction hook fires
  |                                  (re-injects critical rules + git state)
  |
  v
SESSION END
  |
  v
quality-gate hook fires
  |
  +--[Source files changed but CONTINUE_PROMPT.md not updated]
  |     BLOCK: "Update session handoff doc"
  |     --> /session-handoff skill updates doc
  |     --> quality-gate re-checks --> PASS
  |
  +--[Uncommitted source changes]
  |     BLOCK: "Uncommitted source changes in apps/"
  |     --> git commit --> quality-gate re-checks --> PASS
  |
  +--[No source changes OR doc updated]
        PASS: Session ends normally
```

### CONTINUE_PROMPT.md Pattern

The handoff document serves as the "save state" between sessions. Required sections:

```markdown
## Current State
- Phase and issue number
- Branch name and last commit
- Test status (pass count, any failures)

## Completed This Session
- Features/issues completed
- Files created/modified
- Key decisions made

## What to Do Next
- Specific next steps (numbered)
- Current blockers
- Pending items

## Test Status
- Flutter test count and pass rate
- Server test count and pass rate
- Any known failing tests

## Key Decisions
- Architectural choices made
- Trade-offs accepted
- Questions resolved
```

**Enforcement:** The `quality-gate` hook blocks session end if this file wasn't updated when source files changed. The `load-session-context` hook reads "What to Do Next" at the start of every session. The `reinject-after-compaction` hook extracts phase, screen, and checklist status after compaction.

### /session-handoff Skill

The `/session-handoff` skill automates the CONTINUE_PROMPT.md update:
1. Reads current CONTINUE_PROMPT.md
2. Reads IMPLEMENTATION_PLAN.md for phase context
3. Analyzes git state (changed files, current branch)
4. Updates all sections with current session data
5. Ensures smooth handoff to next session

---

## 11. Debugging Workflow

### 8-Step Root Cause Analysis

From `CODE_FIXES.md`:

1. **Reproduce** — Write a failing test that reproduces the exact issue
2. **Read the error** — Understand the full error message and stack trace
3. **Identify the layer** — Which layer is the root cause? (domain/data/presentation/server)
4. **Read the source** — Read the relevant source files fully, not just the error location
5. **Form hypothesis** — What do you think causes the issue? Write it down.
6. **Write regression test** — Ensure the fix is verified by an automated test
7. **Run full test suite** — Verify no regressions in the affected feature
8. **Screenshot verify** — If UI is affected, take a screenshot and compare

### Escalation Tiers

When a fix doesn't work, escalation tiers control how the debugging approach changes:

```
Iteration 1-3: NORMAL
  - Re-read failure output
  - Try a different approach
  - Check adjacent code

Iteration 4-5: TIER 1
  - Slow down
  - Challenge your assumptions
  - Re-read the spec/rules doc

Iteration 6-7: TIER 2
  - Invoke `debugger` agent
  - Widen scope beyond the immediate error
  - Trace the full execution path

Iteration 8-9: TIER 3
  - Audit the architecture
  - Consider if the design is wrong, not just the code
  - Check for environmental issues

Iteration 10: HARD CAP
  - STOP attempting fixes
  - Present structured findings to the user:
    - What was tried (all 10 iterations)
    - What was learned
    - Best hypothesis
    - Suggested next steps
```

### Debug Log Pattern

The `/debug-log <issue-name>` skill creates a structured tracking file:

```markdown
# Debug: <issue-name>

| Iter | Hypothesis | Fix Attempted | Result | Finding |
|------|-----------|--------------|--------|---------|
| 1 | Strike not rotating on wide+1 | Added wide run check to rotateStrike() | FAIL | Wide runs were being counted but not triggering swap |
| 2 | Wide run total not including additional runs | Fixed total_runs calculation | PASS | Root cause was off-by-one in extras sum |
```

**Escalation reminders** are automatically added at iterations 4, 6, 8, and 10.

### Debugger Agent Invocation

At Tier 2 (iteration 6-7), the `debugger` agent is invoked:

```
Task(debugger, "Investigate: <issue description>
  Iterations so far: <summary of 5 failed attempts>
  Hypothesis: <current best guess>
  Affected files: <list>")
```

The debugger agent:
1. Reads accumulated knowledge from `.claude/agents/memory/debugger.md`
2. Systematically investigates the issue
3. Returns findings with evidence
4. Appends new insights to its memory file

---

## 12. Integration Patterns

### Hook + Agent Integration

**Pattern: Hook reminds, agent gathers, human decides**

```
1. remind-schema-parity hook fires
     "SCHEMA MODIFIED: Run /schema-parity to check Drift/Drizzle alignment"

2. Main agent invokes /schema-parity skill
     Skill compares Drift and Drizzle schemas

3. If mismatches found, main agent invokes database-researcher agent
     Agent analyzes the full schema context and migration implications

4. Main agent presents findings to user
     User decides whether to add the missing columns now or later
```

### Hook + CI Mirroring

**Pattern: Same rules enforced locally and remotely**

```
LOCAL (during development):
  Write file → validate-file-placement hook → BLOCK if wrong location
  Write file → guard-cross-feature-imports hook → BLOCK if bad import

REMOTE (on push/PR):
  CI job → flutter-validator.js → FAIL if wrong location
  CI job → flutter-validator.js → FAIL if bad import

Both enforce the SAME rules from .claude/rules.md, just at different points.
```

### Skill + Hook Integration

**Pattern: Skill writes, hook validates and formats**

```
1. /tdd scoring domain skill guides main agent to write test file
2. Write tool is called with test file content
3. validate-file-placement hook checks file is in correct test directory
4. protect-sensitive-files hook verifies no credentials in test
5. File is written
6. auto-format hook formats the .dart file with dart format
```

### Full Workflow Example: Feature Implementation

The complete PLAYBOOK (17 steps) shows all automations working together:

```
Step 1: Read GitHub Issue
  → Load acceptance criteria and technical notes

Step 2: Pre-Implementation Research (PARALLEL AGENTS)
  → cricheroes-comparator (always)
  → ui-researcher (always for UI features)
  → scoring-researcher (if scoring feature)
  → database-researcher (if schema changes)
  → api-researcher (if new endpoints)
  → planner-researcher (if complex)
  → system-architect (if architectural decisions)

Step 3: RED — Write Domain Tests (/tdd <feature> domain)
  → Write failing tests
  → flutter test → CONFIRM RED (tests fail)

Step 4: GREEN — Implement Domain
  → Write minimum code to pass tests
  → auto-format hook formats code
  → validate-file-placement hook checks paths
  → flutter test → CONFIRM GREEN (tests pass)

Steps 5-8: Repeat RED/GREEN for data and presentation layers
  → guard-cross-feature-imports hook prevents bad imports
  → protect-sensitive-files hook prevents credential exposure
  → auto-format hook formats every file written

Step 9: Build Check (/build-check)
  → build_runner regenerates all code
  → flutter analyze checks for lint issues

Step 10: Wireframe Comparison (/screenshot-verify XX)
  → Playwright screenshots wireframe + Flutter app
  → 6-criteria comparison

Step 11: Post-Implementation Review (3 STAGES)
  Stage 1: code-reviewer + tester agents (parallel)
  Stage 2: Domain-specific agents (scoring-researcher, database-researcher)
  Stage 3: reviewer agent → PASS / WARN / BLOCK verdict

Step 12: Fix Loop (if BLOCK)
  → Fix issues → re-run Stage 3
  → Escalation tiers: debugger agent at Tier 2
  → /debug-log skill tracks iterations

Step 13: Final Screenshots
  → /screenshot-verify after fixes

Step 14: Commit (/commit-draft)
  → git-manager agent reviews git practices
  → /commit-draft skill drafts conventional commit message
  → git commit with co-author attribution

Step 15: CI Verification
  → Push → GitHub Actions runs 5 jobs
  → structure-validate mirrors hook checks
  → flutter-test runs full suite
  → server-test runs full suite

Step 16: Session Handoff (/session-handoff)
  → Update CONTINUE_PROMPT.md
  → quality-gate hook verifies update

Step 17: Phase Gate (/phase-gate N)
  → 6 exit criteria verified
  → Issues closed, tests pass, screenshots match, CI green, coverage met
```

---

## 13. Customization Guide

### Adapting for Different Tech Stacks

The automation patterns are stack-agnostic. Here's how to adapt each component:

#### Hooks

| CricScores (Flutter + Bun) | React + Node | Python + FastAPI |
|-------------------------|-------------|-----------------|
| `dart format` | `prettier --write` | `black` or `ruff format` |
| `npx prettier` (TS) | `eslint --fix` | `ruff check --fix` |
| `flutter analyze` | `tsc --noEmit` + `eslint` | `mypy` + `ruff` |
| `flutter test` | `jest` or `vitest` | `pytest` |
| `build_runner` | N/A (or `codegen`) | N/A (or `pydantic`) |
| `*.g.dart` skip | `*.generated.ts` skip | N/A |
| `snake_case.dart` | `PascalCase.tsx` / `camelCase.ts` | `snake_case.py` |
| `drizzle-kit generate` | `prisma migrate dev` | `alembic revision --autogenerate` |

#### File Placement Rules

Replace CricScores's clean architecture rules with your project's structure:

```
CricScores:                    React Example:
  features/<name>/            features/<name>/
    data/datasources/           api/          (API calls)
    data/models/                hooks/        (React hooks)
    data/repositories/          components/   (UI components)
    domain/entities/            types/        (TypeScript types)
    domain/repositories/        store/        (Zustand/Redux)
    presentation/notifiers/     utils/        (helpers)
    presentation/pages/         pages/        (Next.js pages)
    presentation/widgets/       __tests__/    (co-located tests)
    providers.dart              index.ts      (barrel export)
```

#### Shell Language

CricScores hooks use PowerShell (Windows Server). Adapt for your platform:

| Pattern | PowerShell | Bash |
|---------|-----------|------|
| Read stdin | `[Console]::In.ReadToEnd()` | `cat -` or `read -r input` |
| Parse JSON | `ConvertFrom-Json` | `jq` |
| Regex match | `-match 'pattern'` | `[[ "$var" =~ pattern ]]` |
| Write stderr | `[Console]::Error.WriteLine()` | `echo "msg" >&2` |
| Exit block | `exit 2` | `exit 2` |
| Exit allow | `exit 0` | `exit 0` |

### Adapting Agents for Non-Cricket Domains

Replace the domain-specific agents with your domain:

| CricScores Agent | Generic Equivalent | E-commerce Example |
|--------------|-------------------|-------------------|
| scoring-researcher | domain-researcher | payment-researcher |
| cricket-domain skill | domain-rules skill | commerce-rules skill |
| cricheroes-comparator | competitor-comparator | shopify-comparator |
| system-architect | system-architect (keep as-is, update evaluation lens) | system-architect (change from "offline-first cricket" to "high-availability commerce") |

**Key adaptation points in agent prompts:**
1. Replace "First Steps" pre-reads with your domain docs
2. Replace "Research Focus Areas" with your domain concerns
3. Replace "Key Implementation Files" with your file paths
4. Keep the "Output Format" structure (it's domain-agnostic)

### 4-Week Migration Checklist

**Week 1: Foundation**
- [ ] Create `.claude/` directory structure (settings.json, rules.md, hooks/, agents/, skills/)
- [ ] Install Tier 1 hooks (protect-sensitive-files, quality-gate, auto-format, guard-bash-commands, load-session-context)
- [ ] Configure settings.json allow/deny rules for your tech stack
- [ ] Create CONTINUE_PROMPT.md template
- [ ] Write rules.md with your project's file placement rules

**Week 2: Enforcement**
- [ ] Install Tier 2 hooks (validate-file-placement, guard-cross-feature-imports)
- [ ] Create CI validation scripts mirroring hook rules
- [ ] Set up research agents (planner-researcher, code-reviewer, tester)
- [ ] Create session-handoff skill
- [ ] Create build-check and test skills for your stack

**Week 3: Domain**
- [ ] Create domain-specific research agents
- [ ] Create domain rules reference skill
- [ ] Set up competitor comparator agent (if applicable)
- [ ] Install schema parity hook (if dual-database project)
- [ ] Create TDD skill adapted to your architecture

**Week 4: Polish**
- [ ] Create phase-gate skill with your exit criteria
- [ ] Create issue-create skill with your templates
- [ ] Create debug-log skill
- [ ] Set up reinject-after-compaction hook with your critical rules
- [ ] Write accumulated knowledge seed files for agents
- [ ] Test full workflow end-to-end

### Anti-Patterns to Avoid

| Anti-Pattern | Why It Fails | Better Approach |
|-------------|-------------|----------------|
| **Too many blocking hooks** | Agent gets stuck, user loses patience | Start with 4-5 blocking hooks, add more only when violations actually occur |
| **Agents that write code** | Conflicts with main agent, inconsistent style | Agents gather context and return findings; only the main agent writes code |
| **Auto-invoking skills** | Skills inject large prompts that clutter context | Use `disable-model-invocation: true`; let user invoke explicitly |
| **Monolithic hook scripts** | Hard to debug, one failure blocks everything | One hook per concern; each hook has a single responsibility |
| **Duplicating CLAUDE.md in hooks** | Rules drift apart, confusing behavior | Hooks reference rules.md; CLAUDE.md is the single source of truth |
| **No memory accumulation** | Agents repeat the same analysis mistakes | Give key agents memory files; they improve over time |
| **Skipping CI mirroring** | Hook violations slip through non-Claude commits | CI scripts mirror the same rules hooks enforce locally |
| **Over-prescriptive reinject hook** | Too much text after compaction overwhelms context | Keep reinject content to ~30 lines of the most critical rules |

---

## Appendix A: Complete File Inventory

### Hooks (11 files, 10 active)

| File | Lines | Event | Blocks? | Status |
|------|-------|-------|---------|--------|
| `.claude/hooks/validate-file-placement.ps1` | 153 | PreToolUse (Edit\|Write) | Yes | Active |
| `.claude/hooks/protect-sensitive-files.ps1` | 58 | PreToolUse (Edit\|Write) | Yes | Active |
| `.claude/hooks/guard-cross-feature-imports.ps1` | 49 | PreToolUse (Write) | Yes | Active |
| `.claude/hooks/guard-bash-commands.ps1` | 39 | PreToolUse (Bash) | Yes | Active |
| `.claude/hooks/auto-invoke-cricheroes-comparator.ps1` | 24 | PreToolUse (Write) | No | Active |
| `.claude/hooks/load-session-context.ps1` | 24 | SessionStart (startup\|resume) | No | Active |
| `.claude/hooks/reinject-after-compaction.ps1` | 115 | SessionStart (compact) | No | Active |
| `.claude/hooks/auto-format.ps1` | 58 | PostToolUse (Edit\|Write) | No | Active |
| `.claude/hooks/remind-schema-parity.ps1` | 42 | PostToolUse (Edit\|Write) | No | Active |
| `.claude/hooks/quality-gate.ps1` | 74 | Stop | Yes | Active |
| `.claude/hooks/remind-session-handoff.ps1` | 42 | Stop | Yes | Deprecated (replaced by quality-gate) |

### Agents (14 files)

| File | Model | Category | Has Memory? |
|------|-------|----------|------------|
| `.claude/agents/scoring-researcher.md` | inherit | Research | Yes |
| `.claude/agents/database-researcher.md` | sonnet | Research | Yes |
| `.claude/agents/ui-researcher.md` | haiku | Research | No |
| `.claude/agents/api-researcher.md` | sonnet | Research | No |
| `.claude/agents/planner-researcher.md` | sonnet | Research | No |
| `.claude/agents/cricheroes-comparator.md` | sonnet | Research | No |
| `.claude/agents/code-reviewer.md` | sonnet | Review | Yes |
| `.claude/agents/tester.md` | sonnet | Review | No |
| `.claude/agents/reviewer.md` | inherit | Review | Yes |
| `.claude/agents/system-architect.md` | inherit | Review | Yes |
| `.claude/agents/debugger.md` | inherit | Review | Yes |
| `.claude/agents/docs-manager.md` | haiku | Management | No |
| `.claude/agents/git-manager.md` | haiku | Management | No |
| `.claude/agents/database-admin.md` | sonnet | Management | No |

### Skills (16 files)

| Skill | Category | Arguments | Auto-invocable? |
|-------|----------|-----------|----------------|
| `/score-test` | Test & Build | Optional: test file path | No |
| `/server-test` | Test & Build | Optional: test file path | No |
| `/sync-test` | Test & Build | Optional: "server" or "mobile" | No |
| `/build-check` | Test & Build | None | No |
| `/analyze` | Test & Build | None | No |
| `/db-migrate` | Database | None | No |
| `/drift-migrate` | Database | Optional: "apply" | No |
| `/schema-parity` | Database | None | No |
| `/session-handoff` | Workflow | Optional: context string | No |
| `/tdd` | Workflow | Required: `<feature> <layer>` | No |
| `/commit-draft` | Workflow | None | No |
| `/issue-create` | Workflow | Required: phase number | No |
| `/phase-gate` | Workflow | Required: phase number | No |
| `/debug-log` | Workflow | Required: issue name | No |
| `/screenshot-verify` | Verification | Required: screen number | No |
| `cricket-domain` | Verification | None (reference) | Yes |

### Settings Summary

| Category | Count |
|----------|-------|
| Allow rules | 47 |
| Deny rules | 11 |
| PreToolUse hooks | 5 (across 3 matchers) |
| SessionStart hooks | 2 (across 2 matchers) |
| PostToolUse hooks | 2 (across 1 matcher) |
| Stop hooks | 1 |
| **Total hook config entries** | **10** |

### CI Jobs

| Job | Dependencies | Conditional |
|-----|-------------|-------------|
| structure-validate | None | Always |
| flutter-analyze | None | `hashFiles('apps/mobile/pubspec.yaml')` |
| flutter-test | flutter-analyze | `hashFiles('apps/mobile/pubspec.yaml')` |
| server-lint | None | `hashFiles('apps/server/package.json')` |
| server-test | server-lint | `hashFiles('apps/server/package.json')` |
