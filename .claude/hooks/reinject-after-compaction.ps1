# Hook: Post-Compaction Context Re-injection
# Event: SessionStart (compact)
# After context compaction, outputs condensed critical rules + current session context + git state

Write-Output "=== CRITICAL RULES (re-injected after context compaction) ==="
Write-Output ""
Write-Output "FILE PLACEMENT - NEVER DO THESE:"
Write-Output "1. No files directly in lib/ except main.dart"
Write-Output "2. No widgets in core/ (use shared/widgets/ or feature widgets/)"
Write-Output "3. No models/ in domain/ (domain has entities/ only)"
Write-Output "4. No cross-feature data/ or domain/ imports"
Write-Output "5. Dart: snake_case.dart | TS: kebab-case.ts or dot.notation.ts"
Write-Output "6. Pages: _page.dart | Notifiers: _notifier.dart | Models: _model.dart"
Write-Output "7. Services: .service.ts suffix required"
Write-Output "8. No files in server src/ root except index.ts"
Write-Output "9. Drift tables only in shared/data/database/tables/"
Write-Output "10. Generated files (*.g.dart, *.freezed.dart, *.gr.dart) - never edit manually"
Write-Output ""
Write-Output "TDD WORKFLOW: Write tests FIRST (RED), implement (GREEN), refactor. 17-step playbook."
Write-Output ""
Write-Output "DELIVERY PIPELINE (10 steps):"
Write-Output "1.Validate -> 2.CalcRuns -> 3.HandleExtras -> 4.ProcessWicket ->"
Write-Output "5.RotateStrike -> 6.UpdateStats -> 7.CheckOver -> 8.CheckInnings ->"
Write-Output "9.Broadcast -> 10.Persist"
Write-Output ""
Write-Output "MATCH STATE MACHINE:"
Write-Output "SETUP -> TOSS -> LIVE -> INNINGS_BREAK -> LIVE -> COMPLETED (ABANDONED at any point)"
Write-Output ""
Write-Output "CRITICAL CRICKET RULES:"
Write-Output "- Odd runs swap strike; end of over swaps too"
Write-Output "- Wides/no-balls are NOT legal deliveries (don't count toward 6-ball over)"
Write-Output "- No-ball triggers free hit (only run out possible on free hit)"
Write-Output "- Byes/leg-byes don't count against bowler and don't break maidens"
Write-Output "- All out = players_per_side - 1 wickets (not hardcoded 10)"
Write-Output ""

$repoRoot = Join-Path $PSScriptRoot "..\.."

# --- Git state context ---
Write-Output "=== GIT STATE ==="

# Current branch
$branch = & git -C $repoRoot branch --show-current 2>$null
if ($branch) {
    Write-Output "Branch: $branch"
}

# Last commit message
$lastCommit = & git -C $repoRoot log --oneline -1 2>$null
if ($lastCommit) {
    Write-Output "Last commit: $lastCommit"
}

# Modified files (unstaged)
$diffFiles = & git -C $repoRoot diff --name-only HEAD 2>$null
if ($diffFiles) {
    Write-Output "Modified files:"
    foreach ($f in $diffFiles -split "`n") {
        if ($f.Trim()) { Write-Output "  $f" }
    }
}

# Staged files
$stagedFiles = & git -C $repoRoot diff --cached --name-only 2>$null
if ($stagedFiles) {
    Write-Output "Staged files:"
    foreach ($f in $stagedFiles -split "`n") {
        if ($f.Trim()) { Write-Output "  $f" }
    }
}

Write-Output ""

# Extract current session context from CONTINUE_PROMPT.md
$continueFile = Join-Path $repoRoot "docs\CONTINUE_PROMPT.md"
if (Test-Path $continueFile) {
    Write-Output "=== CURRENT SESSION CONTEXT ==="

    $content = Get-Content $continueFile -Raw

    # Extract current phase
    if ($content -match 'Phase\s+(\d+\.?\d*)') {
        Write-Output "Current Phase: $($Matches[1])"
    }

    # Extract current screen being worked on
    if ($content -match '(?:current|working on|next).*?(\d{2}-[a-z-]+\.html)') {
        Write-Output "Current Screen: $($Matches[1])"
    }

    # Count pending checklist items
    $pendingItems = ([regex]::Matches($content, '- \[ \]')).Count
    $completedItems = ([regex]::Matches($content, '- \[x\]')).Count
    if ($pendingItems -gt 0 -or $completedItems -gt 0) {
        Write-Output "Checklist: $completedItems done, $pendingItems pending"
    }

    # Extract "What to Do Next" first 5 lines
    if ($content -match '(?s)## What to Do Next\s*\n(.+?)(?:\n## |\z)') {
        $nextSection = $Matches[1].Trim() -split "`n" | Select-Object -First 5
        if ($nextSection) {
            Write-Output "Next steps:"
            foreach ($line in $nextSection) {
                Write-Output "  $line"
            }
        }
    }

    Write-Output ""
}

Write-Output "WORKFLOW: Read PLAYBOOK.md for 17-step TDD workflow and phase gates."
Write-Output "=== Full rules: .claude/rules.md | CLAUDE.md ==="

exit 0
