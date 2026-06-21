#!/usr/bin/env bash
# ba-usecase-discovery-reminder.sh — UserPromptSubmit hook (matcher "").
#
# WHY: before building a new feature/screen/endpoint, the BA (business-analyst)
# discipline is to discover the USE CASE first — actors, the primary flow, the
# alternate/edge flows, and the acceptance signal — rather than jumping to UI or
# schema. This advisory reminder nudges that discovery step on substantive
# prompts, complementing plan-before-coding.md and design-ssot.md.
#
# CONTRACT:
#   Event: UserPromptSubmit   Matcher: ""   Exit codes: always 0 (non-blocking).
#   Input: JSON on stdin with .prompt. Output: stdout text is injected as context.
#
# NOTE (2026-06-22): reconstructed on the new dev PC — the hub-provisioned
# canonical body was referenced by the committed settings.json but its .sh file
# was never committed (so `git fetch` could not restore it). If the hub later
# provides a canonical version, it supersedes this file.
exec 2>/dev/null

# Non-blocking by design: any failure must not block the prompt.
command -v jq >/dev/null || exit 0

input=$(cat)
prompt=$(printf '%s' "$input" | jq -r '.prompt // ""')

# Skip trivial / continuation prompts — only nudge on substantive ones.
len=${#prompt}
[ "$len" -lt 40 ] && exit 0
case "$prompt" in
  /*|continue|go|yes|y|ok|next|proceed) exit 0 ;;
esac

# Fire only when the prompt looks like NEW build work (not a bugfix/question).
if printf '%s' "$prompt" | grep -qiE '\b(add|build|create|implement|new (feature|screen|page|endpoint|flow)|design)\b'; then
  echo "BA REMINDER: before building, discover the use case first — name the ACTORS, the PRIMARY flow, the ALTERNATE/edge flows, and the ACCEPTANCE signal (how you'll know it's done). Capture the decision in the canonical design doc (design-ssot.md) and produce a visible plan before the first edit (plan-before-coding.md)."
fi

exit 0
