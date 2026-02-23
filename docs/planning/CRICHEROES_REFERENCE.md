# CricHeroes Reference — Competitive Analysis Knowledge Base

## Meta

| Field | Value |
|-------|-------|
| Purpose | Pre-built reference for automated CricScores vs CricHeroes comparison via `cricheroes-comparator` agent |
| Last Researched | 2026-02-11 |
| CricHeroes Version | ~13.x (Android), ~11.x (iOS) |
| Sources | cricheroes.com, blog.cricheroes.com, Play Store, App Store, Tracxn, getlatka.com |
| Update Policy | Refresh when starting a new CricScores phase. Supplement with live web research for recent changes. |

---

## 1. Executive Summary

### 1.1 CricHeroes at a Glance

| Metric | Value |
|--------|-------|
| Registered Users | 40M+ |
| Matches Scored | 10M+ |
| Countries | 100+ |
| Play Store Rating | 4.8/5 (Editor's Choice) |
| App Store Rating | 4.6/5 (483 ratings) |
| Play Store Downloads | 27M+ (2.7 Cr+) |
| Revenue (2023) | $13.4M |
| Team Size | ~78 people |
| Funding | $1M raised for global expansion |
| Platforms | Android, iOS, Web (cricheroes.com) |
| Android App Size | ~51-53MB (base APK), ~100-106MB (with resources/XAPK) |
| iOS App Size | 230.5 MB |
| Min Android | 8.0+ (Oreo) |
| iOS Requirement | iOS 15+ |
| Languages | English primary; in-app language selector (Hindi and regional languages available) |
| Partnerships | 23+ BCCI State Associations, 40+ ICC-affiliated Cricket Associations |
| Developer | CricHeroes Pvt. Ltd. (India) |

### 1.2 Core Value Proposition

"Even a fifth grader can score" — CricHeroes positions itself as the simplest way to digitally score amateur cricket matches. Core pitch: **score matches, organize tournaments, build your cricket profile** — all free. Revenue comes from PRO subscriptions, live streaming, advertising, merchandise (The Dressing Room store), and white-label solutions.

### 1.3 CricScores vs CricHeroes Differentiation

| Dimension | CricHeroes | CricScores (Planned) |
|-----------|-----------|-------------------|
| Primary Market | Global (100+ countries, India-centric) | India (amateur cricket) |
| Theme | Light default, dark available | Material 3 Light only |
| Offline | Supported for scoring | Offline-first architecture (deeper) |
| Target Devices | All devices | Budget Android (2GB RAM focus) |
| App Size | ~80-100MB APK, 230MB iOS | Target: <30MB APK |
| Auth | Phone OTP + Google + Email | Phone OTP only (MVP) |
| Streaming | CH Live Stream (separate app) | Not in MVP |
| Merchandise | The Dressing Room store | Not in scope |
| Analytics | CricInsights (10 PRO tools) | Basic analytics (MVP) |
| Community | Looking For, Stories, PRO Club | Not in MVP |
| Tournaments | Full management + white-label | Full management (MVP Phase 2.5) |

---

## 2. Phase 1: Auth, Theme, Navigation

### 2.1 Authentication & Onboarding

**CricHeroes Approach:**
- **Sign-up methods:** Phone OTP (primary), Google Sign-In, Email. Phone is the default flow.
- **OTP flow:** Country code selector → phone number → 5-digit OTP sent via SMS → auto-read supported (Android SMS Retriever API). International users use email + OTP instead.
- **Alternative login:** PIN-based login available (registered mobile + PIN, no OTP needed each time). "Reset PIN" option in side menu.
- **Onboarding wizard:** After OTP verification, multi-step profile setup: name → playing role (Batter/Bowler/All-Rounder/Wicket-Keeper) → batting style (Right/Left) → bowling style → location → profile photo (optional).
- **Verified player:** Mobile-verified players unlock key features. Unverified players CANNOT: claim records, be Heroes of the Match, win freebies, score matches, be team admin, or receive skill tags.
- **Social login:** No Google/Apple Sign-In confirmed — phone OTP is the only method for India.

**UI Patterns:**
- Clean, minimal login screen with phone number field prominent
- Country code dropdown with flag icons
- Auto-read OTP with countdown timer
- Profile wizard uses step indicators (dots or progress bar)
- Skip option available for optional fields

**Gap Analysis:**

| Gap | CricHeroes | CricScores | Recommendation | Priority |
|-----|-----------|---------|----------------|----------|
| Google Sign-In | Not confirmed (phone OTP only for India) | Phone OTP only (per Q13) | — | — |
| 5-digit OTP | 5-digit OTP with auto-read | Not specified | ADOPT | High |
| Profile wizard steps | Name, role, batting style, bowling style, location, photo | Not fully specified in blueprint | ADOPT | Medium |
| Country code selector | Flag + code dropdown | Not specified | ADOPT | Low |
| Email auth | Available | Not in MVP | SKIP | Low |

**Decision Points:**
- SMS auto-read is trivial to add with `sms_autofill` or `smart_auth` Flutter package — strongly recommend ADOPT.
- Profile wizard: CricScores should collect playing role + batting/bowling style during onboarding (needed for player profiles later).

### 2.2 Navigation & Home Screen

**CricHeroes Approach:**
- **Bottom navigation:** 5 tabs — Home, My Cricket, Discover, Notifications, Profile
- **Home screen content:** Live match cards (if any), recent match results, quick action buttons ("Start Scoring", "Create Tournament"), featured tournaments, community highlights
- **My Cricket tab:** Personal matches, teams, tournaments, stats summary
- **Discover tab:** Looking For (players/teams/umpires), community stories, trending matches
- **Side drawer:** Settings, language selector, help, about, logout

**UI Patterns:**
- Match cards show: team names, scores, overs, result, match date
- Tournament cards show: tournament name, dates, teams count, format badge
- Quick action FAB or prominent buttons for "Start Match" / "Start Tournament"
- Pull-to-refresh on all list screens
- Badge indicators on Notifications tab

**Gap Analysis:**

| Gap | CricHeroes | CricScores | Recommendation | Priority |
|-----|-----------|---------|----------------|----------|
| Tab count | 5 tabs (Home, My Cricket, Discover, Notifications, Profile) | 4 tabs (My Cricket, Updates, Live, More) | SKIP — different but valid structure | — |
| Discover/Looking For | Dedicated tab for community discovery | Not in MVP | SKIP | Low |
| Notifications tab | Dedicated tab with badges | Not explicitly planned | DEFER (Phase 6+) | Medium |
| Match cards | Rich cards with scores, overs, result | Planned in blueprint | — | — |
| Quick actions | Prominent "Start Scoring" on home | Planned in blueprint | — | — |
| Side drawer | Settings, language, help | Minimal settings in Profile (per Q22) | SKIP | Low |

### 2.3 Theme & Visual Design

**CricHeroes Approach:**
- **Default theme:** Light mode (white backgrounds, green accents)
- **Dark mode:** Available as toggle in settings
- **Brand color:** Green (#4CAF50-ish — cricket green)
- **Typography:** System fonts, clean sans-serif
- **Custom themes:** PRO feature — custom team colors
- **Icons:** Mix of custom cricket icons and standard Material icons

**Gap Analysis:**

| Gap | CricHeroes | CricScores | Recommendation | Priority |
|-----|-----------|---------|----------------|----------|
| Default theme | Light mode | Light mode only (M3 Light, seed #1976D2) | — | — |
| Dark mode option | Available as toggle | Not in MVP | DEFER (post-MVP) | Low |
| Custom themes | PRO feature | Not planned | SKIP | Low |
| Brand color | Green ~#4CAF50 | Blue #1976D2 (M3 seed) | — | — |

---

## 3. Phase 2: Teams & Match Setup

### 3.1 Team Management

**CricHeroes Approach:**
- **Team creation:** Team name → team logo → add players
- **Player invite:** Phone contacts integration (bulk import from contacts), in-app search by name/phone, invite link sharing
- **Bulk import:** Select multiple contacts at once from phone book
- **Team features:** Roster management, team stats dashboard, attendance tracker, CricPay (expense management via UPI), team chat
- **Player tagging:** 5 batter types (Top-Order, Middle-Order, Lower-Order, Opener, Finisher) and 5 bowler types for categorization
- **Roles:** Captain badge, Wicket-keeper badge visible on roster

**UI Patterns:**
- Team card: logo, name, member count, recent form
- Contact picker with search and multi-select checkboxes
- Team detail: tabbed page (Roster, Stats, Matches, Tournaments)
- Player row: photo/initials, name, role badge, batting/bowling style
- Swipe actions on player rows for edit/remove

**Gap Analysis:**

| Gap | CricHeroes | CricScores | Recommendation | Priority |
|-----|-----------|---------|----------------|----------|
| Contact import | Bulk import from phone contacts | "Search by phone" + "Create new" per Q21 | ADOPT (bulk select) | Medium |
| Attendance tracker | Built-in attendance for practices | Not planned | SKIP | Low |
| CricPay | UPI-based team expense splitting | Not planned | SKIP | Low |
| Team chat | In-app messaging | Not planned | SKIP | Low |
| Player tagging | 5 batter + 5 bowler type tags | Basic role (Batter/Bowler/AR/WK) | DEFER | Low |
| Team stats dashboard | Aggregate team performance | Planned via career stats | — | — |

**Decision Points:**
- Bulk contact import (multi-select from phone book) is a significant UX improvement over one-by-one search. ADOPT effort: medium (requires contacts permission + bulk UI).

### 3.2 Match Setup

**CricHeroes Approach:**
- **Match creation wizard (8 steps):**
  1. Access: "Start A Match" from side menu or My Cricket section
  2. Select/create teams (Team A vs Team B)
  3. Select Playing XI for each team
  4. Configure: match type, overs, ground/location, date/time, ball type, pitch type
  5. Match officials (optional): add scorers, umpires, commentators
  6. Virtual coin toss: 3D animated flip (200x200px, ~2s animation, sound effects)
  7. Select striker, non-striker, opening bowler
  8. Tap "Let's Play" to start scoring
- **Match types:** Limited Overs, Test Match, Box Cricket, Pair Cricket, The Hundred
- **Over classification:** 6-12 overs → T10, 13-20 overs → T20, 21-99 overs → "Others"
- **Format presets:** Quick-select buttons for common over counts
- **Virtual toss:** 3D coin with rotation animation (1800° heads, 1980° tails), sound effects. Result displayed as "It's Heads/Tails" → choose bat/bowl.
- **Match types:** Friendly match (quick start), Tournament match (inherits rules)
- **Ball types:** Leather, Tennis, Tape, Other
- **Advanced settings:** Wide runs value, no-ball runs value, powerplay overs
- **DLS Calculator:** Automatic Duckworth-Lewis-Stern calculation (ICC DLS 5.0) for rain-affected matches
- **Box Cricket:** Significant use case — 400K+ indoor matches scored globally. Custom rules: last batter continues, bonus/negative runs, bowling restrictions

**UI Patterns:**
- Step indicator showing progress through setup
- Format preset as horizontal scrollable chips/buttons
- Team selector with search + create new team option
- Animated coin toss (3D flip animation)
- Player selection from roster with checkbox list

**Gap Analysis:**

| Gap | CricHeroes | CricScores | Recommendation | Priority |
|-----|-----------|---------|----------------|----------|
| Match formats | 5 types (Limited, Test, Box, Pair, Hundred) | Limited Overs only (MVP) | DEFER (post-MVP for Box/Pair/Hundred) | Low |
| Virtual toss animation | 3D coin flip with sound | Manual toss entry planned | DEFER | Low |
| Format presets | T5/T10/T15/T20/T25/ODI/Custom chips | Not specified but match setup exists | ADOPT | Trivial |
| Friendly match | Quick-start without tournament | Standalone match supported | — | — |
| Advanced settings | Wide/NB runs, powerplay | Supported per Q4/Q8 | — | — |

**Decision Points:**
- Format preset chips (T10/T20/ODI/Custom) are trivial to add and significantly speed up match setup. Strongly recommend ADOPT.

---

## 4. Phase 2.5: Tournaments

### 4.1 Tournament Management

**CricHeroes Approach:**
- **Tournament creation:** Comprehensive wizard — name, format, dates, venue, rules, team size, ball type
- **Formats:** Round-Robin, Knockout, Group Stage + Knockout (same as CricScores)
- **Auto-scheduling:** Generate fixture schedule automatically with conflict detection
- **Points table:** Auto-calculated with configurable point values (W/L/T/NR)
- **NRR calculation:** Automatic Net Run Rate calculation and display
- **Bracket visualization:** Visual knockout bracket for elimination rounds
- **Leaderboards:** Top scorers, wicket takers, batting average, economy rate
- **Sponsor features:** "Super Sponsor" — sponsor visibility on match pages, tournament pages
- **Power Promote:** Paid feature to promote tournament to nearby users
- **Fee collection:** Tournament registration fees (via CricPay/external payment)
- **White-label ("Your App"):** Custom branded apps published on App Store/Play Store. $699 (core features, 3 sponsor slots) or $1,199 (adds news, polls, livestreaming, 3 sponsor slots)
- **Bulk schedule import:** Add tournament schedule in bulk via CSV/template
- **Organizer handbook:** Comprehensive guide for tournament organizers

**UI Patterns:**
- Tournament card: banner image, name, dates, format badge, team count, status
- Tournament detail: tabbed page (Overview, Teams, Fixtures, Standings, Leaderboard)
- Bracket view: visual tree for knockout rounds
- Standings: sortable table with points, NRR, played, won, lost
- Fixture list: chronological with date grouping, status badges (Upcoming/Live/Completed)

**Gap Analysis:**

| Gap | CricHeroes | CricScores | Recommendation | Priority |
|-----|-----------|---------|----------------|----------|
| Formats | RR, KO, Group+KO | Same three formats | — | — |
| Auto-schedule | Generate + manual edit | Same (per T3) | — | — |
| NRR calculation | Automatic | Planned (SCORING_RULES.md §8) | — | — |
| Bracket visualization | Visual knockout tree | Planned (blueprint screen 23) | — | — |
| Sponsor visibility | Super Sponsor program | Not in MVP | SKIP | Low |
| Power Promote | Paid promotion to nearby users | Not planned | SKIP | Low |
| Fee collection | CricPay/external payment | Not in MVP | SKIP | Low |
| White-label | Custom branded apps/pages | Not in MVP | SKIP | Low |
| Bulk schedule import | CSV template upload | Not planned | DEFER | Low |
| Registration approval | Team registers → organizer approves/rejects | Planned (per T10) | — | — |
| Venue conflict detection | Warning on overlapping fixtures | Planned (per T13, warning only) | — | — |
| Organizer handbook | Help guide for tournament setup | Not planned | SKIP | Low |

**CricHeroes-Only Tournament Features (Not in CricScores):**
- Sponsor visibility and paid promotion
- Fee collection and payment processing
- White-label solutions for cricket associations
- Tournament-scoped live streaming
- AI-generated tournament highlights
- Bulk schedule CSV import

---

## 5. Phase 3: Scoring Engine

### 5.1 Core Scoring Interface

**CricHeroes Approach:**
- **Layout:** Fixed header (match status, team scores) + scrollable middle (batter/bowler cards, current over) + fixed bottom (scoring buttons)
- **Scoring method:** Single-tap — tap a run button and the delivery is immediately recorded. No confirmation step for common deliveries.
- **Run buttons:** 0, 1, 2, 3, 4, 6 as circular buttons. 4 and 6 have distinct colors (blue for 4, purple for 6). "More..." button for 5, 7, etc.
- **Extras buttons:** WD (wide), NB (no-ball), B (bye), LB (leg-bye) — tap extra first, then tap runs
- **Wicket button:** Large, red, prominent "W" button
- **Header displays:** Team name, score (runs/wickets), overs, current run rate (CRR), projected score
- **Middle section:** Current batter cards (striker highlighted, name + runs + balls + SR), bowler card (name + overs + maidens + runs + wickets + economy), current over display (dot/run indicators), partnership runs and balls
- **Match status bar:** Shows match context ("Team A needs 45 runs from 30 balls")
- **Offline:** Full offline scoring capability — matches can be scored without internet

**Performance Characteristics:**
- Single-tap scoring — minimal latency between tap and UI update
- Optimized for quick successive taps (e.g., during a fast over)
- Offline mode: entire match can be scored without connectivity
- Auto-save: every delivery persisted immediately

**UI Patterns:**
- Batter cards: Name | R (runs) | B (balls) | SR (strike rate) — striker has visual highlight
- Bowler card: Name | O (overs) | M (maidens) | R (runs) | W (wickets) | ER (economy)
- Current over: horizontal row of ball indicators (dot=0, colored circles for runs, W for wickets, Wd for wides, Nb for no-balls)
- Partnership: "Partnership: X runs (Y balls)"
- Run buttons in a grid layout: [0] [1] [2] [3] [4] [6] with [More...] for uncommon values

**Gap Analysis:**

| Gap | CricHeroes | CricScores | Recommendation | Priority |
|-----|-----------|---------|----------------|----------|
| Layout | Fixed-scroll-fixed (same approach) | Same layout planned (per CLAUDE.md) | — | — |
| Single-tap scoring | Yes (no confirmation) | Planned | — | — |
| CRR display | Current run rate in header | Not explicitly specified | ADOPT | Trivial |
| Projected score | Displayed in header | Not specified | DEFER | Low |
| Match context bar | "Need X from Y balls" | Not explicitly specified | ADOPT | Trivial |
| Partnership display | Runs + balls in middle section | Not specified in detail | ADOPT | Trivial |
| Color-coded run buttons | 4=blue, 6=purple, W=red | Semantic colors defined (G23) | — | — |
| Over indicators | Visual ball-by-ball in current over | Planned | — | — |
| Batter strike rate | Shown on batter card | Not explicitly specified | ADOPT | Trivial |
| Bowler economy | Shown on bowler card | Not explicitly specified | ADOPT | Trivial |

**Decision Points:**
- CRR, partnership display, batter SR, bowler economy are all trivial additions that significantly improve the scoring experience. All should be ADOPT.
- "Match context bar" ("Need X from Y balls") is high UX value and trivial to compute. ADOPT.
- Projected score calculation is more complex (require run rate projection) — DEFER.

### 5.2 Extras Handling

**CricHeroes Approach:**
- Tap extra button (WD/NB/B/LB) → then tap runs to add extra runs
- Wide: WD button → 0/1/2/3/4 runs (wide + runs)
- No-ball: NB button → 0/1/2/3/4/6 runs (no-ball + runs to batter)
- Bye: B button → 1/2/3/4 runs
- Leg-bye: LB button → 1/2/3/4 runs
- Free hit indicator: Visual badge/icon shown when next delivery is a free hit
- Combined extras: Wide + stumping (possible), No-ball + run out (possible on free hit)

**Gap Analysis:**
Minimal gap — cricket laws dictate behavior. CricScores's extras handling matches CricHeroes.

| Gap | CricHeroes | CricScores | Recommendation | Priority |
|-----|-----------|---------|----------------|----------|
| Free hit indicator | Visual badge on scoring screen | Tracked in ScoringState (Q6) | ADOPT (visible indicator) | Medium |
| Extra + runs flow | Tap extra → tap runs | Same approach planned | — | — |

### 5.3 Wicket Handling

**CricHeroes Approach:**
- Tap "W" button → Select dismissal type → Select fielder (if applicable) → Select new batter → Confirm
- Dismissal types shown as a grid of buttons
- For caught: select fielder from field position map or list
- For run out: select which batter is out, select fielder, indicate direct hit
- Confirmation dialog before finalizing
- New batter selection: list of remaining batters from roster

**Gap Analysis:**

| Gap | CricHeroes | CricScores | Recommendation | Priority |
|-----|-----------|---------|----------------|----------|
| Wicket flow | Type → fielder → batter → confirm | Same flow planned (SCORING_RULES.md) | — | — |
| Field position map | Visual field for fielder selection | Not specified (list-based per B1) | DEFER | Medium |
| Direct hit toggle | Available on run out | Planned per Q10 | — | — |

**Decision Points:**
- Visual field position map for fielder selection (instead of a plain list) is a nice UX touch but medium effort. DEFER to post-MVP.

### 5.4 Undo & Error Correction

**CricHeroes Approach:**
- **Undo last ball:** Single tap to undo the most recent delivery. Reverses all effects (runs, wickets, stats, strike rotation).
- **Live Match Edit:** Edit ANY past delivery in the match via settings → "Edit Scorecard". Can change: runs scored, delivery type (wide/no-ball/dot), bowler assignment, batter credit. Tap "UPDATE SCORE" to confirm. Once saved, edits can be re-edited but not "undone."
- **Post-match editing:** Individual matches: both team captains can edit their own innings for up to 8 days. Tournament matches: scorers and tournament creators can edit until tournament ends.
- **Scoring Quality Score (SQS):** 8-parameter quality metric for scorers. Excessive UNDOs penalize SQS. Parameters: matches scored (10+/month ideal), advance scheduling, legitimate deliveries, wagon wheel usage, match officials documented, match photography (3+ photos), player verification, profile completeness.

**Gap Analysis:**

| Gap | CricHeroes | CricScores | Recommendation | Priority |
|-----|-----------|---------|----------------|----------|
| Undo last ball | Single-tap undo | Planned (SCORING_RULES.md §4) | — | — |
| Live Match Edit | Edit any past delivery | Not planned (only undo last) | DEFER (significant effort) | Medium |
| Undo constraints | Unclear limits | Blocked after transition per A1 | — | — |
| Reopen innings/match | Available | Planned per Q12 | — | — |

**Decision Points:**
- Live Match Edit (editing any past delivery, not just the last one) is a significant gap. CricHeroes offers this as a differentiator. Effort: large (requires recalculation of all stats from edited point forward). DEFER to post-MVP but note as important competitive gap.

---

## 6. Phase 4: Analytics & Visualizations

### 6.1 Match Analytics

**CricHeroes Approach:**
- **Charts available:** Wagon wheel, Manhattan chart, Worm chart, Run rate graph, MVP calculation
- **Player selector:** Dropdown above charts to filter by specific player
- **Share as image:** Export any chart/scorecard as shareable image
- **Tabbed analytics page:** Overview, Batting, Bowling, Charts tabs
- **CricInsights PRO (10 tools):**
  1. Batting Insights — strengths/weaknesses analysis
  2. Bowling Insights — bowling potential analysis
  3. Player Comparison — head-to-head stat comparison
  4. Face Off Analysis — performance against specific opponents
  5. Live Match Insights — real-time performance data during match
  6. Past Match Insights — post-match analysis
  7. Upcoming Match Insights — opponent/team scouting
  8. Team Insights — team-level analysis
  9. Team Comparison — team vs team stats
  10. Tournament Insights — tournament-level analysis

**UI Patterns:**
- Charts use interactive touch (tap for data points)
- Manhattan: vertical bars per over
- Worm: line chart comparing both innings
- Wagon wheel: circular chart showing shot direction
- MVP: points-based ranking with breakdown
- Share button on every chart view

**Gap Analysis:**

| Gap | CricHeroes | CricScores | Recommendation | Priority |
|-----|-----------|---------|----------------|----------|
| Wagon wheel | Interactive with shot directions | Planned (12-zone system, G25) | — | — |
| Manhattan | Per-over bar chart | Planned in IMPLEMENTATION_PLAN | — | — |
| Worm | Comparative line chart | Planned | — | — |
| MVP | Points-based player ranking | Planned (IMPLEMENTATION_PLAN Phase 4) | — | — |
| Share as image | Export charts/scorecards | Not explicitly planned | DEFER | Medium |
| CricInsights PRO | 10 advanced analytics tools | Not in MVP | SKIP | — |
| Player comparison | Side-by-side stat comparison | Not in MVP | DEFER | Medium |
| Face Off analysis | Performance against specific opponent | Not planned | SKIP | Low |
| Run rate graph | Per-over run rate visualization | Not explicitly specified | ADOPT | Small |

**Decision Points:**
- Share as image is a viral growth feature (users share scorecards on WhatsApp/Instagram). DEFER but consider for Phase 5+.
- Run rate per-over graph alongside Manhattan is trivial. ADOPT.

---

## 7. Phase 5: Player Profiles & Stats

### 7.1 Player Profiles

**CricHeroes Approach:**
- **Cricket resume:** Comprehensive profile showing career summary, form tracker, badges, awards
- **Profile header:** Photo, name, location, playing role, batting/bowling style, team affiliation
- **Career stats:** Matches, innings, runs, average, strike rate, highest score, 50s/100s, wickets, bowling average, economy, best bowling, catches, stumpings
- **Badges:** Achievement badges for milestones (50 runs, 100 runs, 5-wicket haul, hat trick, etc.)
- **Awards:** Match awards (Player of the Match), tournament awards
- **Form tracker:** Recent match performance (last 5-10 matches) shown as mini bar chart
- **Leaderboards:** Global, local, tournament-scoped rankings by various stats
- **Match history:** Chronological list of all matches with brief performance summary
- **Player tags:** "Batter Type" and "Bowler Type" classification tags

**UI Patterns:**
- Profile header with large photo/avatar, stats summary cards below
- Tabbed view: Overview, Batting, Bowling, Fielding, Matches, Badges
- Badge grid: visual badge icons with labels
- Form tracker: small bar chart or performance line graph
- Leaderboard: ranked list with position indicator, stat values, trend arrows
- Stats displayed in card format with large numbers

**Gap Analysis:**

| Gap | CricHeroes | CricScores | Recommendation | Priority |
|-----|-----------|---------|----------------|----------|
| Cricket resume | Full career summary page | Career stats planned (player_career_stats table) | — | — |
| Badges | Achievement system with visual badges | Not in MVP | DEFER | Medium |
| Awards | MVP, PoTM awards | Not in MVP | DEFER | Medium |
| Form tracker | Recent performance mini chart | Not specified | DEFER | Low |
| Leaderboards | Global, local, tournament-scoped | Tournament-scoped planned (T7/T16) | DEFER (global/local) | Low |
| Match history | Full chronological list | Planned | — | — |
| Profile photo | Upload with crop | Initials-only avatar (MVP, per C5) | SKIP (deliberate MVP choice) | — |

---

## 8. Phase 6: Real-time & Live Updates

### 8.1 Live Scoring

**CricHeroes Approach:**
- **WebSocket-based:** Real-time ball-by-ball updates to all viewers
- **Score ticker:** Compact live score widget visible outside app (notification bar, web embed)
- **Live streaming:** Separate "CH Live Stream" app for camera streaming, integrates with main app
  - Multi-camera support (multiple phones as cameras)
  - Streams to Facebook, YouTube, or CricHeroes YouTube channel
  - Score overlay automatically displayed on stream
  - OBS/VMix compatibility for advanced setups
- **Push notifications:** Match start, wicket, milestone (50/100), match result, innings break
- **Ball-by-ball commentary:** Auto-generated text commentary for each delivery
- **AI-generated highlights:** Automatic highlight reels created post-match
- **CricHeroes Capture:** Built-in camera mode for capturing match footage

**Gap Analysis:**

| Gap | CricHeroes | CricScores | Recommendation | Priority |
|-----|-----------|---------|----------------|----------|
| WebSocket live updates | Real-time ball-by-ball | Planned (Bun native WebSockets) | — | — |
| Score ticker/widget | Notification bar widget | Not planned | DEFER | Low |
| Live streaming | CH Live Stream separate app | Not in MVP | SKIP | — |
| Push notifications | Match events (wicket, 50, result) | Not explicitly planned | DEFER (Phase 6+) | Medium |
| Auto commentary | Generated per delivery | Planned (G21 — template-based) | — | — |
| AI highlights | Post-match highlight reel | Not in MVP | SKIP | — |
| Score overlay | On live stream | Not applicable (no streaming) | SKIP | — |

---

## 9. CricHeroes-Only Features (Not in CricScores MVP)

### 9.1 Community & Social

- **Looking For:** Search for players, teams, umpires, scorers in your area. Filter by role, location, availability.
- **Stories:** Instagram-like stories for cricket updates, match highlights
- **PRO Club:** Exclusive community for PRO subscribers with special features
- **Voice search:** Search for players/teams using voice commands
- **Social feed:** Activity feed showing friends' match results, achievements, updates

### 9.2 Gamification

- **Badges:** Milestone badges (scored 1000 runs, took 50 wickets, etc.)
- **Awards:** CricHeroes Awards — annual recognition program for top performers
- **Player tags:** "Batter" and "Bowler" type tags displayed on merchandise from The Dressing Room
- **Leaderboard rankings:** Local, regional, global leaderboards with seasonal resets
- **Challenges:** [needs research] — may include weekly/monthly challenges

### 9.3 Premium (CricHeroes PRO)

**Tier Structure:**
- **Pro Annum:** Annual subscription
- **Pro Infinity:** Lifetime subscription
- **Monthly/Quarterly:** Shorter duration options

**iOS Pricing (US App Store):**
| Plan | Price |
|------|-------|
| Monthly | $9.99 |
| 90 Days | $1.99 (promotional?) |
| Quarterly | $9.99 |
| Yearly | $24.99 |
| One Year | $12.49 (promotional?) |
| Pro Infinity (lifetime) | $69.99 |

**PRO Features Include:**
- All 10 CricInsights analytics tools
- Advanced player comparison
- Face-off analysis
- Live match insights
- Upcoming match scouting
- Team-level analytics
- Tournament insights
- Exclusive merchandise discounts at The Dressing Room
- Priority support
- Ad-free experience
- Custom themes

### 9.4 Streaming

- **CH Live Stream:** Separate companion app (Play Store: com.cricheroes.streaming). Opens automatically when streaming starts from main app.
- **Multi-camera:** Multiple phone cameras at different angles, synced via same CricHeroes account
- **Platform integration:** Stream to Facebook Live, YouTube (personal or CricHeroes channel)
- **Score overlay:** 19+ customizable ticker templates (3 free, 16+ premium). Auto-animations for boundaries, sixes, wickets, milestones. Full scorecard shown between overs/innings breaks.
- **OBS/VMix/Wirecast support:** For advanced streaming setups
- **CricHeroes Capture:** In-app camera mode for recording match footage
- **AI-generated highlights:** Rs 29 per player highlight, Rs 49 per match highlight. First player highlight free. Requires score ticker during match. Limited to select cities (India, US/Canada, UAE).
- **Live stream pricing:** Rs 199/match (India). iOS: $2.99-$6.99/match, $39.99/day unlimited
- **Requirements:** Quality phone camera, 4G/WiFi, power bank, tripod recommended

### 9.5 Cricket Grounds Directory

- Search for cricket grounds/venues near your location
- Ground details: address, photos, facilities, booking info
- Used for venue selection in match/tournament setup

### 9.6 Match Officials Directory

- Search for umpires and scorers
- Official profiles with experience and availability
- Part of the "Looking For" feature

### 9.7 E-Commerce (The Dressing Room)

- **URL:** store.cricheroes.com / tdr.cricheroes.com
- **Products:** Custom cricket jerseys, team uniforms, cricket equipment, apparel
- **Personalization:** Display batter/bowler tags on gear, custom team names/numbers
- **Pricing:** Standard e-commerce pricing, PRO members get discounts
- **Shipping:** India and international (outside India section available)

### 9.8 CricPay

- UPI-based team expense management
- Split expenses: ground fees, uniforms, tournament registration, meals
- Add UPI ID, send payment requests to teammates
- Payment reminders
- Expense tracking and transparency

---

## 10. Performance Benchmarks

| Metric | CricHeroes | CricScores (Target) |
|--------|-----------|-----------------|
| APK Size | ~51-53MB (base), ~100MB (full) | <30MB |
| iOS Size | 230.5 MB | N/A (Android only MVP) |
| Cold Start | ~3-5s (reported in reviews) | <3s target |
| Scoring Speed | Near-instant (single-tap) | <50ms per delivery pipeline |
| Offline Capability | Yes (full scoring) | Yes (offline-first architecture) |
| Min Android | 8.0+ (API 26, Oreo) | 6.0 (API 23) per Q1 |
| Languages | English + regional (in-app switch) | English only (MVP) |
| Memory Usage | Higher (large APK, many features) | Lower (focused feature set) |

---

## 11. UI/UX Pattern Summary

### 11.1 Navigation Comparison

| Pattern | CricHeroes | CricScores |
|---------|-----------|---------|
| Bottom nav tabs | 5: Home, My Cricket, Discover, Notifications, Profile | 4: My Cricket, Updates, Live, More |
| Side drawer | Yes (settings, language, help) | No (settings in Profile) |
| Quick actions | FAB / prominent buttons | Quick action cards on Home |
| Search | Global search + voice search | Not in MVP |

### 11.2 Color & Theme Comparison

| Element | CricHeroes | CricScores |
|---------|-----------|---------|
| Default | Light mode | Light mode (M3) |
| Primary | Green (~#4CAF50) | Blue (#1976D2) |
| Four | Blue highlight | Blue (#1565C0) per G23 |
| Six | Purple highlight | Purple (#6A1B9A) per G23 |
| Wicket | Red | Red (#C62828) per G23 |
| Background | White (light mode) | Light surface hierarchy (M3) |

### 11.3 Scoring Interface Layout Comparison

| Zone | CricHeroes | CricScores |
|------|-----------|---------|
| Top (fixed) | Team name, score, overs, CRR, projected | Team name, score, overs (+ connectivity dot) |
| Middle (scroll) | Batter cards (R/B/SR), bowler card (O/M/R/W/ER), current over, partnership | Batter cards, bowler card, current over |
| Bottom (fixed) | Run buttons (0-6), extras row (WD/NB/B/LB), wicket button, More, Undo | Run buttons, extras, wicket, More, Undo, Set menu |

### 11.4 Common Interaction Patterns

| Interaction | CricHeroes | CricScores |
|-------------|-----------|---------|
| Record delivery | Single tap (run button) | Single tap (planned) |
| Record extra | Tap extra → tap runs | Same approach |
| Record wicket | W → type → fielder → batter → confirm | Same approach |
| Undo | Single tap undo button | Same approach |
| Edit past ball | Live Match Edit (PRO) | Not in MVP (undo last only) |
| New batter | Select from roster list | Bottom sheet list (B1) |
| New bowler | Select from eligible list | Bottom sheet with stats (B2) |
| Innings transition | Auto-prompt | 3-step stepper (B3) |

---

## 12. Master Gap Summary Matrix

**Last updated:** 2026-02-11 (comprehensive review with live web research across 30+ sources)

### 12.1 ADOPT — Incorporated into MVP (6 items, UI prototypes updated)

| # | Feature | Phase | Status | UI Change |
|---|---------|-------|--------|-----------|
| 1 | SMS auto-read OTP | 1 | ADOPT | Logic only (Flutter `smart_auth` package) |
| 3 | Searchable country code selector | 1 | ADOPT | `02-login.html` updated — searchable dropdown with 20 cricket nations |
| 4 | Location field in profile setup | 1 | ADOPT | `04-profile-setup.html` updated — optional city/state field added |
| 13 | Bulk contact import for teams | 2 | ADOPT | Logic only (phone contacts multi-select, implementation phase) |
| 14 | Team location field | 2 | ADOPT | `07-create-team.html` updated — optional location field added |
| 29 | "Need X from Y balls" context | 3 | ADOPT | `12-scoring-page.html` updated — 2nd innings context bar added |
| 52 | Run rate per-over graph | 4 | ADOPT | `16-match-analytics.html` updated — 5th tab "Run Rate" added |

### 12.2 ALREADY DONE — Already in UI prototypes (25 items, no changes needed)

| # | Feature | Phase | UI File |
|---|---------|-------|---------|
| 5 | Profile photo upload | 1 | `04-profile-setup.html` |
| 21 | Format preset chips (5/10/20/50) | 2 | `10-match-setup.html` |
| 26 | DLS Calculator | 2 | Planned in SCORING_RULES.md |
| 27 | CRR in score header | 3 | `12-scoring-page.html` |
| 28 | RRR in score header | 3 | `12-scoring-page.html` |
| 30 | Partnership display (runs+balls) | 3 | `12-scoring-page.html` |
| 31 | Last wicket info | 3 | `12-scoring-page.html` |
| 32 | Batter SR on card | 3 | `12-scoring-page.html` |
| 33 | Bowler economy on card | 3 | `12-scoring-page.html` |
| 34 | Free hit visual indicator | 3 | `12-scoring-page.html` |
| 35 | Swap strike button | 3 | `12-scoring-page.html` |
| 41 | Scorecard batting table | 3 | `15-scorecard.html` |
| 42 | Scorecard bowling table | 3 | `15-scorecard.html` |
| 43 | Fall of wickets section | 3 | `15-scorecard.html` |
| 44 | Extras breakdown by type | 3 | `15-scorecard.html` |
| 46 | Super Over support | 3 | `15-scorecard.html` |
| 47 | Ball-by-ball commentary | 3 | `15-scorecard.html` |
| 48 | Manhattan chart | 4 | `16-match-analytics.html` |
| 49 | Worm chart | 4 | `16-match-analytics.html` |
| 50 | Wagon wheel | 4 | `16-match-analytics.html` |
| 51 | MVP display | 4 | `16-match-analytics.html` |
| 61 | Tournament formats (RR/KO/Group+KO) | 2.5 | `20-create-tournament.html` |
| 62 | Points system config | 2.5 | `20-create-tournament.html` |
| 63 | Group stage settings | 2.5 | `20-create-tournament.html` |
| 69 | Match schedule config (time/duration/gap) | 2.5 | `20-create-tournament.html` |

### 12.3 DEFER — Post-MVP (20 items)

| # | Feature | Phase | Priority | Notes |
|---|---------|-------|----------|-------|
| 6 | WhatsApp Login (OTPless) | 1 | Medium | 96% success rate, 80% cost reduction |
| 7 | PIN Login | 1 | Medium | Login with phone+PIN, no OTP each time |
| 12 | Notifications dedicated tab | 1 | Medium | Bell icon with badge count |
| 15 | Team profile tabs (6 tabs) | 2 | Medium | Members, Matches, Stats, Leaderboard, Photos, Profile |
| 19 | Invite link sharing | 2 | Low | Share link to join team |
| 20 | Match banners & squad posters | 2 | Medium | Design tools for social sharing |
| 25 | Match officials | 2 | Low | Add scorers, umpires, commentators |
| 36 | Live Match Edit (any past delivery) | 3 | Medium | Significant effort — recalculate all stats from edit point |
| 37 | Post-match edit window (8 days) | 3 | Low | Individual: 8 days; tournament: until end |
| 39 | Projected score in header | 3 | Low | Run rate projection calculation |
| 40 | Field position map for fielder selection | 3 | Medium | Visual field instead of list |
| 45 | Awards (PoTM, Best Bat/Bowl) | 3-4 | Medium | Auto-calculated post-match |
| 53 | Share charts/scorecards as image | 4 | Medium | Viral growth feature (WhatsApp/Instagram) |
| 54 | Player comparison | 4 | Medium | Side-by-side stat comparison |
| 57 | Badges/achievements | 5 | Medium | Visual milestone badges |
| 58 | Awards display on profile | 5 | Medium | PoTM, tournament awards |
| 59 | Form tracker | 5 | Low | Recent performance mini chart |
| 60 | Player tags (AI classification) | 5 | Low | K-means clustering: 5 batter + 4 bowler types |
| 64 | Auto-schedule generator | 2.5 | — | Already planned (T3) |
| 65 | Bulk schedule import (CSV) | 2.5 | Low | Excel/CSV template upload |

### 12.4 SKIP — Out of MVP scope (18 items)

| # | Feature | Reason |
|---|---------|--------|
| 2 | OTP digit count (5 vs 6) | Keep 6-digit (Firebase default). No benefit to changing. |
| 8 | Different tab structure | CricScores's 4-tab structure (My Cricket, Updates, Live, More) is valid and well-designed |
| 9 | "Matches of Your Interest" | Contact+location-based suggestions, complex |
| 10 | Stories (Instagram-like feed) | Social feature, out of MVP scope |
| 11 | Side drawer navigation | Settings in Profile tab is simpler |
| 16 | Team Attendance (RSVP) | Nice-to-have, not core scoring |
| 17 | CricPay (UPI expense splitting) | Payment feature, out of scope |
| 18 | Team chat/DM | Messaging feature, out of scope |
| 22 | Match types (Test/Box/Pair/Hundred) | Limited Overs only for MVP |
| 23 | Virtual coin toss animation | Manual toss entry is sufficient |
| 24 | Pitch type setting | Purely informational, no gameplay impact |
| 38 | Scoring Quality Score (SQS) | 8-parameter scorer metric, not needed for MVP |
| 55 | CricInsights PRO (10 tools) | Premium analytics suite |
| 66 | Sponsor visibility | Monetization feature |
| 67 | Power Promote | Paid promotion |
| 68 | Fee collection | Payment processing |
| 22-old | Score ticker widget | Notification bar widget |
| — | Light mode, voice search, merchandise, AI highlights, live streaming, Looking For | Out of MVP scope or deliberate differentiation |

### 12.5 Summary

| Status | Count | Description |
|--------|-------|-------------|
| **ADOPT** | 7 | Incorporated into MVP — UI prototypes updated |
| **ALREADY DONE** | 25 | Already in UI prototypes — no changes needed |
| **DEFER** | 20 | Good features for post-MVP phases |
| **SKIP** | 18+ | Out of MVP scope or deliberate differentiation |

**Key finding:** 25 of the original ADOPT items from the initial analysis were already implemented in the UI prototypes, which were designed after the spec docs. The UI prototypes are significantly more complete than the specification documents suggest. Only 7 items required actual changes — 5 UI prototype updates and 2 logic-only items.
