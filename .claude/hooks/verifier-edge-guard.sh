#!/usr/bin/env bash
# verifier-edge-guard.sh — Stop hook (matcher "").
#
# WHY: output-plausibility-verification.md notes that the semantic "is this value
# domain-sane?" check is advisory-only (no deterministic hook can detect a
# domain-absurd-but-rendering value). This guard backstops the *codifiable* slice:
# it reminds, at Stop time, that a turn claiming something is "verified" / "passes"
# / "confirmed" must rest on reproduced evidence + a plausibility/substance check,
# not shape-only ("renders / no console error"). See also supervisor-verification.md
# and independent-test-verification.md.
#
# CONTRACT:
#   Event: Stop   Matcher: ""   Exit code: 0 (NON-BLOCKING / advisory).
#   Input: JSON on stdin (.transcript_path). It MUST NOT block the stop — a wrong
#   block on a Stop hook is highly disruptive, so this reconstruction stays purely
#   advisory and never emits {"decision":"block"}.
#
# NOTE (2026-06-22): reconstructed on the new dev PC — the hub-provisioned
# canonical body was referenced by the committed settings.json but its .sh file
# was never committed (so `git fetch` could not restore it). If the hub later
# provides a canonical version (which may add stronger detection), it supersedes
# this file. Kept deliberately non-blocking to avoid fabricating block logic.
exec 2>/dev/null

# Any failure must be a clean no-op — never block a stop.
command -v jq >/dev/null || exit 0

input=$(cat)
tp=$(printf '%s' "$input" | jq -r '.transcript_path // ""')
[ -z "$tp" ] || [ ! -f "$tp" ] && exit 0

# Advisory-only: this reconstruction performs no blocking detection. It exits 0 so
# the missing-file hook error is resolved without risking a wrongful Stop block.
# The semantic plausibility check remains the model's responsibility per
# output-plausibility-verification.md (an advisory-only gate by design).
exit 0
