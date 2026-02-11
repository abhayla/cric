# Hook: Sensitive File Protection
# Event: PreToolUse on Edit|Write
# Blocks writes to sensitive files (.env, credentials, keys, etc.)

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
if (-not $filePath) { exit 0 }

# Normalize path separators
$filePath = $filePath -replace '\\', '/'
$fileName = [System.IO.Path]::GetFileName($filePath)

# Allow: .env.example, files in docs/, files in test/
if ($fileName -eq '.env.example') { exit 0 }
if ($filePath -match '/docs/') { exit 0 }
if ($filePath -match '/test/') { exit 0 }

# Block: .env files (but not .env.example already allowed above)
if ($fileName -match '^\.env') {
    [Console]::Error.WriteLine("BLOCKED: Cannot write to environment file '$fileName'. Use .env.example for templates.")
    exit 2
}

# Block: credential files
if ($fileName -match 'credentials') {
    [Console]::Error.WriteLine("BLOCKED: Cannot write to credentials file '$fileName'.")
    exit 2
}

# Block: service account files
if ($fileName -match 'service-account') {
    [Console]::Error.WriteLine("BLOCKED: Cannot write to service account file '$fileName'.")
    exit 2
}

# Block: google-services.json
if ($fileName -eq 'google-services.json') {
    [Console]::Error.WriteLine("BLOCKED: Cannot write to '$fileName'. This file contains Firebase credentials.")
    exit 2
}

# Block: key/certificate files
if ($fileName -match '\.(key|pem|p12)$') {
    [Console]::Error.WriteLine("BLOCKED: Cannot write to key/certificate file '$fileName'.")
    exit 2
}

exit 0
