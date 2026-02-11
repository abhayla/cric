# Hook: Cross-Feature Import Guard
# Event: PreToolUse on Write
# Blocks cross-feature data/domain imports in Dart files

$input = $env:CLAUDE_TOOL_INPUT
if (-not $input) {
    $input = [Console]::In.ReadToEnd()
}

try {
    $json = $input | ConvertFrom-Json
} catch {
    exit 0
}

$filePath = $json.file_path
$content = $json.content

if (-not $filePath -or -not $content) { exit 0 }

# Normalize path separators
$filePath = $filePath -replace '\\', '/'

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
