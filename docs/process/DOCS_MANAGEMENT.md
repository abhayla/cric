# Documentation Management

## Documentation Map

| File Path | Purpose | Update Frequency |
|-----------|---------|-----------------|
| `CLAUDE.md` | Claude Code project instructions, code principles, architecture | Rarely (protected) |
| `README.md` | Project overview, tech stack, doc links for external visitors | Per phase completion |
| `.claude/rules.md` | File placement rules, folder structure, naming conventions | Rarely (protected) |
| `docs/CONTINUE_PROMPT.md` | Session handoff context and next steps | Every session |
| `docs/planning/PDR.md` | Product requirements, user stories, success metrics | Per phase completion |
| `docs/planning/IMPLEMENTATION_PLAN.md` | Phased roadmap, architecture, packages | Per phase completion |
| `docs/planning/DATABASE.md` | 24 tables, 5 views, indexes, local SQLite schema | When schema changes |
| `docs/planning/API.md` | REST endpoints, WebSocket protocol | When API changes |
| `docs/planning/SCORING_RULES.md` | Match state machine, delivery pipeline, cricket rules | When rules change |
| `docs/planning/blueprint.html` | Interactive wireframes, architecture diagrams | Per phase completion |
| `docs/process/DOCS_MANAGEMENT.md` | This file — doc map and maintenance rules | When docs added/moved |
| `docs/process/CODE_STANDARDS.md` | Single reference for all coding conventions: naming, API design, state management, error handling, testing, performance, logging, linting, tooling | When conventions change |
| `docs/process/IMPLEMENTATION_PRACTICES.md` | Feature workflow, offline-first, state management, testing | When practices evolve |
| `docs/process/CODE_FIXES.md` | Debugging workflow, common issues, fix protocol | When patterns discovered |
| `docs/process/GITHUB_ISSUES.md` | Issue templates, labels, milestones, workflow | When process changes |
| `docs/process/CLAUDE_CODE_CONFIG.md` | Sub-agent specs, skill definitions | When agents/skills change |

## Folder Structure

```
docs/
├── planning/               # WHAT to build — product specs, architecture, schema
│   ├── PDR.md
│   ├── IMPLEMENTATION_PLAN.md
│   ├── DATABASE.md
│   ├── API.md
│   ├── SCORING_RULES.md
│   └── blueprint.html
├── process/                # HOW to build — workflows, standards, practices
│   ├── DOCS_MANAGEMENT.md
│   ├── CODE_STANDARDS.md
│   ├── IMPLEMENTATION_PRACTICES.md
│   ├── CODE_FIXES.md
│   ├── GITHUB_ISSUES.md
│   └── CLAUDE_CODE_CONFIG.md
└── CONTINUE_PROMPT.md      # Session handoff (root for quick access)
```

## Documentation Rules

1. **No duplication.** If information exists in another doc, cross-reference it with a relative link. Example: "See [SCORING_RULES.md](../planning/SCORING_RULES.md) Section 2 for the delivery pipeline."
2. **Every new doc must be added to the Documentation Map** in this file before it is considered complete.
3. **Use Markdown ATX headings** (`#`, `##`, `###`) — not setext (underline) style.
4. **Use relative paths** for all cross-references between docs (e.g., `../planning/DATABASE.md`).
5. **Tables over prose** for structured data (schemas, endpoints, feature lists).
6. **Code blocks with language hints** for all code snippets (e.g., ` ```dart`, ` ```typescript`).

## When to Create a New Doc vs Extend an Existing One

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

## Protected Files

The following files require explicit user approval before modification:

- `CLAUDE.md` — Project-wide instructions and code principles
- `.claude/rules.md` — File placement rules and folder structure

Changes to these files should be proposed with a clear rationale and specific diffs. Never weaken the YAGNI/KISS/DRY rules or the anti-patterns list without user consent.
