---
name: session-handoff
description: Update docs/CONTINUE_PROMPT.md with current session progress, completed work, and next steps for seamless session resumption.
disable-model-invocation: true
allowed-tools: Read, Edit, Write
---

# Session Handoff

Update the session continuation document for seamless handoff.

## Steps

1. Read the current `docs/CONTINUE_PROMPT.md`.

2. Read `docs/planning/IMPLEMENTATION_PLAN.md` to understand which phase we're in.

3. Update `docs/CONTINUE_PROMPT.md` with:

   - **Session Summary**: One paragraph describing what was accomplished this session
   - **Completed Work**: List of features, files, or tasks completed
   - **What to Do Next**: Specific next steps, ordered by priority
   - **Current Phase**: Which implementation phase we're in and progress within it
   - **Files Changed**: Key files created or modified this session
   - **Blockers/Decisions**: Any unresolved issues or pending decisions
   - **Test Status**: Which tests pass, which are failing, any known issues

4. Keep the document concise but complete enough for a fresh session to resume without context loss.

5. If `$ARGUMENTS` is provided, include it as additional context in the session summary.
