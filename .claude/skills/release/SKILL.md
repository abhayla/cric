---
name: release
description: "Guide APK signing, version bumping, release notes, and Play Store preparation. Use when user says 'release', 'build APK', 'sign APK', 'play store', or 'version bump'."
disable-model-invocation: true
allowed-tools: Bash, Read, Write, Edit, Glob
metadata:
  version: 1.0.0
---

# Release — APK Build & Release Workflow

Guide APK signing, version management, and release preparation.

## Arguments

`$ARGUMENTS` can be: `bump <major|minor|patch>`, `build`, or `notes`.

## Steps — Version Bump (`bump`)

1. Read current version from `apps/mobile/pubspec.yaml`:
   ```
   version: X.Y.Z+BUILD
   ```

2. Increment based on argument:
   - `major`: X+1.0.0+BUILD+1
   - `minor`: X.Y+1.0+BUILD+1
   - `patch`: X.Y.Z+1+BUILD+1

3. Update `pubspec.yaml` with new version.

4. Update `apps/mobile/android/app/build.gradle.kts`:
   - `versionCode` = BUILD number
   - `versionName` = "X.Y.Z"

5. Report the version change.

## Steps — Build Release APK (`build`)

1. **Pre-build checks:**
   ```bash
   cd apps/mobile && flutter analyze
   cd apps/mobile && flutter test
   ```

2. **Build release APK:**
   ```bash
   cd apps/mobile && flutter build apk --release
   ```

3. **Verify output:**
   - Check APK size: `ls -lh apps/mobile/build/app/outputs/flutter-apk/app-release.apk`
   - Report APK location and size

4. **Signing reminder:**
   - If keystore not configured, warn user to set up `key.properties`
   - Reference: https://docs.flutter.dev/deployment/android#signing-the-app

## Steps — Release Notes (`notes`)

1. Get commits since last tag:
   ```bash
   git log $(git describe --tags --abbrev=0 2>/dev/null || echo HEAD~20)..HEAD --oneline
   ```

2. Group by type (feat, fix, refactor, etc.)

3. Generate release notes in this format:
   ```
   ## vX.Y.Z — <date>

   ### New Features
   - Feature description

   ### Bug Fixes
   - Fix description

   ### Improvements
   - Improvement description
   ```

4. Present to user for review.
