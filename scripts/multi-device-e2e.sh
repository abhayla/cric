#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# Multi-Device E2E Test Orchestrator
# ═══════════════════════════════════════════════════════════════════════════
#
# Runs the CricScores multi-device E2E test:
#   - Scorer on one Android device (scores a full predetermined match)
#   - Viewer on another Android device (verifies WebSocket live updates)
#
# By default: scorer=emulator, viewer=real device.
# Set SWAP_DEVICES=1 to swap (scorer=real device, viewer=emulator).
#
# Prerequisites:
#   - Android emulator running
#   - Real Android device connected via USB (USB debugging ON)
#   - Both on same network (device can reach host on port 3001)
#   - Windows Firewall allows port 3001
#
# Usage:
#   ./scripts/multi-device-e2e.sh
#   LAN_IP=192.168.1.100 ./scripts/multi-device-e2e.sh
#   SWAP_DEVICES=1 ./scripts/multi-device-e2e.sh
#
set -euo pipefail

# Ensure Android SDK platform-tools (adb) is on PATH
if ! command -v adb &>/dev/null; then
  for candidate in \
    "${LOCALAPPDATA:-}/Android/Sdk/platform-tools" \
    "$HOME/AppData/Local/Android/Sdk/platform-tools" \
    "${ANDROID_HOME:-}/platform-tools" \
    "${ANDROID_SDK_ROOT:-}/platform-tools"; do
    if [[ -n "$candidate" ]] && [[ -f "$candidate/adb" || -f "$candidate/adb.exe" ]]; then
      # On Git Bash/MSYS, convert Windows paths to Unix paths for PATH
      if command -v cygpath &>/dev/null; then
        candidate="$(cygpath -u "$candidate")"
      fi
      export PATH="$PATH:$candidate"
      break
    fi
  done
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SERVER_DIR="$PROJECT_ROOT/apps/server"
MOBILE_DIR="$PROJECT_ROOT/apps/mobile"
SERVER_PORT=3001
SERVER_PID=""
SCORER_PID=""
VIEWER_PID=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log() { echo -e "${CYAN}[orchestrator]${NC} $*"; }
log_ok() { echo -e "${GREEN}[orchestrator]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[orchestrator]${NC} $*"; }
log_err() { echo -e "${RED}[orchestrator]${NC} $*"; }

# ── Cleanup trap ──
cleanup() {
  log "Cleaning up..."
  if [[ -n "$SCORER_PID" ]] && kill -0 "$SCORER_PID" 2>/dev/null; then
    log "Stopping scorer (PID $SCORER_PID)"
    kill "$SCORER_PID" 2>/dev/null || true
  fi
  if [[ -n "$VIEWER_PID" ]] && kill -0 "$VIEWER_PID" 2>/dev/null; then
    log "Stopping viewer (PID $VIEWER_PID)"
    kill "$VIEWER_PID" 2>/dev/null || true
  fi
  if [[ -n "$SERVER_PID" ]] && kill -0 "$SERVER_PID" 2>/dev/null; then
    log "Stopping server (PID $SERVER_PID)"
    kill "$SERVER_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# ═══════════════════════════════════════════════════════════════════════════
# Pre-flight: Kill stale integration test processes
# ═══════════════════════════════════════════════════════════════════════════
log "Pre-flight: Cleaning stale integration test processes..."

if command -v wmic.exe &>/dev/null; then
  # Windows/Git Bash: find dart.exe processes running integration tests
  stale_pids=$(wmic.exe process where "name='dart.exe'" get processid,commandline 2>/dev/null \
    | grep -i "integration_test" \
    | awk '{print $NF}' \
    | tr -d '\r' || true)

  if [[ -n "$stale_pids" ]]; then
    while IFS= read -r pid; do
      if [[ -n "$pid" ]] && [[ "$pid" =~ ^[0-9]+$ ]]; then
        log_warn "Killing stale dart.exe integration test process (PID $pid)"
        taskkill.exe /PID "$pid" /F 2>/dev/null || true
      fi
    done <<< "$stale_pids"
  else
    log_ok "No stale integration test processes found"
  fi
else
  # Linux/Mac: find dart processes running integration tests
  stale_pids=$(pgrep -f "dart.*integration_test" 2>/dev/null || true)
  if [[ -n "$stale_pids" ]]; then
    while IFS= read -r pid; do
      if [[ -n "$pid" ]]; then
        log_warn "Killing stale dart integration test process (PID $pid)"
        kill "$pid" 2>/dev/null || true
      fi
    done <<< "$stale_pids"
  else
    log_ok "No stale integration test processes found"
  fi
fi

# ═══════════════════════════════════════════════════════════════════════════
# Step 1: Detect devices
# ═══════════════════════════════════════════════════════════════════════════
log "Step 1: Detecting devices..."

DEVICES_JSON=$(flutter devices --machine 2>/dev/null || echo "[]")
EMULATOR_ID=""
REAL_DEVICE_ID=""

# Parse device list — look for emulator and real device
while IFS= read -r line; do
  id=$(echo "$line" | sed -n 's/.*"id": *"\([^"]*\)".*/\1/p')
  is_emu=$(echo "$line" | sed -n 's/.*"isVirtual": *\(true\|false\).*/\1/p')
  platform=$(echo "$line" | sed -n 's/.*"targetPlatform": *"\([^"]*\)".*/\1/p')

  # Only consider Android devices
  if [[ "$platform" == *"android"* ]]; then
    if [[ "$is_emu" == "true" ]] && [[ -z "$EMULATOR_ID" ]]; then
      EMULATOR_ID="$id"
    elif [[ "$is_emu" == "false" ]] && [[ -z "$REAL_DEVICE_ID" ]]; then
      REAL_DEVICE_ID="$id"
    fi
  fi
done < <(echo "$DEVICES_JSON" | tr ',' '\n')

# Fallback: use adb devices if flutter parsing failed
if [[ -z "$EMULATOR_ID" ]] || [[ -z "$REAL_DEVICE_ID" ]]; then
  log_warn "Flutter device detection incomplete, trying adb..."
  while IFS= read -r line; do
    dev=$(echo "$line" | awk '{print $1}')
    if [[ "$dev" == emulator-* ]] && [[ -z "$EMULATOR_ID" ]]; then
      EMULATOR_ID="$dev"
    elif [[ "$dev" =~ ^[A-Za-z0-9]+ ]] && [[ "$dev" != "List" ]] && [[ -z "$REAL_DEVICE_ID" ]]; then
      REAL_DEVICE_ID="$dev"
    fi
  done < <(adb devices | grep -E "device$" | grep -v "^$")
fi

if [[ -z "$EMULATOR_ID" ]]; then
  log_err "No Android emulator detected. Start one first."
  exit 1
fi
if [[ -z "$REAL_DEVICE_ID" ]]; then
  log_err "No real Android device detected. Connect via USB with debugging enabled."
  exit 1
fi

log_ok "Emulator:    $EMULATOR_ID"
log_ok "Real device: $REAL_DEVICE_ID"

# ═══════════════════════════════════════════════════════════════════════════
# Step 2: Detect LAN IP
# ═══════════════════════════════════════════════════════════════════════════
log "Step 2: Detecting LAN IP..."

if [[ -z "${LAN_IP:-}" ]]; then
  # Try to get Wi-Fi or Ethernet IPv4 from ipconfig (Windows/Git Bash)
  if command -v ipconfig.exe &>/dev/null; then
    LAN_IP=$(ipconfig.exe 2>/dev/null \
      | grep -A5 "Wi-Fi\|Wireless\|Ethernet" \
      | grep "IPv4" \
      | head -1 \
      | sed 's/.*: //' \
      | tr -d '\r')
  fi

  # Fallback: ip route (Linux/WSL)
  if [[ -z "${LAN_IP:-}" ]] && command -v ip &>/dev/null; then
    LAN_IP=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' || true)
  fi

  # Fallback: hostname -I
  if [[ -z "${LAN_IP:-}" ]] && command -v hostname &>/dev/null; then
    LAN_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || true)
  fi
fi

if [[ -z "${LAN_IP:-}" ]]; then
  log_err "Could not detect LAN IP. Set it manually: LAN_IP=x.x.x.x $0"
  exit 1
fi

log_ok "LAN IP: $LAN_IP"

# ── Device assignment (supports SWAP_DEVICES=1) ──
if [[ "${SWAP_DEVICES:-0}" == "1" ]]; then
  SCORER_DEVICE_ID="$REAL_DEVICE_ID"
  VIEWER_DEVICE_ID="$EMULATOR_ID"
  SCORER_LABEL="real device"
  VIEWER_LABEL="emulator"
  # Real device scorer needs LAN IP dart-defines
  SCORER_DART_DEFINES=(
    --dart-define="API_BASE_URL=http://$LAN_IP:$SERVER_PORT/api/v1"
    --dart-define="WS_BASE_URL=ws://$LAN_IP:$SERVER_PORT/ws"
  )
  # Emulator viewer uses default 10.0.2.2 — no dart-defines needed
  VIEWER_DART_DEFINES=()
  log_warn "SWAP_DEVICES=1 — scorer on real device, viewer on emulator"
else
  SCORER_DEVICE_ID="$EMULATOR_ID"
  VIEWER_DEVICE_ID="$REAL_DEVICE_ID"
  SCORER_LABEL="emulator"
  VIEWER_LABEL="real device"
  # Emulator scorer uses default 10.0.2.2 — no dart-defines needed
  SCORER_DART_DEFINES=()
  # Real device viewer needs LAN IP dart-defines
  VIEWER_DART_DEFINES=(
    --dart-define="API_BASE_URL=http://$LAN_IP:$SERVER_PORT/api/v1"
    --dart-define="WS_BASE_URL=ws://$LAN_IP:$SERVER_PORT/ws"
  )
fi

# ═══════════════════════════════════════════════════════════════════════════
# Step 3: Start server (if not running)
# ═══════════════════════════════════════════════════════════════════════════
log "Step 3: Checking server at http://localhost:$SERVER_PORT ..."

server_healthy() {
  curl -sf "http://localhost:$SERVER_PORT/api/v1/test/health" >/dev/null 2>&1 ||
  curl -sf "http://localhost:$SERVER_PORT/api/v1/test/health" -o /dev/null -w "%{http_code}" 2>/dev/null | grep -qE "^(200|404|403)$"
}

if server_healthy; then
  log_ok "Server already running"
else
  log "Starting Bun server..."
  cd "$SERVER_DIR"
  PORT=$SERVER_PORT NODE_ENV=test bun run src/index.ts &
  SERVER_PID=$!
  cd "$PROJECT_ROOT"

  # Wait up to 30s for health
  deadline=$((SECONDS + 30))
  while (( SECONDS < deadline )); do
    if server_healthy; then
      log_ok "Server started (PID $SERVER_PID)"
      break
    fi
    sleep 1
  done

  if ! server_healthy; then
    log_err "Server failed to start within 30s"
    exit 1
  fi
fi

# ═══════════════════════════════════════════════════════════════════════════
# Step 4: Reset test database + clear stale signals
# ═══════════════════════════════════════════════════════════════════════════
log "Step 4: Resetting test database and clearing signals..."
curl -sf -X POST "http://localhost:$SERVER_PORT/api/v1/test/reset-match-data" >/dev/null 2>&1 || true
curl -sf -X DELETE "http://localhost:$SERVER_PORT/api/v1/test/signals" >/dev/null 2>&1 || true
log_ok "Database reset, signals cleared"

# ═══════════════════════════════════════════════════════════════════════════
# Step 5: Launch scorer
# ═══════════════════════════════════════════════════════════════════════════
log "Step 5: Launching SCORER on $SCORER_LABEL ($SCORER_DEVICE_ID)..."

cd "$MOBILE_DIR"
flutter test integration_test/multi_device_scorer_e2e_test.dart \
  -d "$SCORER_DEVICE_ID" ${SCORER_DART_DEFINES[@]+"${SCORER_DART_DEFINES[@]}"} 2>&1 | sed "s/^/[scorer] /" &
SCORER_PID=$!
cd "$PROJECT_ROOT"

# ═══════════════════════════════════════════════════════════════════════════
# Step 6: Poll for scorer-ready signal (replaces hardcoded sleep)
# ═══════════════════════════════════════════════════════════════════════════
log "Step 6: Polling for scorer-ready signal (up to 5 minutes)..."

POLL_DEADLINE=$((SECONDS + 300))
SCORER_READY=false

while (( SECONDS < POLL_DEADLINE )); do
  # Check scorer process is still alive
  if ! kill -0 "$SCORER_PID" 2>/dev/null; then
    log_err "Scorer process died before signaling ready"
    wait "$SCORER_PID" 2>/dev/null || true
    SCORER_PID=""
    exit 1
  fi

  # Poll the scorer-ready signal
  SIGNAL_VALUE=$(curl -sf "http://localhost:$SERVER_PORT/api/v1/test/signal/scorer-ready" 2>/dev/null \
    | sed -n 's/.*"value": *"\([^"]*\)".*/\1/p' || true)

  if [[ "$SIGNAL_VALUE" == "true" ]]; then
    SCORER_READY=true
    log_ok "Scorer-ready signal received!"
    break
  fi

  # Progress indicator every 10s
  if (( SECONDS % 10 < 2 )); then
    log "Waiting for scorer-ready... (${SECONDS}s elapsed)"
  fi

  sleep 2
done

if [[ "$SCORER_READY" != "true" ]]; then
  log_err "Scorer did not signal ready within 5 minutes"
  exit 1
fi

# Grace period: let Gradle daemon fully release locks before viewer build
log "Waiting 5s grace period for Gradle daemon to idle..."
sleep 5

# ═══════════════════════════════════════════════════════════════════════════
# Step 7: Launch viewer
# ═══════════════════════════════════════════════════════════════════════════
log "Step 7: Launching VIEWER on $VIEWER_LABEL ($VIEWER_DEVICE_ID)..."
if [[ "$VIEWER_LABEL" == "real device" ]]; then
  log "  API_BASE_URL=http://$LAN_IP:$SERVER_PORT/api/v1"
  log "  WS_BASE_URL=ws://$LAN_IP:$SERVER_PORT/ws"
fi

cd "$MOBILE_DIR"
flutter test integration_test/multi_device_viewer_e2e_test.dart \
  -d "$VIEWER_DEVICE_ID" ${VIEWER_DART_DEFINES[@]+"${VIEWER_DART_DEFINES[@]}"} 2>&1 | sed "s/^/[viewer] /" &
VIEWER_PID=$!
cd "$PROJECT_ROOT"

# ═══════════════════════════════════════════════════════════════════════════
# Step 8: Wait for both to complete
# ═══════════════════════════════════════════════════════════════════════════
log "Step 8: Waiting for tests to complete..."

SCORER_EXIT=0
VIEWER_EXIT=0

wait "$SCORER_PID" 2>/dev/null || SCORER_EXIT=$?
SCORER_PID=""
log "Scorer exited with code $SCORER_EXIT"

wait "$VIEWER_PID" 2>/dev/null || VIEWER_EXIT=$?
VIEWER_PID=""
log "Viewer exited with code $VIEWER_EXIT"

# ═══════════════════════════════════════════════════════════════════════════
# Step 9: Print combined report
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "  MULTI-DEVICE E2E TEST REPORT"
echo "═══════════════════════════════════════════════════════════════════"

if [[ $SCORER_EXIT -eq 0 ]]; then
  echo -e "  Scorer ($SCORER_LABEL):     ${GREEN}PASSED${NC}"
else
  echo -e "  Scorer ($SCORER_LABEL):     ${RED}FAILED (exit $SCORER_EXIT)${NC}"
fi

if [[ $VIEWER_EXIT -eq 0 ]]; then
  echo -e "  Viewer ($VIEWER_LABEL):  ${GREEN}PASSED${NC}"
else
  echo -e "  Viewer ($VIEWER_LABEL):  ${RED}FAILED (exit $VIEWER_EXIT)${NC}"
fi

echo "───────────────────────────────────────────────────────────────────"

if [[ $SCORER_EXIT -eq 0 ]] && [[ $VIEWER_EXIT -eq 0 ]]; then
  echo -e "  Overall:               ${GREEN}ALL PASSED${NC}"
  echo "═══════════════════════════════════════════════════════════════════"
  exit 0
else
  echo -e "  Overall:               ${RED}SOME FAILED${NC}"
  echo "═══════════════════════════════════════════════════════════════════"
  exit 1
fi
