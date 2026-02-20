# Hook: Cross-Feature Import Guard
# Event: PreToolUse on Write
# Blocks cross-feature data/domain imports in Dart files

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
$content = $json.content

if (-not $filePath -or -not $content) { exit 0 }

# Skip files outside the project root
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path -replace '\\','/'
$normalizedFile = $filePath -replace '\\','/'
if ($normalizedFile -notlike "$projectRoot*") { exit 0 }

# Normalize path separators
$filePath = $normalizedFile

# Only check Dart files in features/
if ($filePath -notmatch '\.dart$') { exit 0 }
if ($filePath -notmatch 'features/') { exit 0 }
if ($filePath -match '\.(g|freezed|gr)\.dart$') { exit 0 }
if ($filePath -match '/test/') { exit 0 }

# Extract the current feature name
if ($filePath -match 'features/([^/]+)/') {
    $currentFeature = $Matches[1]
} else {
    exit 0
}

# Check content for imports from other features' data/ or domain/ directories
$lines = $content -split "`n"
foreach ($line in $lines) {
    if ($line -match "import\s+['\"].*features/([^/]+)/(data|domain)/") {
        $importedFeature = $Matches[1]
        if ($importedFeature -ne $currentFeature) {
            [Console]::Error.WriteLine("BLOCKED: Cross-feature import detected. Feature '$currentFeature' imports from '$importedFeature/$($Matches[2])/'. Features communicate only through shared/ providers. See rules.md.")
            exit 2
        }
    }
}

exit 0
