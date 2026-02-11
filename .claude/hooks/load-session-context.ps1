# Hook: Session Start Context Loader
# Event: SessionStart (startup, resume)
# Reads CONTINUE_PROMPT.md and outputs the "What to Do Next" section

$continuePrompt = Join-Path $PSScriptRoot "..\..\docs\CONTINUE_PROMPT.md"

if (-not (Test-Path $continuePrompt)) {
    Write-Output "Note: docs/CONTINUE_PROMPT.md not found. Create it for session context."
    exit 0
}

$content = Get-Content $continuePrompt -Raw

# Extract "What to Do Next" section
if ($content -match '(?ms)## What to Do Next\s*\n(.*?)(?=\n## |\z)') {
    Write-Output "=== SESSION CONTEXT (from CONTINUE_PROMPT.md) ==="
    Write-Output ""
    Write-Output "WHAT TO DO NEXT:"
    Write-Output $Matches[1].Trim()
    Write-Output ""
    Write-Output "=== Read full context: docs/CONTINUE_PROMPT.md ==="
}

exit 0
