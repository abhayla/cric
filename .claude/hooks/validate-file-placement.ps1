# Hook: File Placement Validator
# Event: PreToolUse on Edit|Write
# Validates file paths against rules.md before any write

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
$normalizedFile = $filePath -replace '\\','/'
if ($normalizedFile -notlike "$projectRoot*") { exit 0 }

# Normalize path separators
$filePath = $normalizedFile

# Skip directories that don't need validation
$skipPatterns = @(
    '\.claude/',
    'docs/',
    'test/',
    'node_modules/',
    'build/',
    '\.dart_tool/',
    'android/',
    '\.github/',
    'scripts/',
    '\.gitignore',
    '\.mcp\.json',
    '\.env\.example'
)

foreach ($pattern in $skipPatterns) {
    if ($filePath -match $pattern) { exit 0 }
}

# Skip generated files
if ($filePath -match '\.(g|freezed|gr)\.dart$') { exit 0 }

# Skip config files at project root (not in apps/)
if ($filePath -notmatch 'apps/' -and $filePath -notmatch 'scripts/') { exit 0 }

# === Flutter checks (apps/mobile/) ===
if ($filePath -match 'apps/mobile/') {
    $libRelative = $filePath -replace '.*apps/mobile/lib/', ''

    # No files directly in lib/ except main.dart
    if ($filePath -match 'apps/mobile/lib/[^/]+\.dart$') {
        $fileName = [System.IO.Path]::GetFileName($filePath)
        if ($fileName -ne 'main.dart') {
            [Console]::Error.WriteLine("BLOCKED: No files directly in lib/ except main.dart. Got: $fileName. Place in lib/src/ subdirectory per rules.md.")
            exit 2
        }
    }

    # snake_case.dart naming for Dart files
    if ($filePath -match '\.dart$') {
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
        if ($fileName -notmatch '^[a-z][a-z0-9_]*$') {
            [Console]::Error.WriteLine("BLOCKED: Dart files must use snake_case naming. Got: $fileName.dart")
            exit 2
        }
    }

    # Drift tables only in shared/data/database/tables/
    if ($filePath -match '\.dart$' -and $filePath -match 'tables?' -and $filePath -notmatch 'shared/data/database/tables/') {
        if ($filePath -match 'drift|table' -and $filePath -notmatch 'presentation/' -and $filePath -notmatch 'test/') {
            # Only block if it looks like a Drift table file outside the correct location
            # This is a heuristic - actual table files would be caught by content review
        }
    }

    # No widgets in core/
    if ($filePath -match 'core/.*widget') {
        [Console]::Error.WriteLine("BLOCKED: No widgets in core/. Widgets belong in shared/widgets/ or feature presentation/widgets/. See rules.md.")
        exit 2
    }

    # No models/ folder in domain/
    if ($filePath -match 'domain/models/') {
        [Console]::Error.WriteLine("BLOCKED: No models/ folder in domain/. Domain uses entities/. Models belong in data/models/. See rules.md.")
        exit 2
    }

    # Pages must have _page.dart suffix
    if ($filePath -match 'presentation/pages/' -and $filePath -match '\.dart$') {
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
        if ($fileName -notmatch '_page$') {
            [Console]::Error.WriteLine("BLOCKED: Page files must have _page.dart suffix. Got: $fileName.dart")
            exit 2
        }
    }

    # Notifiers must have _notifier.dart suffix
    if ($filePath -match 'presentation/notifiers/' -and $filePath -match '\.dart$') {
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
        if ($fileName -notmatch '_notifier$') {
            [Console]::Error.WriteLine("BLOCKED: Notifier files must have _notifier.dart suffix. Got: $fileName.dart")
            exit 2
        }
    }

    # Models must have _model.dart suffix
    if ($filePath -match 'data/models/' -and $filePath -match '\.dart$') {
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
        if ($fileName -notmatch '_model$') {
            [Console]::Error.WriteLine("BLOCKED: Model files must have _model.dart suffix. Got: $fileName.dart")
            exit 2
        }
    }
}

# === Server checks (apps/server/) ===
if ($filePath -match 'apps/server/') {
    # kebab-case.ts naming for TypeScript files (except dot-notation service files)
    if ($filePath -match '\.ts$') {
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
        # Allow dot-notation for services (e.g., scoring.service)
        if ($fileName -match '\.') {
            # dot-notation file - check service suffix
        } elseif ($fileName -eq 'index') {
            # index.ts is fine
        } elseif ($fileName -notmatch '^[a-z][a-z0-9-]*$') {
            [Console]::Error.WriteLine("BLOCKED: TypeScript files must use kebab-case naming. Got: $fileName.ts")
            exit 2
        }
    }

    # Services must have .service.ts suffix
    if ($filePath -match 'services/' -and $filePath -match '\.ts$') {
        $fileName = [System.IO.Path]::GetFileName($filePath)
        if ($fileName -ne 'index.ts' -and $fileName -notmatch '\.service\.ts$') {
            [Console]::Error.WriteLine("BLOCKED: Service files must have .service.ts suffix. Got: $fileName")
            exit 2
        }
    }

    # No files in src/ root except index.ts
    if ($filePath -match 'apps/server/src/[^/]+\.ts$') {
        $fileName = [System.IO.Path]::GetFileName($filePath)
        if ($fileName -ne 'index.ts') {
            [Console]::Error.WriteLine("BLOCKED: No files in src/ root except index.ts. Got: $fileName. Place in appropriate subdirectory.")
            exit 2
        }
    }
}

exit 0
