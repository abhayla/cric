# Pre-Production: Anywhere Actions (Local Machine)

These changes are made in the codebase (local dev machine) before building the APK. They fix issues that would break or degrade the app when friends use it over mobile data.

**Domain:** `cricscores.in` (pointed to VPS `103.118.16.189`)

---

## BLOCKER — Must complete before distributing

### A1. Add Dio Timeouts to 4 Feature Providers

**Problem:** Home, Player Profile, Tournaments, Updates features create `Dio()` with no timeout config. On slow/dropped mobile data, API calls hang indefinitely — the app appears frozen.

**Files to modify:**
- `apps/mobile/lib/src/features/home/providers.dart:9-11`
- `apps/mobile/lib/src/features/player_profile/providers.dart:12-14`
- `apps/mobile/lib/src/features/tournaments/providers.dart:12-14`
- `apps/mobile/lib/src/features/updates/providers.dart:9-11`

**Change:** Replace `Dio()` with:
```dart
Dio(BaseOptions(
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
  sendTimeout: const Duration(seconds: 10),
))
```

**Reference:** `teams/providers.dart:13-17` already does this correctly.

---

### A2. Add Firebase Auth Token to ALL Dio Instances

**Problem:** Only `scoring/providers.dart` attaches the Firebase Bearer token via interceptor. The other 4 Dio instances (home, player_profile, tournaments, updates) send requests WITHOUT auth tokens. In production (`NODE_ENV=production`), the server requires valid tokens — these requests will all return 401.

**Files to modify:** Same 4 files as A1.

**Change:** Add the same interceptor pattern from `scoring/providers.dart:32-50` to each Dio provider:
```dart
final _dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 10),
  ));
  try {
    final authDatasource = ref.read(firebaseAuthDatasourceProvider);
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = await authDatasource.getIdToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (_) {}
        handler.next(options);
      },
    ));
  } catch (_) {}
  return dio;
});
```

**Reference:** `scoring/providers.dart:22-53` and `teams/providers.dart` (teams uses a different Dio but also has auth via its datasource).

---

### A3. Implement WebSocket Heartbeat (Client-Side Ping)

**Problem:** Server `idleTimeout: 120` seconds. If no delivery is scored for 2 minutes (drinks break, timeout, phone call), viewer WebSocket silently dies. The `WS_HEARTBEAT_INTERVAL_MS` env var is defined in `env.ts` but never used.

**Files to modify:**
- `apps/mobile/lib/src/shared/data/websocket/websocket_client.dart` — Add periodic ping
- `apps/server/src/websocket/handler.ts` — Handle `ping` message type (respond with `pong`)

**Change (client):** Add a `Timer.periodic` that sends `{"type":"ping"}` every 30 seconds while connected. Reset timer on any received message.

**Change (server):** Add `case 'ping':` to the message switch that responds with `{"type":"pong"}`.

---

### A4. Create Release Keystore and Signing Config

**Problem:** `build.gradle.kts:38` uses debug signing. Some Android devices refuse to install debug-signed APKs. Firebase Auth requires the release SHA-1 fingerprint registered in Firebase Console.

**Files to modify:**
- `apps/mobile/android/app/build.gradle.kts` — Already has release signing config (reads `key.properties`)
- `apps/mobile/android/key.properties` — NEW file (gitignored) with keystore path/passwords

**Steps:**
1. Generate keystore: `keytool -genkey -v -keystore cricscores-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias cricscores`
2. Create `key.properties` with keystore path and passwords
3. `build.gradle.kts` already reads `key.properties` — no code changes needed
4. Add SHA-1 + SHA-256 fingerprints to Firebase Console (Project Settings > Your Apps > Add fingerprint)
5. Add `key.properties` and `*.jks` to `.gitignore`

> **See also:** `VPS_DEPLOYMENT_RUNBOOK.md` Phase 7 for the full Firebase production setup (adding prod app, fingerprints, test phone numbers).

### A4b. Firebase Production App Setup (Dev Machine)

**Problem:** Only the dev Android app (`com.cricapp.cricapp`) exists in Firebase project `cricapp-7403d`. The prod flavor (`in.cricscores.app`) needs its own `google-services.json`.

**Steps:**
1. Firebase Console > Project Settings > Add App > Android
2. Package name: `in.cricscores.app`, nickname: `CricScores (Prod)`
3. Download `google-services.json` and place at `apps/mobile/android/app/src/prod/google-services.json`
4. Add release keystore SHA-1 and SHA-256 to the prod app (see A4 above)
5. Verify Phone Auth is enabled with test numbers:
   - `+919999999999` → OTP: `123456` (scorer)
   - `+919999999998` → OTP: `123456` (viewer)

**Server-side:** The same `firebase-service-account.json` (project-level) validates tokens from both dev and prod apps. No server changes needed.

**Flavor config reference:**

| Flavor | applicationId | google-services.json location | Build command |
|--------|--------------|-------------------------------|---------------|
| `dev` | `com.cricapp.cricapp` | `android/app/src/dev/google-services.json` | `flutter run --flavor dev` |
| `prod` | `in.cricscores.app` | `android/app/src/prod/google-services.json` | `flutter run --flavor prod --dart-define=FLAVOR=prod` |

---

### A5. Add `android:usesCleartextTraffic` (Safety Net)

**Problem:** Even with HTTPS via Caddy, the app may make some requests during development/testing that use HTTP. Android 9+ blocks cleartext by default.

**File to modify:**
- `apps/mobile/android/app/src/main/AndroidManifest.xml`

**Change:** Add `android:usesCleartextTraffic="true"` to the `<application>` tag. This is a safety net — primary traffic goes through HTTPS, but this prevents crashes if any HTTP fallback occurs.

---

## CRITICAL — Will cause bad experience without these

### A6. User-Friendly Error Messages

**Problem:** Most pages show raw `error.toString()` which displays Dart exception internals to users (e.g., `DioException [connection timeout]: The connection...`).

**Files to modify:**
- Pages that display `error.toString()`: teams list, tournament list/detail, player profile, team detail
- Consider creating a shared `ErrorDisplayWidget` in `shared/widgets/`

**Change:** Map common error types to friendly messages:
- `NetworkException` / `DioException.connectionTimeout` → "Could not connect. Check your internet and try again."
- `ServerException` with 401 → "Session expired. Please log in again."
- `ServerException` with 500 → "Something went wrong. Please try again."
- Unknown → "An error occurred. Pull down to refresh."

Add a "Retry" button on error states for detail pages (team detail, tournament detail, player profile).

---

### A7. Show Sync Status on Scoring Page

**Problem:** Scorer has no way to know if deliveries are synced to server. If mobile data drops, they keep scoring unaware that viewers see nothing. `SyncStatus` enum exists internally but nothing displays it.

**Files to modify:**
- `apps/mobile/lib/src/features/scoring/presentation/pages/scoring_page.dart`
- `apps/mobile/lib/src/features/scoring/presentation/widgets/sync_status_indicator.dart` (already exists — 15 tests)

**Change:** The `SyncStatusIndicator` widget already exists with cloud icons (green/orange/red). Wire it into the scoring page's `ScoreHeader` or AppBar area so the scorer sees pending/failed sync state.

---

### A8. Increase WebSocket Reconnect Resilience

**Problem:** Max 10 reconnect attempts (~160s total). On flaky mobile data that's unstable for longer periods, viewer permanently disconnects with no recovery.

**File to modify:**
- `apps/mobile/lib/src/core/constants/app_constants.dart`

**Change:** Increase `wsReconnectMaxAttempts` from 10 to 30 (gives ~15 minutes of retry window). Also ensure the "Disconnected" banner's Retry button resets the attempt counter.

---

## NICE TO HAVE — Polish for better experience

### A9. Custom App Icon

**Problem:** App uses default Flutter icon. Friends can't identify it on their home screen.

**Change:** Design a simple cricket-themed icon and use `flutter_launcher_icons` package to generate all densities.

---

### A10. App Label in AndroidManifest

**Problem:** `android:label="CricScores"` (lowercase, no space). Shows as "cricscores" under the icon.

**File:** `apps/mobile/android/app/src/main/AndroidManifest.xml:3`

**Change:** `android:label="CricScores"` (matches the domain branding).

---

### A11. Pull-to-Refresh on Profile Pages

**Problem:** Player Profile and Player Match History pages lack `RefreshIndicator`. If they fail to load, user has no way to retry without navigating away.

**Files:**
- `apps/mobile/lib/src/features/player_profile/presentation/pages/player_profile_page.dart`
- `apps/mobile/lib/src/features/player_profile/presentation/pages/player_match_history_page.dart`

---

## Build Command (after all changes)

```bash
# Production APK (uses prod google-services.json, points to cricscores.in)
cd apps/mobile && flutter build apk --flavor prod --release --dart-define=FLAVOR=prod
```

Output APK: `apps/mobile/build/app/outputs/flutter-apk/app-prod-release.apk`

Share this APK file directly with friends (WhatsApp, Google Drive, etc).

> **Note:** The `--dart-define=FLAVOR=prod` flag makes `AppConstants.isProduction` true, which auto-switches API/WS URLs to `https://cricscores.in/api/v1` and `wss://cricscores.in/ws`. No need to pass `API_BASE_URL`/`WS_BASE_URL` manually.
