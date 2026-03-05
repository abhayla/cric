# CricScores Launch Action Plan

**Date:** 2026-03-03
**Status:** All Claude tasks DONE — awaiting human tasks (VPS deploy, Play Console, screenshots)
**Target:** Amateur cricketers in India (friends & local league players)
**Platform:** Android only (`in.cricscores.app`)
**Commit:** `66e0d82` — all C-PC tasks implemented

---

## 1. Current State Audit

| Area | Documented Status | Actual Status | Gap? |
|------|------------------|---------------|------|
| Phases 1-6 | Complete | Complete | No |
| Phase 7 (Polish & Testing) | In progress | 10/10 E2E tests passing, prod APK on real device | No |
| Flutter tests | ~2050 passing | **2255 passing** (post C-PC fixes) | No |
| Server tests | ~420 passing | Confirmed | No |
| `flutter analyze` | Clean | Clean | No |
| `bun run typecheck` | Clean | Clean | No |
| Uncommitted code | None mentioned | Only `Notes` file modified — no source code | No |
| TODO/FIXME/HACK | Not tracked | **1 TODO** in `scoring.service.ts:994` (undo logic comment, non-blocking) | Minimal |
| WebSocket auth (B4) | Was marked BLOCKER | **FIXED** — `handler.ts:175-197` verifies Firebase UID + `verifyScorerForMatch()` per match | Stale doc |
| ProGuard/R8 (B1) | Was marked BLOCKER | **FIXED** — `isMinifyEnabled=true`, `isShrinkResources=true` | Stale doc |
| INTERNET permission (B5) | Was marked BLOCKER | **FIXED** — in `AndroidManifest.xml` | Stale doc |
| CORS (B3) | Was marked BLOCKER | **FIXED** — no wildcard default, `CORS_ORIGIN` required env var | Stale doc |
| Test routes (B2) | Was marked BLOCKER | **FIXED** — `testVerifyRoutes` gated by `NODE_ENV=test`; `testSignalRoutes` always active (safe, no DB mutation) | Stale doc |
| Super Over server sync | Known non-blocking | SyncService logs "Match must be in live status" during SO — client works offline-first | Acceptable |
| Match deletion | Not mentioned | **FIXED** (C-PC-1) — server soft-delete + Flutter UI. Migration `0009` pending on VPS. | Fixed |
| Match resumption prompt | Not mentioned | **FIXED** (C-PC-2) — `_ResumeBanner` on home page reads Drift snapshots | Fixed |
| Error messages | Not mentioned | **FIXED** (C-PC-3) — `toUserFriendlyMessage()` applied to all 8 SnackBars | Fixed |
| Roster fetch failure | Not mentioned | **FIXED** (C-PC-4) — shows error + stays on match setup | Fixed |
| Player editing | Not mentioned | **DEFERRED** — cannot change player role/style after creation (delete + re-add workaround) | P2 |
| Tournament deletion | Not mentioned | **DEFERRED** — cannot delete/cancel a tournament at any stage | P2 |
| Privacy Policy | Not mentioned | **FIXED** (C-PC-7) — `docs/pre-prod/privacy.html` created. Needs deploy to Nginx. | Fixed |
| Store listing assets | Not mentioned | **PARTIAL** — listing text done (C-PC-9). Screenshots, icon, feature graphic still TODO. | Partial |
| App signing key | Configured | `cricscores-release.jks` exists, `key.properties` populated | No |
| Launcher icons | Not mentioned | Custom icons present in all `mipmap-*` densities | No |
| targetSdkVersion | Not verified | **36** (Flutter 3.41.2 default) — exceeds Play Store minimum of 34 | No |
| minSdkVersion | 23 documented | **24** (Flutter 3.41.2 default) — fine | Minor doc gap |

**All 5 prior BLOCKERS (B1-B5) from the Feb 23 production readiness scan are FIXED.** The `PRODUCTION_READINESS_SCAN.md` document is stale.

---

## 2. Launch Blockers

### P0 — Ship-Blocking (app crashes, data loss, security, Play Store rejection)

| # | Issue | Detail | Evidence |
|---|-------|--------|----------|
| P0-1 | **Privacy Policy missing** | Google Play rejects apps without a privacy policy URL. Firebase Auth collects phone numbers — disclosure required. | DONE — `docs/pre-prod/privacy.html` created (C-PC-7). Needs deploy to `cricscores.in/privacy`. |
| P0-2 | **Play Store listing assets missing** | Cannot submit without: app icon (512x512), feature graphic (1024x500), 2+ screenshots, short/long description | PARTIAL — `docs/pre-prod/play-store-listing.md` created (C-PC-9). Still need: screenshots, icon 512x512, feature graphic. |
| P0-3 | **Play Store developer account** | Need a Google Play Developer account ($25 one-time) to submit | Abhay TODO |
| P0-4 | **Upload signing key** | Play App Signing requires uploading the key or using Google-managed signing. Current `cricscores-release.jks` is self-signed. | Signing files verified in `.gitignore` (C-PC-11). Enrollment is Abhay TODO. |
| P0-5 | **No match deletion** | User creates match with wrong teams — it sits in match list forever. No `deleteMatch()` in repository, no server endpoint, no UI. | DONE (C-PC-1) — server soft-delete + migration `0009` + Flutter UI with confirmation dialog. Needs `bun run db:migrate` on VPS. |
| P0-6 | **No "Resume Match" prompt after crash/restart** | Scoring is the core feature. App crashes mid-match, user reopens to home page with no indication of incomplete match. State IS saved to Drift but never checked on startup. | DONE (C-PC-2) — `_ResumeBanner` on home page with RESUME/DISMISS. Reads Drift snapshots, reconstructs `ScoringPageArgs`. |

### P1 — Day-1 Critical (broken/missing but won't block store listing)

| # | Issue | Detail |
|---|-------|--------|
| P1-1 | **Raw exception strings shown to users** | `catch (e)` blocks show `"Failed to create team: $e"` — users see `Connection refused`, `SocketException`, etc. | DONE (C-PC-3) — `toUserFriendlyMessage()` in `exceptions.dart`, 8 SnackBars updated. |
| P1-2 | **Roster fetch failure = dead end at toss** | If server unreachable during match start, code catches error silently, navigates to toss with empty rosters. | DONE (C-PC-4) — shows error SnackBar + `return;` stays on match setup page. |
| P1-3 | **Unguarded `debugPrint`/`print` in release** | `router.dart` and `tournament_detail_page.dart` leak to logcat. | DONE (C-PC-5) — 8 calls wrapped in `kDebugMode`. |
| P1-4 | **VPS NODE_ENV verification** | Must confirm `.env` on VPS has `NODE_ENV=production` so `testVerifyRoutes` don't load | Abhay TODO |
| P1-5 | **Logo upload fails silently** | `router.dart` — `catch (_)` swallows logo upload error. Team creates without logo, user unaware. | DONE (C-PC-6) — shows "Team created, but logo upload failed." SnackBar. |

### P2 — Fast-Follow (ship without, fix within first week)

| # | Issue | Detail |
|---|-------|--------|
| P2-1 | **Super Over server sync** | SyncService errors during SO scoring — client works offline-first, no data loss |
| P2-2 | **Firebase Crashlytics** | No crash reporting in production — blind to user issues |
| P2-3 | **Rate limiting** | No per-endpoint rate limits on API — acceptable for friend-testing scale |
| P2-4 | **`PRODUCTION_READINESS_SCAN.md` stale** | Document shows B1-B5 as blockers but all are fixed — confusing for future sessions |
| P2-5 | **No player editing** | Cannot change player role/bowling style after creation. Workaround: delete + re-add. |
| P2-6 | **No tournament deletion** | Cannot delete/cancel a tournament at any stage. Test tournaments sit forever. |
| P2-7 | **Local persistence errors not surfaced** | `scoring_persistence_service.dart` stores error in `_lastSaveError` but never shows UI indicator. If Drift save fails, user unaware. |
| P2-8 | **SMS retriever error unhandled** | `firebase_auth_datasource.dart:82-86` — fire-and-forget with no `.catchError()`. Auto-OTP silently degrades. |

---

## 3. Cut List — Explicitly Deferred to Post-Launch

| Planned Item | Why Safe to Cut | User Impact |
|-------------|----------------|-------------|
| Spectator live test (`spectator_live_test.dart`) | E2E test 08 already validates multi-device. Spectator is a testing concern, not a user feature. | None — public Live tab works, just no automated test for non-team viewers |
| Server-side super over support | Client scores super overs offline-first. Sync error is logged but no data loss. | Super over results don't sync to server until fixed — local device has correct data |
| Remaining E2E coverage (scorecard deep verification, analytics charts, updates feed, remove player) | Core flows (scoring, tournaments, teams) all tested. These are verification-depth gaps, not functional gaps. | None — features work, just less automated test coverage |
| `ListView.builder` migration (C6 from scan) | Only affects scroll performance with very large lists. Amateur leagues have <50 teams, <20 tournaments. | Negligible for target audience size |
| Certificate pinning | Only matters for man-in-the-middle attacks. Cloudflare SSL + domain validation is sufficient for friend-testing. | None for amateur cricket app |
| Database SSL | PostgreSQL on VPS is localhost-only (port 5432 firewalled). No external DB access possible. | None |
| iOS support | Explicitly out of scope — Android-only MVP | No iOS users |
| Match editing after creation | Abandon + recreate workaround exists. Rare scenario — users usually get settings right. | Minor inconvenience |
| Concurrent scoring lock | Amateur cricket: one scorer per match on one phone. `verifyScorerForMatch()` already validates per-match auth. | Theoretical risk only |
| Player on two opposing teams validation | Edge case. Users manage their own teams. No validation but also no real-world scenario. | None expected |
| Tournament match rescheduling | Fixtures are fixed once generated. Abandon match + create manually if needed. | Workaround exists |

---

## 4. Sprint Plan — Grouped by Who + Where

### Claude Code — On Local PC

**App Code Fixes (P0/P1):**

| # | Task | Effort | Status | Key Changes |
|---|------|--------|--------|-------------|
| C-PC-1 | **Add match deletion** | M | DONE | Server: `deletedAt` column + migration `0009` + `deleteMatch()` service + `DELETE /:id` route + soft-delete filter on `getMatches`/`getMatch`. Flutter: repository/datasource/impl + `PopupMenuButton` on `MatchCard` + confirmation dialog in home page. |
| C-PC-2 | **Resume Match prompt** | M | DONE | `resumableMatchIdsProvider` in `providers.dart`. `_ResumeBanner` widget in `home_page.dart` — RESUME reconstructs `ScoringPageArgs` from Drift state, DISMISS clears snapshot. |
| C-PC-3 | **User-friendly error messages** | S | DONE | `toUserFriendlyMessage()` in `exceptions.dart`. `ErrorDisplay` refactored to use it (DRY). 8 SnackBars updated in `router.dart` (4) and `tournament_detail_page.dart` (4). |
| C-PC-4 | **Fix roster fetch dead end** | S | DONE | `router.dart` — error SnackBar + `return;` on roster fetch failure. User stays on match setup. |
| C-PC-5 | **Guard debugPrint/print** | S | DONE | 1 call in `router.dart` + 7 calls in `tournament_detail_page.dart` wrapped in `kDebugMode`. |
| C-PC-6 | **Logo upload failure SnackBar** | S | DONE | Silent `catch (_)` → `catch (e)` with SnackBar "Team created, but logo upload failed." |

**Store/Deployment Assets:**

| # | Task | Effort | Status | Output |
|---|------|--------|--------|--------|
| C-PC-7 | Privacy Policy HTML | S | DONE | `docs/pre-prod/privacy.html` — standalone HTML5, covers Firebase Auth, data storage, no ads, 13+ |
| C-PC-8 | Terms of Service HTML | S | DONE | `docs/pre-prod/terms.html` — standalone HTML5, India governing law |
| C-PC-9 | Play Store listing text | S | DONE | `docs/pre-prod/play-store-listing.md` — short desc (57 chars), full desc (~1960 chars), tags |
| C-PC-10 | Build signed release AAB | S | READY | Pre-flight passed: `flutter analyze` 0 issues, 2255/2255 tests pass, `bun run typecheck` clean. Build command: `flutter build appbundle --flavor prod --release --dart-define=FLAVOR=prod` |
| C-PC-11 | Back up signing key | S | VERIFIED | `cricscores-release.jks` + `key.properties` exist, both in `.gitignore`. Manual backup to safe location is Abhay TODO. |

**Claude total: COMPLETE** (all 11 tasks done in commit `66e0d82`)

### Claude Code — On VPS (`103.118.16.189`)

_Nothing. Claude does not have direct VPS access. All VPS tasks are human-executed._

### Abhay (Human) — On Local PC

| # | Task | Effort | Depends On | Acceptance Criteria |
|---|------|--------|------------|-------------------|
| H-PC-1 | Create Google Play Developer account | S | Nothing | TODO | Account active at `play.google.com/console` ($25 fee) |
| H-PC-2 | Take 4-6 app screenshots | M | AAB built | TODO | Screenshots of: Login, Home/My Cricket, Live Scoring, Scorecard, Tournament, Team Detail |
| H-PC-3 | Create 512x512 app icon PNG | S | Nothing | TODO | High-res export of existing launcher icon |
| H-PC-4 | Create 1024x500 feature graphic | S | Nothing | TODO | Banner with app name + tagline + cricket imagery |
| H-PC-5 | Create app in Play Console | S | H-PC-1 | TODO | App listing created for `in.cricscores.app` |
| H-PC-6 | Enroll in Play App Signing | S | H-PC-5 | TODO | Upload `cricscores-release.jks`, enable Play-managed signing |
| H-PC-7 | Upload AAB to internal testing track | S | H-PC-6 | TODO | AAB uploaded, internal testing track active |
| H-PC-8 | Complete content rating questionnaire | S | H-PC-5 | TODO | IARC rating obtained (likely "Everyone") |
| H-PC-9 | Fill Data Safety form | S | H-PC-5 | TODO | Declare: phone number (Firebase Auth), match data (server), no ads, no third-party sharing |
| H-PC-10 | Fill store listing (all fields) | M | H-PC-2/3/4, H-VPS-2 | TODO | Title, descriptions, screenshots, icon, feature graphic, privacy policy URL, category, content rating — all filled |
| H-PC-11 | Provide test credentials in "App access" | S | H-PC-5 | TODO | Test phone + OTP documented for Google reviewer |
| H-PC-12 | Submit for internal testing | S | H-PC-7, H-PC-10 | TODO | Friends can install via Play Store internal testing link |
| H-PC-13 | Promote to production after friend-testing | S | H-PC-12 + 1-3 days | TODO | App publicly available on Google Play |

**Human (PC) total: ~3-4 hours** (spread across days due to review wait)

### Abhay (Human) — On VPS (`103.118.16.189`)

| # | Task | Effort | Depends On | Acceptance Criteria |
|---|------|--------|------------|-------------------|
| H-VPS-1 | Verify `NODE_ENV=production` in `.env` | S | Nothing | TODO | `curl https://cricscores.in/api/v1/health` shows production mode. |
| H-VPS-2 | **Run `bun run db:migrate`** (applies `0009_match_soft_delete.sql`) | S | Nothing | TODO | `deleted_at` column added to `matches` table. |
| H-VPS-3 | **Deploy server** (pull latest, restart PM2) | S | H-VPS-2 | TODO | `DELETE /api/v1/matches/:id` endpoint active. |
| H-VPS-4 | Deploy privacy + terms pages to Nginx | S | C-PC-7, C-PC-8 (DONE) | TODO | `https://cricscores.in/privacy` and `https://cricscores.in/terms` return the HTML pages. |
| H-VPS-5 | Verify health monitoring is active | S | Nothing | TODO | `health-check.ps1` scheduled task running every 5 min. PM2 process `cricscores` is online. |
| H-VPS-6 | Verify DB backup job | S | Nothing | TODO | `backup-db.bat` scheduled at 3 AM. At least 1 recent backup exists in backup dir. |

**Human (VPS) total: ~30 minutes**

### Estimated Remaining Timeline

| Track | Duration | Status |
|-------|----------|--------|
| Claude on PC — code fixes (C-PC-1 to C-PC-6) | ~1 day | DONE |
| Claude on PC — assets (C-PC-7 to C-PC-11) | ~1-2 hours | DONE |
| Human on VPS (H-VPS-1 to H-VPS-6) | ~30 minutes | TODO |
| Human on PC (pre-submission: screenshots, icons, Play Console) | ~3-4 hours | TODO |
| Human on PC (submission + review) | 1-7 days | TODO |
| **Remaining hands-on work** | **~4 hours + VPS** | |
| **Google review time** | **1-7 days** (typically 1-3 for new apps) | |

---

## 5. Play Store Checklist

| Requirement | Status | Action Needed |
|-------------|--------|---------------|
| **Google Play Developer Account** | TODO | Abhay: create at `play.google.com/console` ($25) |
| **App Bundle (AAB)** | READY TO BUILD | `flutter build appbundle --flavor prod --release --dart-define=FLAVOR=prod` (pre-flight passed) |
| **App Signing** | JKS verified in `.gitignore` | Enroll in Play App Signing, upload `cricscores-release.jks` |
| **Package name** | `in.cricscores.app` | Ready |
| **Version** | `1.0.0` (versionCode 1) | Ready |
| **targetSdkVersion** | 36 | Exceeds Play Store minimum (34) |
| **minSdkVersion** | 24 | Covers 99%+ of Indian Android devices |
| **App icon (512x512)** | Custom icon exists in mipmap dirs | Need high-res 512x512 PNG export for store |
| **Feature graphic (1024x500)** | TODO | Create — can be simple branded banner |
| **Screenshots (min 2, max 8)** | TODO | Take 4-6 on emulator or real device |
| **Short description (80 chars)** | DONE | `docs/pre-prod/play-store-listing.md` (57 chars) |
| **Full description (4000 chars)** | DONE | `docs/pre-prod/play-store-listing.md` (~1960 chars) |
| **App category** | DONE | "Sports" — in listing doc |
| **Content rating (IARC)** | TODO | Complete questionnaire — likely "Everyone" |
| **Privacy policy URL** | DONE (file) / TODO (deploy) | `docs/pre-prod/privacy.html` created. Deploy to `cricscores.in/privacy` via Nginx. |
| **Terms of Service** | DONE (file) / TODO (deploy) | `docs/pre-prod/terms.html` created. Deploy to `cricscores.in/terms` via Nginx. |
| **Data safety form** | TODO | Declare: phone number (Firebase Auth), match data (server), no ads, no third-party data sharing |
| **Target audience** | TODO | 13+ (sports app, no sensitive content) |
| **App access** | TODO | Provide test phone + OTP in "App access" section for Google reviewer |
| **ProGuard/R8** | DONE | Enabled |
| **64-bit support** | DONE | Default in Flutter |
| **Permissions declared** | DONE | INTERNET only |
| **Adaptive icon** | DONE | Standard mipmap icons — acceptable |

---

## 6. Risk Register

| # | Risk | Likelihood | Impact | Mitigation |
|---|------|-----------|--------|------------|
| **R1** | **Google Play rejects due to Firebase test phone numbers** — reviewer can't log in with real phone, and test numbers (999...) may look suspicious | Medium | High — blocks launch | In Play Console "App access" section, provide a test phone number + OTP. Add a note explaining Firebase test auth. Alternatively, temporarily add the reviewer's phone to Firebase test numbers. |
| **R2** | **VPS downtime during review** — if `cricscores.in` is down when the reviewer tests, app shows errors and gets rejected | Medium | High — delays launch | Verify VPS health monitoring is active (`health-check.ps1` runs every 5 min). Test the health endpoint before submitting. Consider adding a visible "Server unreachable, working offline" message in the app. |
| **R3** | **Play Store review takes longer than expected** — new developer accounts sometimes get extra scrutiny | Medium | Medium — delays launch by days | Submit to **internal testing** first (no review needed), get friends testing immediately. Promote to open/production testing in parallel. |
| **R4** | **Key loss** — if `cricscores-release.jks` is lost, cannot update the app on Play Store ever | Low | Critical — permanent | Back up `cricscores-release.jks` and `key.properties` to a secure location (cloud drive, USB). Once enrolled in Play App Signing, Google keeps a copy. |
| **R5** | **Server can't handle concurrent users** — no load testing done, VPS is a single Windows Server instance | Low (for friend-testing) | Medium | Acceptable for 10-50 concurrent users. PostgreSQL connection pool configured at 10. Add monitoring of PM2 process memory/CPU. Defer proper load testing to post-launch. |

---

## Summary: Critical Path to Launch

```
DONE — Claude Code (commit 66e0d82):
  [x] C-PC-1: Match deletion (server + Flutter)
  [x] C-PC-2: Resume match prompt
  [x] C-PC-3: User-friendly error messages
  [x] C-PC-4: Fix roster fetch dead end
  [x] C-PC-5: Guard debugPrint/print
  [x] C-PC-6: Logo upload failure SnackBar
  [x] C-PC-7: Privacy policy HTML
  [x] C-PC-8: Terms of service HTML
  [x] C-PC-9: Play Store listing text
  [x] C-PC-10: Pre-flight checks passed (analyze, tests, typecheck)
  [x] C-PC-11: Signing key verified in .gitignore

NEXT — Abhay on VPS:
  [ ] H-VPS-1: Verify NODE_ENV=production
  [ ] H-VPS-2: Run `bun run db:migrate` (migration 0009)
  [ ] H-VPS-3: Deploy server (git pull + pm2 restart)
  [ ] H-VPS-4: Deploy privacy.html + terms.html to Nginx
  [ ] H-VPS-5: Verify health monitoring
  [ ] H-VPS-6: Verify DB backup

NEXT — Abhay on PC:
  [ ] Build AAB: flutter build appbundle --flavor prod --release --dart-define=FLAVOR=prod
  [ ] Back up cricscores-release.jks + key.properties to safe location
  [ ] Take 4-6 screenshots (Login, Home, Scoring, Scorecard, Tournament, Team)
  [ ] Create 512x512 app icon + 1024x500 feature graphic
  [ ] Create Google Play Developer account ($25)
  [ ] Create app + enroll in Play App Signing
  [ ] Upload AAB + fill store listing + submit for internal testing

THEN:
  [ ] Friends test via internal testing link (1-3 days)
  [ ] Promote to production -> Google review -> app live
```

**Bottom line:** All code work is done. The app is functionally complete with 2255 passing tests, 0 analyzer issues, and all 6 user-facing gaps (match deletion, crash recovery, error messages, roster fix, debug guards, logo SnackBar) addressed. Remaining work is purely operational: VPS deployment (~30 min), asset creation (~2 hrs), and Play Console submission (~2 hrs).
