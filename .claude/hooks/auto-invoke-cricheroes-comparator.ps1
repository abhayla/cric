# Hook: Auto-Invoke CricHeroes Comparator Reminder
# Event: PreToolUse (Write)
# Detects new *_page.dart file creation in features/*/presentation/pages/
# Outputs a non-blocking reminder to invoke the cricheroes-comparator agent

param(
    [string]$TOOL_INPUT
)

# Check if the file path matches a page file in a feature's presentation/pages/ directory
if ($TOOL_INPUT -match 'features[\\/][^\\/]+[\\/]presentation[\\/]pages[\\/][a-z_]+_page\.dart') {
    $filePath = $Matches[0]
    # Extract the feature name for the reminder
    if ($TOOL_INPUT -match 'features[\\/]([^\\/]+)[\\/]') {
        $featureName = $Matches[1]
        Write-Output "REMINDER: New page detected in '$featureName' feature."
        Write-Output "Before implementing, invoke the cricheroes-comparator agent:"
        Write-Output "  Task(cricheroes-comparator, 'Compare $featureName feature against CricHeroes')"
        Write-Output "This is required by CLAUDE.md workflow preferences."
    }
}

# Always exit 0 — this is a non-blocking reminder
exit 0
