# Hook: PostToolUse Auto-Format
# Event: PostToolUse (Edit|Write)
# Reads tool input JSON from stdin, extracts file_path
# Formats .dart files with dart format and .ts files with npx prettier
# Skips generated files: *.g.dart, *.freezed.dart, *.gr.dart
# Exit 0 always — formatting failure should never block

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

    # Skip generated files
    if ($filePath -match '\.(g|freezed|gr)\.dart$') {
        exit 0
    }

    # Format .dart files
    if ($filePath -match '\.dart$') {
        $repoRoot = Join-Path $PSScriptRoot "..\.."
        $mobileDir = Join-Path $repoRoot "apps\mobile"
        if (Test-Path $mobileDir) {
            & dart format --fix "$filePath" 2>$null | Out-Null
        }
        exit 0
    }

    # Format .ts files
    if ($filePath -match '\.ts$') {
        $repoRoot = Join-Path $PSScriptRoot "..\.."
        $serverDir = Join-Path $repoRoot "apps\server"
        if (Test-Path $serverDir) {
            $prettierConfig = Join-Path $serverDir ".prettierrc"
            if (Test-Path $prettierConfig) {
                & npx prettier --write "$filePath" 2>$null | Out-Null
            } else {
                & npx prettier --write --single-quote --trailing-comma all "$filePath" 2>$null | Out-Null
            }
        }
        exit 0
    }
} catch {
    # Never block on formatting failure
    exit 0
}

exit 0
