# Hook: Verify Evidence Artifacts
# Event: PreToolUse on Bash (git commit commands only)
# Blocks commits when fixes were applied but post-fix-pipeline was not invoked

$input = $env:CLAUDE_TOOL_INPUT
if (-not $input) {
    $input = [Console]::In.ReadToEnd()
}

try {
    $json = $input | ConvertFrom-Json
} catch {
    exit 0
}

$command = $json.command
if (-not $command) { exit 0 }

# Only check on git commit commands
if ($command -notmatch 'git\s+commit') { exit 0 }

$repoRoot = Join-Path $PSScriptRoot "..\.."
$stateFile = Join-Path $repoRoot ".claude\workflow-state.json"

if (-not (Test-Path $stateFile)) { exit 0 }

try {
    $state = Get-Content $stateFile -Raw | ConvertFrom-Json
} catch {
    exit 0
}

$failures = @()

# Check 1: If fixes were applied, post-fix-pipeline must have been invoked
$fixCount = 0
if ($state.fixesApplied) {
    $fixCount = @($state.fixesApplied).Count
}

if ($fixCount -gt 0) {
    $pipelineInvoked = $false
    if ($state.skillInvocations -and $state.skillInvocations.postFixPipelineInvoked) {
        $pipelineInvoked = $true
    }
    if (-not $pipelineInvoked) {
        $failures += "BLOCKED: $fixCount fix(es) were applied but /post-fix-pipeline was not invoked. Run /post-fix-pipeline before committing."
    }
}

# Check 2: If visual issues are pending, block commit
if ($state.visualIssuesPending -eq $true) {
    $failures += "BLOCKED: Visual issues are pending. Run /verify-screenshots and resolve issues before committing."
}

# Check 3: If active command is fix-issue or implement, ensure fix-loop was invoked for any failures
if ($state.activeCommand -in @('fix-issue', 'implement', 'tdd')) {
    $failureCount = 0
    if ($state.testResults -and $state.testResults.failureCount) {
        $failureCount = $state.testResults.failureCount
    }
    if ($failureCount -gt 0) {
        $fixLoopInvoked = $false
        if ($state.skillInvocations -and $state.skillInvocations.fixLoopInvoked) {
            $fixLoopInvoked = $true
        }
        if (-not $fixLoopInvoked) {
            $failures += "BLOCKED: Test failures detected ($failureCount) but /fix-loop was not invoked. Use /fix-loop to address failures before committing."
        }
    }
}

if ($failures.Count -gt 0) {
    $msg = $failures -join "`n"
    [Console]::Error.WriteLine("EVIDENCE GATE FAILED:`n$msg")
    exit 2
}

exit 0
