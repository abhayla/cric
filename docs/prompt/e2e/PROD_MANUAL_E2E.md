# Production E2E Test Plan — 16 Teams, 5 Tournaments, 256 Matches

## Overview

Comprehensive production test: create 16 teams (96 players), run 5 tournaments (~256 matches) with fully random scoring. All data persists permanently on the prod server (`cricscores.in`). Runs overnight (~13-17 hours).

**All actions (team creation, player addition, tournament creation, tournament status transitions, team registration, fixture generation, scoring) go through the app UI — the exact same process any real user would follow. No API shortcuts. No exceptions.** API calls are allowed ONLY for read-only queries (listing tournaments by name to get IDs, fetching fixture lists for scoring order, checking standings after completion).

### Full UI Flow Per Tournament
1. **Create Tournament** — Fill form (name, format chip, overs, ball type, players per side, group settings) → Submit
2. **Open Registration** — Tap ⋮ menu → "Open Registration"
3. **Add Teams** — Tap "Add Team" on Teams tab → select group (if applicable) → tap team name. Repeat for all teams.
4. **Generate Fixtures** — Tap "Generate Fixtures" on Overview tab
5. **Start Tournament** — Tap ⋮ menu → "Start Tournament"
6. **Score Matches** — Navigate to each fixture, complete toss, score all deliveries via UI

## Pre-Test Checklist

- [ ] Prod server running at `cricscores.in` (verify: `curl https://cricscores.in/api/v1/test/health` or just open in browser)
- [ ] Android emulator running (`emulator -avd <name>`)
- [ ] Scorer phone configured: `9999999999` (Firebase test phone, OTP: `123456`)
- [ ] Viewer phone configured: `9999999998` (Firebase test phone, OTP: `123456`)
- [ ] Prod APK built: `flutter build apk --flavor prod --debug --dart-define=FLAVOR=prod`
- [ ] Viewer has prod APK installed on their device
- [ ] Stable internet connection for overnight run

## 16 Team Rosters

| # | Team Name | Player 1 | Player 2 | Player 3 | Player 4 | Player 5 | Player 6 |
|---|-----------|----------|----------|----------|----------|----------|----------|
| 1 | Bangalore Titans | Rajesh Kumar | Amit Sharma | Vikram Singh | Sanjay Reddy | Ravi Yadav | Suresh Menon |
| 2 | Hyderabad Kings | Arjun Rao | Nikhil Verma | Vinay Kulkarni | Harish Shetty | Ajay Chauhan | Tarun Bhat |
| 3 | Mumbai Warriors | Rohan Patil | Aditya Joshi | Pranav Desai | Kunal Sawant | Sachin Tendulkar Jr | Yash Bhosale |
| 4 | Chennai Strikers | Karthik Iyer | Ashwin Rajan | Varun Chakravarthy | Deepak Natarajan | Ganesh Subramanian | Surya Narayanan |
| 5 | Delhi Dynamos | Mohit Taneja | Virat Kohli Jr | Shubham Gill Jr | Naveen Dhaliwal | Ishant Mehra | Prithvi Chahar |
| 6 | Kolkata Knights | Sourav Ghosh | Anirban Das | Debashish Roy | Subhajit Mondal | Rishav Chatterjee | Arko Banerjee |
| 7 | Pune Gladiators | Aniket Kulkarni | Siddharth Pawar | Rohit Kale | Tejas Deshpande | Omkar Shinde | Pratik Jadhav |
| 8 | Jaipur Royals | Manish Shekhawat | Yuvraj Rathore | Lalit Yadav Jr | Hemant Sharma | Divyanshu Meena | Rahul Chahar Jr |
| 9 | Lucknow Lions | Aman Mishra | Shivam Tiwari | Abhishek Pandey | Rajan Srivastava | Gaurav Awasthi | Vivek Dubey |
| 10 | Ahmedabad Avengers | Parth Patel | Darshan Shah | Jignesh Mistry | Chirag Thakkar | Ketan Bhatt | Mihir Raval |
| 11 | Chandigarh Chargers | Gurpreet Singh | Harmanpreet Brar | Jaspreet Bumrah Jr | Mandeep Sandhu | Ravinder Gill | Tejvir Dhillon |
| 12 | Indore Infernos | Ayush Tiwari | Rishabh Jain | Nitin Agrawal | Harsh Malviya | Devendra Chouhan | Rahul Patidar Jr |
| 13 | Vizag Vikings | Prashanth Reddy | Sai Krishna | Venkat Rao | Ravi Teja | Anil Kumar | Sudheer Babu |
| 14 | Kochi Tuskers | Arun Lal | Vishnu Nair | Sreejith Menon | Jobin Joseph | Aswin Das | Midhun Pillai |
| 15 | Guwahati Gladiators | Bikash Sarma | Rajdeep Bora | Pranjal Hazarika | Debojit Das | Manash Kalita | Rituraj Gogoi |
| 16 | Ranchi Rhinos | Akash Kumar | Saurabh Singh | Vikash Mahto | Dheeraj Tiwary | Amit Oraon | Pankaj Sahu |

All players assigned role: **All-Rounder** (everyone can bat and bowl in 6-player format).

## 5 Tournament Configurations

| # | Name | Format | Overs | Groups | Qualify/Group | Ball Type | Est. Matches |
|---|------|--------|-------|--------|---------------|-----------|-------------|
| T1 | Champions Trophy 2026 | Group+KO | 5 | 4 (4 teams) | Top 2 | Tennis (2) | ~31 |
| T2 | Premier League S1 | Group+KO | 10 | 4 (4 teams) | Top 1 | Leather (1) | ~27 |
| T3 | Knockout Cup | Knockout | 5 | - | - | Tennis (2) | 15 |
| T4 | Super League | Round Robin | 5 | - | - | Tennis (2) | 120 |
| T5 | Masters Trophy | Group+KO | 3 | 2 (8 teams) | Top 4 | Tape (3) | ~63 |

### Group Assignments

**T1 & T2 (4 groups x 4 teams):**
- Group A: Bangalore Titans, Hyderabad Kings, Mumbai Warriors, Chennai Strikers
- Group B: Delhi Dynamos, Kolkata Knights, Pune Gladiators, Jaipur Royals
- Group C: Lucknow Lions, Ahmedabad Avengers, Chandigarh Chargers, Indore Infernos
- Group D: Vizag Vikings, Kochi Tuskers, Guwahati Gladiators, Ranchi Rhinos

**T3 (Knockout):** Seeded 1-16 in team list order.

**T4 (Round Robin):** All 16 teams in single pool.

**T5 (2 groups x 8 teams):**
- Group A: Teams 1-8 (Bangalore through Jaipur)
- Group B: Teams 9-16 (Lucknow through Ranchi)

## Delivery Distribution (Random Scoring)

| Outcome | Weight | Probability |
|---------|--------|-------------|
| Dot (0) | 30 | 30% |
| Single (1) | 25 | 25% |
| Double (2) | 15 | 15% |
| Triple (3) | 5 | 5% |
| Four (4) | 10 | 10% |
| Six (6) | 5 | 5% |
| Wicket | 5 | 5% |
| Wide | 3 | 3% |
| No-ball | 2 | 2% |

**Wicket types (equal probability):** Bowled, Caught, LBW, Run Out, Stumped, Hit Wicket, C&B.

## Quick Manual Test Sessions

### Session 1: Core Flow Verification (~15 min)
Before running overnight automation, manually verify on emulator:
1. Log in with test phone 9999999999
2. Create one team ("Test Team") with 6 players
3. Create a standalone match (5 overs)
4. Complete toss, score 2-3 overs
5. Verify scoring controls work, bowler rotation triggers
6. Verify match appears in "My Cricket" tab

### Session 2: Edge Cases (~10 min)
1. Score a wide followed by a no-ball (extras panel)
2. Take a wicket (Bowled) - verify new batter selection sheet
3. Verify last wicket triggers innings transition
4. Score target chase - verify match completion

### Session 3: Bowl-First Scenario (~10 min)
1. Create match, toss winner chooses to Field
2. Verify batting team is correct (toss loser bats first)
3. Score through innings transition
4. Verify correct teams batting in each innings

### Session 4: Persistence (~5 min)
1. Close and reopen app
2. Verify completed match still visible in match list
3. Verify scorecard shows correct data

## Execution Commands

```bash
# 1. Start emulator
emulator -avd <avd_name> &

# 2. Build prod debug APK
cd apps/mobile
flutter build apk --flavor prod --debug --dart-define=FLAVOR=prod

# 3. Create teams (one-time, ~5 min)
flutter test --flavor prod --dart-define=FLAVOR=prod \
  integration_test/prod/prod_team_setup_test.dart -d emulator-5554

# 4. Run tournaments sequentially (overnight)
# Option A: Individual
flutter test --flavor prod --dart-define=FLAVOR=prod \
  integration_test/prod/prod_tournament_1_test.dart -d emulator-5554

# Option B: Runner script (all 5 tournaments)
bash scripts/prod-e2e-overnight.sh
```

## Pass/Fail Criteria

### PASS
- All 16 teams created with 6 players each
- Each tournament completes all fixtures without crashes
- Match completion modals appear for every match
- No unhandled exceptions in test output
- Viewer can see tournaments and match scorecards on their device

### FAIL
- Test crashes mid-tournament (acceptable: re-run creates NEW tournament)
- Server returns 5xx errors during scoring
- Match gets stuck (no completion modal after all overs)
- Firebase auth fails on emulator

### WARN (investigate but don't block)
- Occasional wide/no-ball not registering (UI timing)
- Bowler selection falls back to "any available" (naming mismatch)
- Score totals differ by 1-2 runs (extras timing edge case)

## Viewer Verification Protocol

After overnight run completes, the viewer (phone 9999999998) should check:

1. **Tournaments tab:** 5 tournaments visible with correct names
2. **Each tournament:**
   - Standings tab shows correct team order (by points, then NRR)
   - Fixtures tab shows all matches as completed
   - Leaderboard shows top run-scorers and wicket-takers
3. **Any match scorecard:** Tap any completed match to verify:
   - Both innings shown with correct batting/bowling stats
   - Extras tallied (wides, no-balls)
   - Result displayed correctly
4. **Player profiles:** Tap any player name to verify career stats accumulated across tournaments
5. **Data integrity:** ~256 matches x ~60 deliveries avg = ~15,000 deliveries in prod DB

## Resumability

Each tournament test is **independent**:
- Teams discovered via API (by name match)
- If a tournament test crashes, re-run it -- creates a NEW tournament
- Previous tournament data is never touched
- Team setup only needs to run once (idempotent -- skips existing teams)
