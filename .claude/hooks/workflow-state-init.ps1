# Hook: Workflow State Initialization
# Event: SessionStart (startup|resume)
# Creates workflow-state.json if missing, resets transient fields on session start

$repoRoot = Join-Path $PSScriptRoot "..\.."
$stateFile = Join-Path $repoRoot ".claude\workflow-state.json"

if (-not (Test-Path $stateFile)) {
    $initialState = @{
        activeCommand = $null
        sessionStartedAt = (Get-Date -Format "o")
        skillInvocations = @{
            fixLoopInvoked = $false
            fixLoopResult = $null
            postFixPipelineInvoked = $false
            postFixPipelineResult = $null
            verifyScreenshotsInvoked = $false
            verifyScreenshotsResult = $null
            reflectInvoked = $false
        }
        steps = @{}
        fixesApplied = @()
        filesChanged = @()
        testResults = @{
            lastRunPassed = $null
            failureCount = 0
        }
        visualIssuesPending = $false
    } | ConvertTo-Json -Depth 5

    [System.IO.File]::WriteAllText($stateFile, $initialState)
    [Console]::Error.WriteLine("Workflow state initialized: .claude/workflow-state.json")
} else {
    # Reset transient fields on session start but preserve learning data
    try {
        $state = Get-Content $stateFile -Raw | ConvertFrom-Json
        $state.activeCommand = $null
        $state.sessionStartedAt = (Get-Date -Format "o")
        $state.skillInvocations = @{
            fixLoopInvoked = $false
            fixLoopResult = $null
            postFixPipelineInvoked = $false
            postFixPipelineResult = $null
            verifyScreenshotsInvoked = $false
            verifyScreenshotsResult = $null
            reflectInvoked = $false
        }
        $state.steps = @{}
        $state.fixesApplied = @()
        $state.filesChanged = @()
        $state.testResults = @{
            lastRunPassed = $null
            failureCount = 0
        }
        $state.visualIssuesPending = $false

        $json = $state | ConvertTo-Json -Depth 5
        [System.IO.File]::WriteAllText($stateFile, $json)
    } catch {
        # If state file is corrupted, recreate it
        Remove-Item $stateFile -Force
        [Console]::Error.WriteLine("Workflow state was corrupted, recreated.")
    }
}

exit 0
