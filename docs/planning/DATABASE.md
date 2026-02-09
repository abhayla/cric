# CricApp - Database Schema

## Overview

- **Server Database:** PostgreSQL (via Drizzle ORM)
- **Local Database:** SQLite (via Drift in Flutter)
- **Total Tables:** 22 core tables + 5 materialized views

---

## 1. Master Data Tables (Seeded Once)

### 1.1 `ball_types`
| Column | Type | Notes |
|--------|------|-------|
| id | serial PK | |
| name | varchar(50) | leather, tennis, tape, other |
| created_at | timestamp | default now() |

### 1.2 `dismissal_types`
12 standard cricket dismissal types.

| Column | Type | Notes |
|--------|------|-------|
| id | serial PK | |
| name | varchar(50) | e.g. "bowled", "caught", "lbw" |
| code | varchar(10) | e.g. "b", "c", "lbw" |
| requires_fielder | boolean | true for caught, run out, stumped |
| requires_bowler_credit | boolean | true for bowled, caught, lbw, stumped, hit wicket |
| created_at | timestamp | |

**Seed values:** bowled, caught, lbw, run_out, stumped, hit_wicket, caught_and_bowled, retired_hurt, retired_out, timed_out, obstructing_field, handled_ball

### 1.3 `fielding_positions`
16 standard cricket fielding positions.

| Column | Type | Notes |
|--------|------|-------|
| id | serial PK | |
| name | varchar(50) | e.g. "wicket-keeper", "slip", "gully" |
| code | varchar(10) | e.g. "wk", "sl", "gu" |
| created_at | timestamp | |

**Seed values:** wicket_keeper, first_slip, second_slip, third_slip, gully, point, cover, mid_off, mid_on, mid_wicket, square_leg, fine_leg, third_man, long_off, long_on, deep_mid_wicket

### 1.4 `wagon_wheel_zones`
12-zone system (30-degree segments, industry standard).

| Column | Type | Notes |
|--------|------|-------|
| id | serial PK | |
| zone_code | varchar(10) | e.g. "OF1", "OF2", "ON1", "ON2" |
| label | varchar(50) | e.g. "Cover Drive Region" |
| start_angle | integer | 0-360 degrees |
| end_angle | integer | 0-360 degrees |
| side | varchar(10) | "offside" or "onside" |
| created_at | timestamp | |

**Zone mapping (right-handed batter perspective):**
| Zone | Label | Angle Range | Side |
|------|-------|-------------|------|
| OF1 | Third Man | 0-30 | offside |
| OF2 | Point/Backward Point | 30-60 | offside |
| OF3 | Cover | 60-90 | offside |
| OF4 | Extra Cover | 90-120 | offside |
| OF5 | Mid Off | 120-150 | offside |
| OF6 | Straight (Off) | 150-180 | offside |
| ON1 | Straight (On) | 180-210 | onside |
| ON2 | Mid On | 210-240 | onside |
| ON3 | Mid Wicket | 240-270 | onside |
| ON4 | Square Leg | 270-300 | onside |
| ON5 | Fine Leg | 300-330 | onside |
| ON6 | Behind (Leg) | 330-360 | onside |

---

## 2. User & Team Tables

### 2.1 `users`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | default gen_random_uuid() |
| firebase_uid | varchar(128) UNIQUE | Firebase Auth UID |
| phone | varchar(15) | nullable |
| email | varchar(255) | nullable |
| display_name | varchar(100) | required |
| avatar_url | text | nullable |
| batting_style | varchar(20) | "right_hand", "left_hand" |
| bowling_style | varchar(30) | "right_arm_fast", "right_arm_medium", "right_arm_off_spin", "right_arm_leg_spin", "left_arm_fast", "left_arm_medium", "left_arm_orthodox", "left_arm_chinaman", "none" |
| player_role | varchar(20) | "batter", "bowler", "all_rounder", "wk_batter" |
| city | varchar(100) | nullable |
| created_at | timestamp | |
| updated_at | timestamp | |

### 2.2 `teams`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| name | varchar(100) | |
| logo_url | text | nullable |
| city | varchar(100) | nullable |
| created_by | uuid FK → users.id | Team owner |
| is_active | boolean | default true |
| created_at | timestamp | |
| updated_at | timestamp | |

### 2.3 `team_rosters`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| team_id | uuid FK → teams.id | |
| player_id | uuid FK → users.id | |
| jersey_number | integer | nullable |
| role | varchar(20) | "captain", "vice_captain", "player" |
| is_active | boolean | default true |
| joined_at | timestamp | |

**Unique constraint:** (team_id, player_id)
**Max roster size:** 25 players per team (enforced at application level)

### 2.4 `match_players`
Playing XI for each team in a specific match.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| match_id | uuid FK → matches.id | |
| team_id | uuid FK → teams.id | |
| player_id | uuid FK → users.id | |
| batting_order | integer | nullable (set when player comes in to bat) |
| is_playing | boolean | default true |
| is_captain | boolean | default false |
| is_keeper | boolean | default false |
| created_at | timestamp | |
| updated_at | timestamp | |

**Unique constraint:** (match_id, team_id, player_id)
**Max per team per match:** 11 players (enforced at application level)

---

## 3. Match Structure Tables

### 3.1 `matches`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| home_team_id | uuid FK → teams.id | |
| away_team_id | uuid FK → teams.id | |
| format | varchar(20) | "T20", "ODI", "custom" |
| total_overs | integer | e.g. 20, 50, any custom number. Valid range: 1-50 |
| ball_type_id | integer FK → ball_types.id | |
| venue | varchar(200) | nullable |
| toss_winner_id | uuid FK → teams.id | nullable (set after toss) |
| toss_decision | varchar(10) | "bat" or "bowl" (nullable) |
| status | varchar(20) | "setup", "toss", "live", "innings_break", "completed", "abandoned" |
| scorer_id | uuid FK → users.id | Who is scoring this match |
| created_by | uuid FK → users.id | |
| match_date | date | |
| created_at | timestamp | |
| updated_at | timestamp | |

### 3.2 `innings`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| match_id | uuid FK → matches.id | |
| innings_number | integer | 1 or 2 |
| batting_team_id | uuid FK → teams.id | |
| bowling_team_id | uuid FK → teams.id | |
| total_runs | integer | default 0 |
| total_wickets | integer | default 0 |
| total_overs | decimal(5,1) | e.g. 12.3 |
| total_extras | integer | default 0 |
| total_wides | integer | default 0 |
| total_no_balls | integer | default 0 |
| total_byes | integer | default 0 |
| total_leg_byes | integer | default 0 |
| is_completed | boolean | default false |
| completed_reason | varchar(30) | "all_out", "overs_exhausted", "target_chased", "declared" |
| target | integer | nullable (set for 2nd innings) |
| run_rate | decimal(5,2) | computed: total_runs / total_overs |
| dot_ball_percentage | decimal(5,2) | computed: dot balls / total legal deliveries * 100 |
| boundary_percentage | decimal(5,2) | computed: (fours + sixes) / total legal deliveries * 100 |
| created_at | timestamp | |
| updated_at | timestamp | |

### 3.3 `overs`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| innings_id | uuid FK → innings.id | |
| over_number | integer | 1-based |
| bowler_id | uuid FK → users.id | |
| runs_conceded | integer | default 0 |
| wickets_taken | integer | default 0 |
| wides | integer | default 0 |
| no_balls | integer | default 0 |
| is_maiden | boolean | default false |
| is_completed | boolean | default false |
| created_at | timestamp | |
| updated_at | timestamp | |

### 3.4 `deliveries` -- ATOMIC UNIT (most important table)
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| innings_id | uuid FK → innings.id | |
| over_number | integer | 1-based over |
| ball_number | integer | 1-6 for legal deliveries |
| sequence_number | integer | auto-increment within innings (includes extras) |
| striker_id | uuid FK → users.id | |
| non_striker_id | uuid FK → users.id | |
| bowler_id | uuid FK → users.id | |
| runs_from_bat | integer | default 0 |
| is_wide | boolean | default false |
| wide_runs | integer | default 0 (typically 1) |
| is_no_ball | boolean | default false |
| no_ball_runs | integer | default 0 (typically 1) |
| is_bye | boolean | default false |
| bye_runs | integer | default 0 |
| is_leg_bye | boolean | default false |
| leg_bye_runs | integer | default 0 |
| total_runs | integer | computed: runs_from_bat + wide_runs + no_ball_runs + bye_runs + leg_bye_runs |
| is_wicket | boolean | default false |
| is_legal | boolean | true if not wide and not no-ball |
| is_boundary_four | boolean | default false |
| is_boundary_six | boolean | default false |
| is_free_hit | boolean | default false |
| wagon_wheel_zone_id | integer FK → wagon_wheel_zones.id | nullable |
| timestamp | timestamp | when this delivery was recorded |
| synced | boolean | default false (for offline sync) |
| created_at | timestamp | |
| updated_at | timestamp | |

---

## 4. Delivery Detail Tables

### 4.1 `wickets_by_delivery`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| delivery_id | uuid FK → deliveries.id | |
| dismissed_player_id | uuid FK → users.id | |
| dismissal_type_id | integer FK → dismissal_types.id | |
| fielder_id | uuid FK → users.id | nullable (needed for caught, run out, stumped) |
| bowler_credited | boolean | is the bowler credited with this wicket? |
| created_at | timestamp | |
| updated_at | timestamp | |

### 4.2 `fall_of_wickets`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| innings_id | uuid FK → innings.id | |
| wicket_number | integer | 1st, 2nd, 3rd... |
| runs_at_fall | integer | team score when wicket fell |
| overs_at_fall | decimal(5,1) | e.g. 8.3 |
| dismissed_player_id | uuid FK → users.id | |
| delivery_id | uuid FK → deliveries.id | |
| created_at | timestamp | |
| updated_at | timestamp | |

---

## 5. Stats Tables (Pre-computed per Innings)

### 5.1 `batting_stats`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| innings_id | uuid FK → innings.id | |
| player_id | uuid FK → users.id | |
| batting_position | integer | 1-11 |
| runs_scored | integer | default 0 |
| balls_faced | integer | default 0 |
| fours | integer | default 0 |
| sixes | integer | default 0 |
| strike_rate | decimal(6,2) | computed |
| is_not_out | boolean | default true |
| dismissal_type_id | integer FK → dismissal_types.id | nullable |
| dismissed_by_id | uuid FK → users.id | nullable (bowler) |
| fielder_id | uuid FK → users.id | nullable |
| is_retired_hurt | boolean | default false |
| minutes_batted | integer | nullable |
| created_at | timestamp | |
| updated_at | timestamp | |

### 5.2 `bowling_stats`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| innings_id | uuid FK → innings.id | |
| player_id | uuid FK → users.id | |
| overs_bowled | decimal(4,1) | e.g. 4.0 |
| maidens | integer | default 0 |
| runs_conceded | integer | default 0 |
| wickets_taken | integer | default 0 |
| economy_rate | decimal(5,2) | computed |
| wides | integer | default 0 |
| no_balls | integer | default 0 |
| dot_balls | integer | default 0 |
| fours_conceded | integer | default 0 |
| sixes_conceded | integer | default 0 |
| created_at | timestamp | |
| updated_at | timestamp | |

### 5.3 `fielding_stats`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| innings_id | uuid FK → innings.id | |
| player_id | uuid FK → users.id | |
| catches | integer | default 0 |
| run_outs | integer | default 0 |
| stumpings | integer | default 0 |
| direct_hits | integer | default 0 |
| created_at | timestamp | |
| updated_at | timestamp | |

---

## 6. Career & Results Tables

### 6.1 `player_career_stats`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| player_id | uuid FK → users.id | |
| format | varchar(20) | "T20", "ODI", "custom", "all" |
| matches_played | integer | default 0 |
| innings_batted | integer | default 0 |
| total_runs | integer | default 0 |
| highest_score | integer | default 0 |
| batting_average | decimal(6,2) | |
| batting_strike_rate | decimal(6,2) | |
| fifties | integer | default 0 |
| hundreds | integer | default 0 |
| fours | integer | default 0 |
| sixes | integer | default 0 |
| not_outs | integer | default 0 |
| innings_bowled | integer | default 0 |
| overs_bowled | decimal(6,1) | |
| runs_conceded | integer | default 0 |
| wickets_taken | integer | default 0 |
| bowling_average | decimal(6,2) | |
| bowling_economy | decimal(5,2) | |
| bowling_strike_rate | decimal(6,2) | |
| best_bowling_wickets | integer | default 0 |
| best_bowling_runs | integer | default 0 |
| three_wicket_hauls | integer | default 0 |
| five_wicket_hauls | integer | default 0 |
| catches | integer | default 0 |
| run_outs | integer | default 0 |
| stumpings | integer | default 0 |
| updated_at | timestamp | |

### 6.2 `match_result`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| match_id | uuid FK → matches.id | UNIQUE |
| winner_team_id | uuid FK → teams.id | nullable (tie/no result) |
| result_type | varchar(20) | "runs", "wickets", "tie", "no_result" |
| margin | integer | nullable (runs or wickets margin) |
| man_of_match_id | uuid FK → users.id | nullable |
| summary | text | e.g. "Team A won by 5 wickets" |
| created_at | timestamp | |

### 6.3 `match_analytics`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| match_id | uuid FK → matches.id | |
| manhattan_data | jsonb | `[{"over":1,"runs":8}, ...]` per innings |
| worm_data | jsonb | `[{"over":1,"cumulative":8}, ...]` per innings |
| mvp_scores | jsonb | `[{"playerId":"...","score":45.5,"breakdown":{...}}, ...]` |
| created_at | timestamp | |
| updated_at | timestamp | |

---

## 7. Materialized Views

### 7.1 `player_match_summary`
Quick player performance per match. Joins deliveries + batting_stats + bowling_stats.

### 7.2 `innings_scoreboard`
Scorecard view. Joins innings + batting_stats + bowling_stats + dismissal info.

### 7.3 `batting_innings_summary`
Batting card with dismissal description (e.g. "c Smith b Jones 45 (32)").

### 7.4 `bowling_innings_summary`
Bowling analysis card (e.g. "J Bumrah 4-0-22-2").

### 7.5 `player_season_stats`
Aggregated stats by format across all matches.

**Refresh trigger:** Auto-refresh after match status changes to "completed".

---

## 8. Key Design Decisions

| Decision | Choice | Why |
|----------|--------|-----|
| Ball-by-ball granularity | Every delivery stored | Enables any stat calculation, replay, analytics |
| Stats storage | Pre-computed per innings + career aggregates | Fast reads for profiles & scorecards |
| Graph data | JSONB in match_analytics | Flexible, avoid excessive joins |
| Wagon wheel zones | 12-zone system (30-degree segments) | Industry standard, matches CricHeroes |
| Offline sync | `synced` flag on deliveries + `sync_queue` table in SQLite | Track what needs pushing to server |
| Primary keys | UUIDs | Cross-device sync friendly, no conflicts |
| Timestamps | All tables have created_at + updated_at | Audit trail, sync ordering, conflict resolution |

---

## 9. Indexes (Performance)

```sql
-- Deliveries (most queried table)
CREATE INDEX idx_deliveries_innings ON deliveries(innings_id);
CREATE INDEX idx_deliveries_bowler ON deliveries(bowler_id);
CREATE INDEX idx_deliveries_striker ON deliveries(striker_id);
CREATE INDEX idx_deliveries_over ON deliveries(innings_id, over_number);
CREATE INDEX idx_deliveries_synced ON deliveries(synced) WHERE synced = false;

-- Stats
CREATE INDEX idx_batting_stats_innings ON batting_stats(innings_id);
CREATE INDEX idx_batting_stats_player ON batting_stats(player_id);
CREATE INDEX idx_bowling_stats_innings ON bowling_stats(innings_id);
CREATE INDEX idx_bowling_stats_player ON bowling_stats(player_id);

-- Career
CREATE INDEX idx_career_stats_player ON player_career_stats(player_id, format);

-- Matches
CREATE INDEX idx_matches_status ON matches(status);
CREATE INDEX idx_matches_teams ON matches(home_team_id, away_team_id);

-- Team rosters
CREATE INDEX idx_rosters_team ON team_rosters(team_id);
CREATE INDEX idx_rosters_player ON team_rosters(player_id);

-- Match players (Playing XI)
CREATE INDEX idx_match_players_match ON match_players(match_id);
CREATE INDEX idx_match_players_team ON match_players(match_id, team_id);
CREATE INDEX idx_match_players_player ON match_players(player_id);
```

---

## 10. SQLite Local Schema (Drift)

The local SQLite database mirrors a subset of the PostgreSQL schema for offline-first capability:

**Mirrored tables:** users, teams, team_rosters, match_players, matches, innings, overs, deliveries, batting_stats, bowling_stats

**Additional local-only tables:**

#### `sync_queue`
Pending operations to push to server.

| Column | Type | Notes |
|--------|------|-------|
| id | integer PK autoincrement | |
| entity_type | text NOT NULL | match, innings, delivery, batting_stats, etc. |
| entity_id | text NOT NULL | local UUID of the entity |
| operation | text NOT NULL | create, update, delete |
| payload | text NOT NULL | JSON blob of entity data |
| retry_count | integer | default 0 |
| status | text | default 'pending' — pending, syncing, synced, failed |
| created_at | timestamp | default CURRENT_TIMESTAMP |

#### `local_preferences`
App settings and cached auth state.

| Column | Type | Notes |
|--------|------|-------|
| key | text PK | |
| value | text NOT NULL | |

**Sync strategy:**
1. All writes go to local SQLite first
2. `synced` flag marks what has been pushed to server
3. Sync engine pushes pending items when connectivity is available
4. Server responds with server-generated IDs for mapping
