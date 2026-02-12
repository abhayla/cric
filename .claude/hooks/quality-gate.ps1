# Hook: Quality Gate (Stop)
# Event: Stop
# Comprehensive session-end quality gate
# Checks: CONTINUE_PROMPT.md updated, uncommitted source changes warning
# Exit 2 to block stop, Exit 0 to allow

$repoRoot = Join-Path $PSScriptRoot "..\.."

# Skip if not a git repo
if (-not (Test-Path (Join-Path $repoRoot ".git"))) {
    exit 0
}

# Check if any source files were changed in this session
$gitStatus = & git -C $repoRoot status --porcelain 2>$null
if (-not $gitStatus) {
    # No changes at all — pure research session, skip all checks
    exit 0
}

$hasSourceChanges = $false
$modifiedFiles = @()
foreach ($line in $gitStatus -split "`n") {
    $trimmed = $line.Trim()
    if ($trimmed -match 'apps/|scripts/|\.claude/(hooks|skills)') {
        $hasSourceChanges = $true
        $modifiedFiles += $trimmed
    }
}

if (-not $hasSourceChanges) {
    # No source file changes — pure doc/config session, skip checks
    exit 0
}

$failures = @()

# --- Check 1: CONTINUE_PROMPT.md updated ---
$continuePromptDiff = & git -C $repoRoot diff -- "docs/CONTINUE_PROMPT.md" 2>$null
$continuePromptStaged = & git -C $repoRoot diff --cached -- "docs/CONTINUE_PROMPT.md" 2>$null

if (-not $continuePromptDiff -and -not $continuePromptStaged) {
    $failures += "CONTINUE_PROMPT.md not updated: Source files were changed but session handoff doc was not updated. Use /session-handoff or update manually."
}

# --- Check 2: Uncommitted source changes warning ---
$unstagedApps = @()
foreach ($line in $gitStatus -split "`n") {
    $trimmed = $line.Trim()
    # Check for modified but not staged files in apps/ (status starts with space + M, or ??)
    if ($trimmed -match '^(\?\?|.[MADRC])\s+apps/') {
        $unstagedApps += $trimmed
    }
}

if ($unstagedApps.Count -gt 0) {
    $fileList = ($unstagedApps | ForEach-Object { "  $_" }) -join "`n"
    $failures += "Uncommitted source changes in apps/:`n$fileList`nConsider staging and committing before ending the session."
}

# --- Output modified files list for context ---
if ($modifiedFiles.Count -gt 0) {
    $fileList = ($modifiedFiles | ForEach-Object { "  $_" }) -join "`n"
    [Console]::Error.WriteLine("Modified files this session:`n$fileList")
}

# --- Final result ---
if ($failures.Count -gt 0) {
    $failureMsg = $failures -join "`n`n"
    [Console]::Error.WriteLine("QUALITY GATE FAILED:`n$failureMsg")
    exit 2
}

exit 0
