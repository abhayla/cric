# CricScores Launch Action Plan

**Date:** 2026-03-03
**Status:** Ready for Play Store submission pipeline
**Target:** Amateur cricketers in India (friends & local league players)
**Platform:** Android only (`in.cricscores.app`)

---

## 1. Current State Audit

| Area | Documented Status | Actual Status | Gap? |
|------|------------------|---------------|------|
| Phases 1-6 | Complete | Complete | No |
| Phase 7 (Polish & Testing) | In progress | 10/10 E2E tests passing, prod APK on real device | No |
| Flutter tests | ~2050 passing | Confirmed | No |
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
| Match deletion | Not mentioned | **MISSING** — no `deleteMatch()` in repository, no server endpoint, no UI | Gap |
| Match resumption prompt | Not mentioned | **MISSING** — Drift saves state, but no startup check or "Resume Match?" dialog | Gap |
| Error messages | Not mentioned | **Raw exception strings** shown to users (`"Failed to create team: Connection refused"`) | Gap |
| Roster fetch failure | Not mentioned | **Silent failure** — toss page proceeds with empty rosters, user stuck | Gap |
| Player editing | Not mentioned | **MISSING** — cannot change player role/style after creation (delete + re-add workaround) | Gap |
| Tournament deletion | Not mentioned | **MISSING** — cannot delete/cancel a tournament at any stage | Gap |
| Privacy Policy | Not mentioned | **MISSING** — no policy files anywhere | Gap |
| Store listing assets | Not mentioned | **MISSING** — no screenshots, description, feature graphic | Gap |
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
| P0-1 | **Privacy Policy missing** | Google Play rejects apps without a privacy policy URL. Firebase Auth collects phone numbers — disclosure required. | No `privacy*` or `policy*` files in codebase |
| P0-2 | **Play Store listing assets missing** | Cannot submit without: app icon (512x512), feature graphic (1024x500), 2+ screenshots, short/long description | No assets found under `docs/` or project root |
| P0-3 | **Play Store developer account** | Need a Google Play Developer account ($25 one-time) to submit | Unknown if Abhay has one |
| P0-4 | **Upload signing key** | Play App Signing requires uploading the key or using Google-managed signing. Current `cricscores-release.jks` is self-signed. | `key.properties` exists but Play App Signing enrollment unknown |
| P0-5 | **No match deletion** | User creates match with wrong teams — it sits in match list forever. No `deleteMatch()` in repository, no server endpoint, no UI. | `MatchRepository` has only `createMatch()` |
| P0-6 | **No "Resume Match" prompt after crash/restart** | Scoring is the core feature. App crashes mid-match, user reopens to home page with no indication of incomplete match. State IS saved to Drift but never checked on startup. | No resume detection code in home page or router |

### P1 — Day-1 Critical (broken/missing but won't block store listing)

| # | Issue | Detail |
|---|-------|--------|
| P1-1 | **Raw exception strings shown to users** | `catch (e)` blocks show `"Failed to create team: $e"` — users see `Connection refused`, `SocketException`, etc. Affects `router.dart:349,418`, `tournament_detail_page.dart:74`. |
| P1-2 | **Roster fetch failure = dead end at toss** | If server unreachable during match start, `router.dart:456-486` catches error silently, navigates to toss with empty rosters. User sees toss wizard but can't select players. |
| P1-3 | **Unguarded `debugPrint`/`print` in release** | `router.dart:484` and possibly others leak to logcat. Not user-visible but unprofessional. |
| P1-4 | **VPS NODE_ENV verification** | Must confirm `.env` on VPS has `NODE_ENV=production` so `testVerifyRoutes` don't load |
| P1-5 | **Logo upload fails silently** | `router.dart:332-337` — `catch (_)` swallows logo upload error. Team creates without logo, user unaware it failed. |

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

| # | Task | Effort | Depends On | Acceptance Criteria |
|---|------|--------|------------|-------------------|
| C-PC-1 | **Add match deletion** — server endpoint (soft-delete for `setup`/`toss` status only) + Flutter repository method + UI button on match card/detail | M | Nothing | User can delete a match that hasn't started scoring. Server returns 400 if match has deliveries. E2E or manual verification. |
| C-PC-2 | **Add "Resume Match" prompt on startup** — query `ScoringDao` for active sessions on home page mount, show banner/dialog linking to scoring page with `resume()` | M | Nothing | After app crash mid-match, reopening app shows "You have an incomplete match — Resume?" banner on home page. Tapping navigates to scoring page. |
| C-PC-3 | **User-friendly error messages** — create shared `userFriendlyError(dynamic e)` mapping `DioException` types to readable strings. Apply to all `catch (e)` SnackBars in `router.dart` and `tournament_detail_page.dart`. | S | Nothing | All API error SnackBars show "No internet connection" / "Server unavailable" / "Please try again" instead of raw exceptions. |
| C-PC-4 | **Fix roster fetch failure dead end** — show error SnackBar and stay on match setup if roster fetch fails, instead of navigating to toss with empty rosters | S | Nothing | When server is unreachable, user sees "Could not load team rosters" error and stays on match setup page. |
| C-PC-5 | **Guard all `debugPrint`/`print` in `lib/`** | S | Nothing | All debug logging wrapped in `kDebugMode`. `flutter analyze` clean. |
| C-PC-6 | **Add SnackBar for logo upload failure** | S | Nothing | `router.dart:332-337` shows "Team created, but logo upload failed" SnackBar instead of silent `catch (_)`. |

**Store/Deployment Assets:**

| # | Task | Effort | Depends On | Acceptance Criteria |
|---|------|--------|------------|-------------------|
| C-PC-7 | Create Privacy Policy HTML page | S | Nothing | `privacy.html` ready to deploy, covers Firebase Auth phone collection, match data storage, no third-party sharing |
| C-PC-8 | Create Terms of Service HTML page | S | Nothing | `terms.html` ready to deploy |
| C-PC-9 | Write Play Store listing text | S | Nothing | Short description (80 chars) + full description (4000 chars max) in a text file |
| C-PC-10 | Build signed release AAB | S | C-PC-1 to C-PC-6 | `flutter build appbundle --flavor prod --release --dart-define=FLAVOR=prod` succeeds |
| C-PC-11 | Back up signing key | S | Nothing | Copy `cricscores-release.jks` + `key.properties` to a safe backup location |

**Claude total: ~1 day** (C-PC-1 and C-PC-2 are M-sized; rest are S)

### Claude Code — On VPS (`103.118.16.189`)

_Nothing. Claude does not have direct VPS access. All VPS tasks are human-executed._

### Abhay (Human) — On Local PC

| # | Task | Effort | Depends On | Acceptance Criteria |
|---|------|--------|------------|-------------------|
| H-PC-1 | Create Google Play Developer account | S | Nothing | Account active at `play.google.com/console` ($25 fee) |
| H-PC-2 | Take 4-6 app screenshots | M | C-PC-5 (AAB built) | Screenshots of: Login, Home/My Cricket, Live Scoring, Scorecard, Tournament, Team Detail |
| H-PC-3 | Create 512x512 app icon PNG | S | Nothing | High-res export of existing launcher icon |
| H-PC-4 | Create 1024x500 feature graphic | S | Nothing | Banner with app name + tagline + cricket imagery |
| H-PC-5 | Create app in Play Console | S | H-PC-1 | App listing created for `in.cricscores.app` |
| H-PC-6 | Enroll in Play App Signing | S | H-PC-5 | Upload `cricscores-release.jks`, enable Play-managed signing |
| H-PC-7 | Upload AAB to internal testing track | S | C-PC-5, H-PC-6 | AAB uploaded, internal testing track active |
| H-PC-8 | Complete content rating questionnaire | S | H-PC-5 | IARC rating obtained (likely "Everyone") |
| H-PC-9 | Fill Data Safety form | S | H-PC-5 | Declare: phone number (Firebase Auth), match data (server), no ads, no third-party sharing |
| H-PC-10 | Fill store listing (all fields) | M | H-PC-2/3/4, C-PC-4, H-VPS-2 | Title, descriptions, screenshots, icon, feature graphic, privacy policy URL, category, content rating — all filled |
| H-PC-11 | Provide test credentials in "App access" | S | H-PC-5 | Test phone + OTP documented for Google reviewer |
| H-PC-12 | Submit for internal testing | S | H-PC-7, H-PC-10 | Friends can install via Play Store internal testing link |
| H-PC-13 | Promote to production after friend-testing | S | H-PC-12 + 1-3 days | App publicly available on Google Play |

**Human (PC) total: ~3-4 hours** (spread across days due to review wait)

### Abhay (Human) — On VPS (`103.118.16.189`)

| # | Task | Effort | Depends On | Acceptance Criteria |
|---|------|--------|------------|-------------------|
| H-VPS-1 | Verify `NODE_ENV=production` in `.env` | S | Nothing | `curl https://cricscores.in/api/v1/health` shows production mode. `GET /api/v1/test/verify/...` returns 404. |
| H-VPS-2 | Deploy privacy + terms pages to Nginx | S | C-PC-2, C-PC-3 | `https://cricscores.in/privacy` and `https://cricscores.in/terms` return the HTML pages |
| H-VPS-3 | Verify health monitoring is active | S | Nothing | `health-check.ps1` scheduled task running every 5 min. PM2 process `cricscores` is online. |
| H-VPS-4 | Verify DB backup job | S | Nothing | `backup-db.bat` scheduled at 3 AM. At least 1 recent backup exists in backup dir. |

**Human (VPS) total: ~30 minutes**

### Estimated Timeline

| Track | Duration | Can Parallelize? |
|-------|----------|-----------------|
| Claude on PC — code fixes (C-PC-1 to C-PC-6) | ~1 day | C-PC-1 and C-PC-2 are M-sized; C-PC-3 to C-PC-6 are quick |
| Claude on PC — assets (C-PC-7 to C-PC-11) | ~1-2 hours | After code fixes, or parallel where independent |
| Human on VPS | ~30 minutes | Yes — parallel with Claude on PC |
| Human on PC (pre-submission) | ~3-4 hours | After Claude + VPS tasks done |
| Human on PC (submission + review) | 1-7 days | Sequential — submit, wait for review |
| **Total hands-on work** | **~2 days** | |
| **Google review time** | **1-7 days** (typically 1-3 for new apps) | |

---

## 5. Play Store Checklist

| Requirement | Status | Action Needed |
|-------------|--------|---------------|
| **Google Play Developer Account** | Unknown | Abhay: create at `play.google.com/console` ($25) |
| **App Bundle (AAB)** | Not built yet | Build with `flutter build appbundle --flavor prod --release --dart-define=FLAVOR=prod` |
| **App Signing** | Self-signed JKS exists | Enroll in Play App Signing, upload `cricscores-release.jks` |
| **Package name** | `in.cricscores.app` | Ready |
| **Version** | `1.0.0` (versionCode 1) | Ready |
| **targetSdkVersion** | 36 | Exceeds Play Store minimum (34) |
| **minSdkVersion** | 24 | Covers 99%+ of Indian Android devices |
| **App icon (512x512)** | Custom icon exists in mipmap dirs | Need high-res 512x512 PNG export for store |
| **Feature graphic (1024x500)** | Missing | Create — can be simple branded banner |
| **Screenshots (min 2, max 8)** | Missing | Take 4-6 on emulator or real device |
| **Short description (80 chars)** | Missing | Write |
| **Full description (4000 chars)** | Missing | Write |
| **App category** | Not set | "Sports" |
| **Content rating (IARC)** | Not done | Complete questionnaire — likely "Everyone" |
| **Privacy policy URL** | Missing | Create page, host at `cricscores.in/privacy` |
| **Terms of Service** | Missing | Create page, host at `cricscores.in/terms` |
| **Data safety form** | Not done | Declare: phone number (Firebase Auth), match data (server), no ads, no third-party data sharing |
| **Target audience** | Not set | 13+ (sports app, no sensitive content) |
| **App access** | Phone OTP login | May need test credentials for reviewers — provide test phone in "App access" section |
| **ProGuard/R8** | Enabled | Ready |
| **64-bit support** | Default in Flutter | Ready |
| **Permissions declared** | INTERNET only | Ready |
| **Adaptive icon** | Standard mipmap icons | Acceptable — adaptive icon is recommended but not required |

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
Day 1 — Code fixes (parallel with human prep):
  CLAUDE ON PC                          ABHAY ON VPS              ABHAY ON PC
  +-- Add match deletion (P0-5)         +-- Verify NODE_ENV       +-- Create Play Developer account ($25)
  +-- Add resume match prompt (P0-6)    +-- Verify health monitor +-- Create app icon 512x512
  +-- User-friendly error messages      +-- Verify DB backup      +-- Create feature graphic 1024x500
  +-- Fix roster fetch dead end
  +-- Guard debugPrint/print
  +-- Logo upload failure SnackBar

Day 2 — Assets + build:
  CLAUDE ON PC                          ABHAY ON PC
  +-- Create privacy.html               +-- Take 4-6 screenshots
  +-- Create terms.html
  +-- Write store listing text
  +-- Build signed AAB
  +-- Back up signing key

Day 3 — Submission:
  ABHAY ON VPS                          ABHAY ON PC
  +-- Deploy privacy/terms to Nginx     +-- Create app in Play Console
                                        +-- Enroll in Play App Signing
                                        +-- Upload AAB to internal testing
                                        +-- Fill all store listing fields
                                        +-- Submit for internal testing
                                           (friends can install immediately)

Day 4-7:
  +-- Friends test via internal testing link

Day 7-14:
  +-- [Abhay] Promote to production -> Google review -> app live
```

**Bottom line:** The app is functionally complete and well-tested. Six code fixes are needed (2 medium, 4 small) to address user-facing gaps — match deletion, crash recovery prompt, error messages, and minor polish. After ~2 days of Claude code work + Play Store asset prep, you're ready to submit.
