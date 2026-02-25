# Updates Tab Features

CricHeroes comparison analysis for the Updates/Activity Feed screen. Based on CricHeroes (40M+ users) competitive research.

## Currently Implemented in CricScores

| Feature | Status |
|---------|--------|
| Activity feed with grouped dates (Today/Yesterday/This Week/Earlier) | Done |
| Colored event-type icons (match=green, team=blue, tournament=orange) | Done |
| Unread dot indicator + bold title for unread items | Done |
| Tap to navigate to referenced entity | Done |
| Mark-as-read on tap | Done |
| Pull-to-refresh | Done |
| Error state with retry | Done |
| Empty state (bell icon + "No Updates Yet") | Done |
| 3 server event emitters (match_completed, player_added, tournament_update) | Done |

### Relevant Files

- `apps/mobile/lib/src/features/updates/domain/entities/activity_event.dart` - Entity with 5 event types
- `apps/mobile/lib/src/features/updates/presentation/pages/updates_page.dart` - Feed page with grouping and navigation
- `apps/mobile/lib/src/features/updates/presentation/widgets/activity_event_card.dart` - List tile card with colored icons and unread dot
- `apps/mobile/lib/src/features/updates/providers.dart` - `activityFeedProvider` and `unreadCountProvider`
- `apps/server/src/services/activity-feed.service.ts` - 3 event emitters
- `apps/server/src/routes/v1/activity-feed.ts` - 3 endpoints: GET `/`, POST `/read`, GET `/unread-count`
- `apps/server/src/db/schema/activity-feed.ts` - `activity_feed` table schema

---

## ADOPT - Implement Now (Low Effort)

### 1. Nav Tab Unread Badge
- **Description:** Show numeric red badge on Updates tab icon using existing `unreadCountProvider`
- **Effort:** Trivial
- **Details:** `unreadCountProvider` already fetches count from server. Need to `ref.watch(unreadCountProvider)` in bottom nav widget and render a Material 3 `Badge` widget on the Updates tab icon.

### 2. Pagination / Infinite Scroll
- **Description:** Server already supports `page`/`limit` params - wire up `ScrollController` to load more
- **Effort:** Small
- **Details:** `UpdatesRepository` interface already has `page` and `limit` params. `activityFeedProvider` currently only fetches page 1. Need to change from `FutureProvider` to `AsyncNotifier` that accumulates pages. Detect scroll within 200px of bottom to trigger next page load.

### 3. Mark-All-As-Read
- **Description:** AppBar overflow menu action + server endpoint
- **Effort:** Small
- **Details:** Add overflow menu item in AppBar ("Mark all read"). Server: extend `POST /activity-feed/read` to accept empty array as mark-all signal, or add dedicated `POST /activity-feed/read-all` endpoint. Invalidate both `activityFeedProvider` and `unreadCountProvider` after action.

### 4. team_joined Event Emitter
- **Description:** Entity already has the `team_joined` case - need to wire emitter in `team.service.ts` on roster add
- **Effort:** Trivial
- **Details:** `ActivityEvent` entity already handles `team_joined` in its `iconType` switch. Server `team.service.ts` needs to call event emitter when a player is added to a roster. Check if `emitPlayerAddedEvents` covers this path or if a new emitter is needed.

### 5. Swipe-to-Delete
- **Description:** Allow dismissing individual notifications with `Dismissible` widget
- **Effort:** Small
- **Details:** Wrap `ActivityEventCard` in `Dismissible` with red background and delete icon. Server needs `DELETE /activity-feed/:id` endpoint. Show SnackBar with "Undo" action.

### 6. Relative Timestamps
- **Description:** "2 min ago", "1 hour ago", "Yesterday at 3:45 PM" format
- **Effort:** Small
- **Details:** Replace raw date display with relative time formatting. Use rules: <1 min = "Just now", <60 min = "X min ago", <24h = "X hours ago", yesterday = "Yesterday at HH:MM", older = "MMM DD at HH:MM".

---

## DEFER - Post-MVP

### 7. Push Notifications (FCM) - BIGGEST ENGAGEMENT GAP
- **Description:** OS-level push for match_completed, player_added, tournament_update events
- **Effort:** Medium
- **Priority:** HIGH (single largest engagement gap vs CricHeroes)
- **Details:** Requires Firebase Cloud Messaging setup on both Flutter (already has `firebase_core`) and server (FCM Admin SDK). Define which events trigger pushes. CricHeroes sends minimum 2 push notifications per match (pre-match + result). Consider targeting Phase 8 or early post-MVP.

### 8. Deep-Link from Push Notification
- **Description:** Tap push notification to navigate directly to match/team/tournament
- **Effort:** Medium
- **Dependencies:** Requires push notifications (#7) first
- **Details:** go_router deep link integration. Parse notification payload to extract `referenceType` and `referenceId`, navigate to appropriate route on app open.

### 9. Personal Milestones
- **Description:** "You scored 50 runs!", "5-wicket haul!", "Hat trick!" achievements in feed
- **Effort:** Medium
- **Details:** Server needs milestone detection after match completion. Check batting stats for 50/100 runs, bowling stats for 5-wicket haul, consecutive wickets for hat trick. Entity already has `personal_milestone` case but no server emitter exists.

### 10. Match Attendance Request
- **Description:** Captain schedules match, selected players get Yes/No actionable notification
- **Effort:** Medium
- **Dependencies:** Requires team attendance feature to exist first
- **Details:** Extend `ActivityEventCard` to support actionable events with inline Yes/No buttons. New event type `attendance_request` with action callback.

### 11. Team Invitation Deep Link
- **Description:** Shareable invite URL to join a team (CricHeroes pattern: `/invite-team/{teamId}/{timestamp}`)
- **Effort:** Small
- **Details:** Requires Android App Links config or web redirect. New route in go_router to handle invite acceptance flow.

### 12. Notification Settings Page
- **Description:** Per-category on/off toggles for notification types
- **Effort:** Small
- **Dependencies:** Only useful after push notifications (#7) are implemented
- **Details:** Settings entry under Profile/More page. Categories: match alerts, team updates, tournament updates, milestones.

### 13. Offline Feed Caching
- **Description:** Cache activity_feed to Drift table for instant load without network
- **Effort:** Small
- **Details:** New Drift table mirroring `activity_feed` schema with `synced` flag. Load cached events instantly on app open, refresh from server in background. CricHeroes requires connectivity - this would be a CricScores advantage.

---

## SKIP - Not for CricScores MVP

| Feature | Reason |
|---------|--------|
| Dugout (live in-match chat + emoji reactions) | Major social infrastructure, completely out of scope |
| Cricket Feed (follow-based social stream) | Requires social graph system, not MVP |
| Stories (Instagram-like score sharing) | Ephemeral content infrastructure, not MVP |
| Live Activities / Dynamic Island (iOS) | Android-only MVP |
| Scorecard-embedded "follow match" | Social follow system not planned |

---

## CricScores Advantages Over CricHeroes

1. **Offline-first architecture** - Could cache feed locally for instant load (CricHeroes requires connectivity)
2. **Clean event model from day one** - Well-defined `referenceType`/`referenceId` deep-link support for all 4 entity types
3. **No notification spam** - Feed-only approach = zero notification fatigue at launch
4. **Faster load on budget devices** - Focused ~100-line page backed by single indexed DB table vs CricHeroes's heavy 51-100MB APK

---

## Implementation Priority Order

1. Nav tab unread badge (trivial)
2. team_joined event emitter (trivial)
3. Relative timestamps (small)
4. Pagination / infinite scroll (small)
5. Mark-all-as-read (small)
6. Swipe-to-delete (small)

---

*Analysis date: 2026-02-24*
*Source: CricHeroes competitive research (40M+ users)*
