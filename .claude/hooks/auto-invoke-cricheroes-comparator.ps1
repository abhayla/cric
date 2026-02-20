# Hook: Auto-Invoke CricHeroes Comparator Reminder
# Event: PreToolUse (Write)
# Detects new *_page.dart file creation in features/*/presentation/pages/
# Outputs a non-blocking reminder to invoke the cricheroes-comparator agent

try {
    $input = $env:CLAUDE_TOOL_INPUT
    if (-not $input) {
        if ([Console]::IsInputRedirected) {
            $input = [Console]::In.ReadToEnd()
        }
    }
    if (-not $input) { exit 0 }
    $json = $input | ConvertFrom-Json
} catch {
    exit 0
}

$filePath = $json.file_path
if (-not $filePath) { exit 0 }

# Skip files outside the project root
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path -replace '\\','/'
if (($filePath -replace '\\','/') -notlike "$projectRoot*") { exit 0 }

# Check if the file path matches a page file in a feature's presentation/pages/ directory
if ($filePath -match 'features[\\/][^\\/]+[\\/]presentation[\\/]pages[\\/][a-z_]+_page\.dart') {
    # Extract the feature name for the reminder
    if ($filePath -match 'features[\\/]([^\\/]+)[\\/]') {
        $featureName = $Matches[1]
        Write-Output "REMINDER: New page detected in '$featureName' feature."
        Write-Output "Before implementing, invoke the cricheroes-comparator agent:"
        Write-Output "  Task(cricheroes-comparator, 'Compare $featureName feature against CricHeroes')"
        Write-Output "This is required by CLAUDE.md workflow preferences."
    }
}

# Always exit 0 — this is a non-blocking reminder
exit 0
