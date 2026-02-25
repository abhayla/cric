## Prod E2E: Fresh Database → APK → Real Device Viewer + Emulator Scorer

### Phase 1: Clean Prod Database
- Connect to the VPS PostgreSQL (`103.118.16.189:5432`, database `cricscores`, user `cricscores_user`)
- Drop all data from all tables (truncate cascade) — fresh start, no leftover test data
- Re-run seed data (`bun run db:seed`) so master data tables (dismissal_types, ball_types, fielding_positions, wagon_wheel_zones) are populated

### Phase 2: Build & Install Prod APK
- Build a fresh prod release APK: `flutter build apk --flavor prod --release --dart-define=FLAVOR=prod`
- Identify the attached real device via `adb devices` (expected serial: `843773fe`, OPPO CPH2691)
- Install the APK on the real device: `adb -s <device-id> install -r <apk-path>`
- Verify the app launches (package: `in.cricscores.app`)

### Phase 3: Real Device Setup (Viewer — Abhay)
- On the real device, log in with phone number **9999999998** / OTP **123456**
- Complete profile setup for **Abhay** — set as a player (role: all_rounder or batter, your choice)
- Abhay must be added as a player to one of the teams created in Phase 4

### Phase 4: Emulator Setup (Scorer)
- Use the emulator (get device ID from `flutter devices`, expected: `emulator-5554`)
- Log in with phone number **9999999999** / OTP **123456**
- Complete profile setup for the scorer user

### Phase 5: Full Match via UI Only (Scorer on Emulator)
**Critical constraint: ALL operations must be done through the app UI. No direct API calls, no `curl`, no server-side shortcuts. Everything through Flutter integration test or manual UI automation.**

This includes:
1. **Create two teams** via UI (Create Team page) — one team must include Abhay (the viewer user from the real device) as a player
2. **Add players to both rosters** via UI (Add Player page) — minimum players per side (e.g., 6v6 or 11v11)
3. **Create a match** via UI (Match Setup page) — select the two teams, set overs/format
4. **Complete toss** via UI (Toss wizard — all 5 steps: toss winner, bat/field choice, Playing XI for both teams, openers + bowler)
5. **Score the full match** via UI (Scoring page) — record deliveries, extras, wickets, over transitions, innings transition, until match completes
6. **Verify match completion** — match complete modal appears with correct result

### Phase 6: Viewer Verification (Real Device)
- On the real device (Abhay's account), navigate to the live match and verify:
  - Live score updates appear via WebSocket
  - Final match result is visible after completion

### Constraints & Rules
- **No API shortcuts**: No `curl`, no direct DB inserts, no test-verify endpoints. Every action flows through the app UI.
- **Prod environment**: APK points to `https://cricscores.in/api/v1` and `wss://cricscores.in/ws` — this is testing the real production server
- **Firebase test numbers**: Both 9999999999 and 9999999998 are configured in Firebase project `cricapp-7403d` with OTP 123456
- **Abhay is a real person**: His profile and team membership should look realistic (not "Test User 1")
