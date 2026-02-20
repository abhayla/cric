# Hook: PostToolUse Remind Schema Parity
# Event: PostToolUse (Edit|Write)
# Non-blocking reminder when schema files are modified
# Reads tool input JSON from stdin, extracts file_path
# Exit 0 always — reminder should never block

try {
    $input = $null
    if (-not [Console]::IsInputRedirected) {
        exit 0
    }
    $input = [Console]::In.ReadToEnd() | ConvertFrom-Json -ErrorAction SilentlyContinue

    if (-not $input) { exit 0 }

    # Extract file_path from tool input
    $filePath = $null
    if ($input.tool_input -and $input.tool_input.file_path) {
        $filePath = $input.tool_input.file_path
    }
    if (-not $filePath) { exit 0 }

    # Skip files outside the project root
    $projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path -replace '\\','/'
    if (($filePath -replace '\\','/') -notlike "$projectRoot*") { exit 0 }

    # Check if file is a Drizzle schema file
    $isDrizzle = $filePath -match 'apps[\\/]server[\\/]src[\\/]db[\\/]schema[\\/].*\.ts$'

    # Check if file is a Drift table file
    $isDrift = $filePath -match 'apps[\\/]mobile[\\/]lib[\\/]src[\\/]shared[\\/]data[\\/]database[\\/]tables[\\/].*\.dart$'

    if ($isDrizzle -or $isDrift) {
        Write-Output "SCHEMA MODIFIED: Run /schema-parity to check Drift/Drizzle alignment."
        if ($isDrizzle) {
            Write-Output "  Also run: cd apps/server && bunx drizzle-kit generate (check for pending migrations)"
        }
        if ($isDrift) {
            Write-Output "  Also run: cd apps/mobile && dart run build_runner build --delete-conflicting-outputs"
        }
    }
} catch {
    # Never block on reminder failure
}

exit 0
