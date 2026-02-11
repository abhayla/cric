# Hook: Session Handoff Reminder
# Event: Stop
# Checks if CONTINUE_PROMPT.md has uncommitted changes; blocks if not updated

$repoRoot = Join-Path $PSScriptRoot "..\.."

# Skip if not a git repo
if (-not (Test-Path (Join-Path $repoRoot ".git"))) {
    exit 0
}

# Check if any source files were changed in this session
# (by checking git status for tracked/untracked changes in apps/ or scripts/)
$gitStatus = & git -C $repoRoot status --porcelain 2>$null
if (-not $gitStatus) {
    # No changes at all - pure research session, skip check
    exit 0
}

$hasSourceChanges = $false
foreach ($line in $gitStatus -split "`n") {
    if ($line -match 'apps/|scripts/|\.claude/(hooks|skills)') {
        $hasSourceChanges = $true
        break
    }
}

if (-not $hasSourceChanges) {
    # No source file changes - pure doc/research session, skip check
    exit 0
}

# Check if CONTINUE_PROMPT.md has uncommitted changes (staged or unstaged)
$continuePromptDiff = & git -C $repoRoot diff -- "docs/CONTINUE_PROMPT.md" 2>$null
$continuePromptStaged = & git -C $repoRoot diff --cached -- "docs/CONTINUE_PROMPT.md" 2>$null

if (-not $continuePromptDiff -and -not $continuePromptStaged) {
    [Console]::Error.WriteLine("REMINDER: Update docs/CONTINUE_PROMPT.md before ending session. Source files were changed but session handoff doc was not updated. Use /session-handoff or update manually.")
    exit 2
}

exit 0
