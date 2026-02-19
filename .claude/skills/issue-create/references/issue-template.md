# GitHub Issue Template

Use this template when creating issues for a phase.

## Command Format

```bash
gh issue create --title "<screen/feature name>" --milestone "Phase $ARGUMENTS" --label "type: feature" --label "P0: critical" --label "component: <area>" --body "$(cat <<'EOF'
## User Story
As a [role], I want to [action] so that [benefit].

## Acceptance Criteria

### Domain Layer
- [ ] Entity classes created
- [ ] Repository interface defined

### Data Layer
- [ ] Freezed models with JSON serialization
- [ ] Local datasource (Drift)
- [ ] Remote datasource (Dio)
- [ ] Repository implementation

### Presentation Layer
- [ ] Notifier with Freezed state
- [ ] Page widget
- [ ] Feature-specific widgets
- [ ] providers.dart declarations

### Tests
- [ ] Domain unit tests
- [ ] Repository unit tests (mocked datasources)
- [ ] Notifier unit tests (mocked repo)
- [ ] Widget tests

### Wireframe Comparison
- [ ] Screenshot matches wireframe (`/screenshot-verify XX`)

## Design Reference
Wireframe: `docs/ui/XX-name.html`

## Technical Notes
**Tables:** `table1`, `table2`
**Endpoints:** `GET /api/v1/...`, `POST /api/v1/...`
**Rules:** (if applicable)

## Agents to Invoke
- [ ] `cricheroes-comparator` (pre-implementation)
- [ ] `ui-researcher` (pre-implementation)
- [ ] `CricApp-code-reviewer` (post-implementation)
- [ ] `tester` (post-implementation)
EOF
)"
```
