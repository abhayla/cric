# Hook: Bash Command Safety Guard
# Event: PreToolUse on Bash
# Blocks destructive git and file operations

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

# Blocked patterns with specific error messages
$blockedPatterns = @(
    @{ Pattern = 'rm\s+-rf\b'; Message = "BLOCKED: 'rm -rf' is destructive. Remove files individually or ask for confirmation." }
    @{ Pattern = 'rm\s+-fr\b'; Message = "BLOCKED: 'rm -fr' is destructive. Remove files individually or ask for confirmation." }
    @{ Pattern = 'git\s+push\s+--force\b(?!-with-lease)'; Message = "BLOCKED: 'git push --force' can destroy remote history. Use 'git push --force-with-lease' instead." }
    @{ Pattern = 'git\s+push\s+-f\b'; Message = "BLOCKED: 'git push -f' can destroy remote history. Use 'git push --force-with-lease' instead." }
    @{ Pattern = 'git\s+reset\s+--hard\b'; Message = "BLOCKED: 'git reset --hard' discards all uncommitted changes. Stage changes or stash first." }
    @{ Pattern = 'git\s+clean\s+-f\b'; Message = "BLOCKED: 'git clean -f' permanently deletes untracked files." }
    @{ Pattern = 'git\s+clean\s+-fd\b'; Message = "BLOCKED: 'git clean -fd' permanently deletes untracked files and directories." }
    @{ Pattern = 'git\s+branch\s+-D\b'; Message = "BLOCKED: 'git branch -D' force-deletes a branch. Use 'git branch -d' for safe deletion." }
    @{ Pattern = '--no-verify\b'; Message = "BLOCKED: '--no-verify' skips pre-commit hooks. Run with hooks enabled to maintain code quality." }
)

foreach ($blocked in $blockedPatterns) {
    if ($command -match $blocked.Pattern) {
        [Console]::Error.WriteLine($blocked.Message)
        exit 2
    }
}

exit 0
