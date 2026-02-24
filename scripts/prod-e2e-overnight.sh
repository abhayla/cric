#!/usr/bin/env bash
# =============================================================================
# Production E2E Overnight Runner
# =============================================================================
# Runs all 5 tournament tests sequentially with logging.
# Expects: emulator running, prod server live at cricscores.in.
#
# Usage:
#   bash scripts/prod-e2e-overnight.sh
#   bash scripts/prod-e2e-overnight.sh --skip-teams   # Skip team setup
#   bash scripts/prod-e2e-overnight.sh --only 3       # Run only tournament 3
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MOBILE_DIR="$PROJECT_DIR/apps/mobile"
LOG_DIR="$PROJECT_DIR/logs/prod-e2e"

# Parse args
SKIP_TEAMS=false
ONLY_TOURNAMENT=""
for arg in "$@"; do
  case $arg in
    --skip-teams) SKIP_TEAMS=true ;;
    --only) shift; ONLY_TOURNAMENT="$1" ;;
  esac
  shift 2>/dev/null || true
done

# Create log directory
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SUMMARY_LOG="$LOG_DIR/summary_$TIMESTAMP.log"

# Flutter test command base
FLUTTER_CMD="flutter test --flavor prod --dart-define=FLAVOR=prod"
DEVICE="-d emulator-5554"

echo "==============================================================================" | tee "$SUMMARY_LOG"
echo "  PRODUCTION E2E OVERNIGHT RUN" | tee -a "$SUMMARY_LOG"
echo "  Started: $(date)" | tee -a "$SUMMARY_LOG"
echo "  Log dir: $LOG_DIR" | tee -a "$SUMMARY_LOG"
echo "==============================================================================" | tee -a "$SUMMARY_LOG"

cd "$MOBILE_DIR"

run_test() {
  local name="$1"
  local file="$2"
  local log_file="$LOG_DIR/${name}_$TIMESTAMP.log"

  echo "" | tee -a "$SUMMARY_LOG"
  echo "----------------------------------------------------------------------" | tee -a "$SUMMARY_LOG"
  echo "[$name] Starting at $(date)" | tee -a "$SUMMARY_LOG"
  echo "[$name] Log: $log_file" | tee -a "$SUMMARY_LOG"
  echo "----------------------------------------------------------------------" | tee -a "$SUMMARY_LOG"

  local start_time=$(date +%s)

  if $FLUTTER_CMD "$file" $DEVICE 2>&1 | tee "$log_file"; then
    local end_time=$(date +%s)
    local duration=$(( end_time - start_time ))
    local minutes=$(( duration / 60 ))
    local seconds=$(( duration % 60 ))
    echo "[$name] PASSED in ${minutes}m ${seconds}s" | tee -a "$SUMMARY_LOG"
  else
    local end_time=$(date +%s)
    local duration=$(( end_time - start_time ))
    local minutes=$(( duration / 60 ))
    local seconds=$(( duration % 60 ))
    echo "[$name] FAILED after ${minutes}m ${seconds}s" | tee -a "$SUMMARY_LOG"
    echo "[$name] Check log: $log_file" | tee -a "$SUMMARY_LOG"
    # Don't exit — continue with next tournament
  fi
}

# Step 0: Team Setup (one-time, ~5 min)
if [ "$SKIP_TEAMS" = false ] && [ -z "$ONLY_TOURNAMENT" ]; then
  run_test "team-setup" "integration_test/prod/prod_team_setup_test.dart"
fi

# Step 1-5: Tournaments
TOURNAMENTS=(
  "tournament-1:integration_test/prod/prod_tournament_1_test.dart"
  "tournament-2:integration_test/prod/prod_tournament_2_test.dart"
  "tournament-3:integration_test/prod/prod_tournament_3_test.dart"
  "tournament-4:integration_test/prod/prod_tournament_4_test.dart"
  "tournament-5:integration_test/prod/prod_tournament_5_test.dart"
)

for entry in "${TOURNAMENTS[@]}"; do
  IFS=':' read -r name file <<< "$entry"
  tournament_num="${name##*-}"

  if [ -n "$ONLY_TOURNAMENT" ] && [ "$tournament_num" != "$ONLY_TOURNAMENT" ]; then
    continue
  fi

  run_test "$name" "$file"
done

echo "" | tee -a "$SUMMARY_LOG"
echo "==============================================================================" | tee -a "$SUMMARY_LOG"
echo "  OVERNIGHT RUN COMPLETE" | tee -a "$SUMMARY_LOG"
echo "  Finished: $(date)" | tee -a "$SUMMARY_LOG"
echo "  Summary: $SUMMARY_LOG" | tee -a "$SUMMARY_LOG"
echo "==============================================================================" | tee -a "$SUMMARY_LOG"
