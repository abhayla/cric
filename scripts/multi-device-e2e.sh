#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# Multi-Device E2E Test Orchestrator
# ═══════════════════════════════════════════════════════════════════════════
#
# Runs the CricApp multi-device E2E test:
#   - Scorer on Android emulator (scores a full predetermined match)
#   - Viewer on real Android device (verifies WebSocket live updates)
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
#
set -euo pipefail

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
# Step 4: Reset test database
# ═══════════════════════════════════════════════════════════════════════════
log "Step 4: Resetting test database..."
curl -sf -X POST "http://localhost:$SERVER_PORT/api/v1/test/reset-match-data" >/dev/null 2>&1 || true
log_ok "Database reset"

# ═══════════════════════════════════════════════════════════════════════════
# Step 5: Launch scorer on emulator
# ═══════════════════════════════════════════════════════════════════════════
log "Step 5: Launching SCORER on emulator ($EMULATOR_ID)..."

cd "$MOBILE_DIR"
flutter test integration_test/multi_device_scorer_e2e_test.dart \
  -d "$EMULATOR_ID" 2>&1 | sed "s/^/[scorer] /" &
SCORER_PID=$!
cd "$PROJECT_ROOT"

# ═══════════════════════════════════════════════════════════════════════════
# Step 6: Wait for scorer to create match
# ═══════════════════════════════════════════════════════════════════════════
log "Step 6: Waiting 15s for scorer to create match..."
sleep 15

# ═══════════════════════════════════════════════════════════════════════════
# Step 7: Launch viewer on real device
# ═══════════════════════════════════════════════════════════════════════════
log "Step 7: Launching VIEWER on real device ($REAL_DEVICE_ID)..."
log "  API_BASE_URL=http://$LAN_IP:$SERVER_PORT/api/v1"
log "  WS_BASE_URL=ws://$LAN_IP:$SERVER_PORT/ws"

cd "$MOBILE_DIR"
flutter test integration_test/multi_device_viewer_e2e_test.dart \
  -d "$REAL_DEVICE_ID" \
  --dart-define="API_BASE_URL=http://$LAN_IP:$SERVER_PORT/api/v1" \
  --dart-define="WS_BASE_URL=ws://$LAN_IP:$SERVER_PORT/ws" 2>&1 | sed "s/^/[viewer] /" &
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
  echo -e "  Scorer (emulator):     ${GREEN}PASSED${NC}"
else
  echo -e "  Scorer (emulator):     ${RED}FAILED (exit $SCORER_EXIT)${NC}"
fi

if [[ $VIEWER_EXIT -eq 0 ]]; then
  echo -e "  Viewer (real device):  ${GREEN}PASSED${NC}"
else
  echo -e "  Viewer (real device):  ${RED}FAILED (exit $VIEWER_EXIT)${NC}"
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
