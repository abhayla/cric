# CricApp - API Design

## Overview

- **Framework:** ElysiaJS on Bun
- **Base URL:** `/api/v1`
- **Auth:** Firebase JWT tokens in `Authorization: Bearer <token>` header
- **Real-time:** Bun Native WebSockets at `/ws`
- **Format:** JSON request/response bodies

---

## 1. REST Endpoints

### 1.1 Auth

```
POST   /api/v1/auth/verify
```
Verify Firebase token, create or retrieve user record.

**Request:**
```json
{
  "idToken": "firebase_id_token_string"
}
```

**Response (200):**
```json
{
  "user": {
    "id": "uuid",
    "firebaseUid": "string",
    "displayName": "string",
    "phone": "string",
    "email": "string",
    "battingStyle": "right_hand",
    "bowlingStyle": "right_arm_fast",
    "playerRole": "all_rounder",
    "isNewUser": false
  }
}
```

---

```
PUT    /api/v1/auth/profile
```
Update user profile (batting style, bowling style, role, etc.).

**Request:**
```json
{
  "displayName": "Rohit Sharma",
  "battingStyle": "right_hand",
  "bowlingStyle": "right_arm_medium",
  "playerRole": "batter",
  "location": "Mumbai"
}
```

**Response (200):** Updated user object.

---

### 1.2 Teams

```
POST   /api/v1/teams
```
Create a new team. Authenticated user becomes team owner.

**Request:**
```json
{
  "name": "Mumbai Warriors",
  "location": "Mumbai",
  "logoUrl": "https://..."
}
```

**Response (201):** Team object with `id`.

---

```
GET    /api/v1/teams
```
List teams the authenticated user belongs to or created.

**Query params:** `?page=1&limit=20`

**Response (200):**
```json
{
  "teams": [
    {
      "id": "uuid",
      "name": "Mumbai Warriors",
      "location": "Mumbai",
      "logoUrl": "...",
      "playerCount": 15,
      "role": "owner"
    }
  ],
  "total": 3,
  "page": 1
}
```

---

```
GET    /api/v1/teams/:id
```
Get team details including roster.

**Response (200):**
```json
{
  "team": {
    "id": "uuid",
    "name": "Mumbai Warriors",
    "location": "Mumbai",
    "logoUrl": "...",
    "createdBy": "uuid",
    "roster": [
      {
        "playerId": "uuid",
        "displayName": "Rohit Sharma",
        "jerseyNumber": 45,
        "role": "captain",
        "battingStyle": "right_hand",
        "bowlingStyle": "right_arm_medium",
        "playerRole": "batter"
      }
    ]
  }
}
```

---

```
PUT    /api/v1/teams/:id
```
Update team info. Only team owner/captain.

**Request:**
```json
{
  "name": "Mumbai Warriors Updated",
  "location": "Pune",
  "logoUrl": "https://..."
}
```
All fields optional — only provided fields are updated.

**Response (200):** Updated team object.

---

```
DELETE /api/v1/teams/:id
```
Soft delete a team. Sets `is_active=false`. Only team owner or captain.

**Response (200):**
```json
{
  "message": "Team deleted successfully"
}
```

**Error (403):** Not authorized (not owner or captain).

---

```
POST   /api/v1/teams/:id/players
```
Add player to team roster.

**Request:**
```json
{
  "playerId": "uuid",
  "jerseyNumber": 18,
  "role": "player"
}
```

---

```
DELETE /api/v1/teams/:id/players/:pid
```
Remove player from roster. Only team owner/captain.

**Response (200):**
```json
{
  "message": "Player removed from roster"
}
```

---

### 1.3 Matches

```
POST   /api/v1/matches
```
Create a new match.

**Request:**
```json
{
  "homeTeamId": "uuid",
  "awayTeamId": "uuid",
  "format": "T20",
  "totalOvers": 20,
  "ballTypeId": 1,
  "venue": "Wankhede Stadium",
  "matchDate": "2025-03-15"
}
```

**Response (201):** Match object with status "setup".

---

```
GET    /api/v1/matches
```
List matches the user is involved in (as scorer, player, or team member).

**Query params:** `?status=live&page=1&limit=20`

**Response (200):**
```json
{
  "matches": [
    {
      "id": "uuid",
      "homeTeam": { "id": "uuid", "name": "Mumbai Warriors" },
      "awayTeam": { "id": "uuid", "name": "Delhi Dragons" },
      "format": "T20",
      "totalOvers": 20,
      "status": "live",
      "matchDate": "2025-03-15",
      "venue": "Wankhede Stadium",
      "currentInnings": {
        "battingTeam": "Mumbai Warriors",
        "totalRuns": 87,
        "totalWickets": 3,
        "overs": "12.3"
      },
      "result": null
    }
  ],
  "total": 15,
  "page": 1
}
```

---

```
GET    /api/v1/matches/:id
```
Get match details including current state.

**Response (200):**
```json
{
  "match": {
    "id": "uuid",
    "homeTeam": { "id": "uuid", "name": "..." },
    "awayTeam": { "id": "uuid", "name": "..." },
    "format": "T20",
    "totalOvers": 20,
    "status": "live",
    "tossWinner": { "id": "uuid", "name": "..." },
    "tossDecision": "bat",
    "currentInnings": {
      "inningsNumber": 1,
      "battingTeam": "...",
      "totalRuns": 87,
      "totalWickets": 3,
      "overs": "12.3",
      "runRate": 6.96
    },
    "superOvers": [
      {
        "superOverNumber": 1,
        "innings": [
          {
            "battingTeam": "Mumbai Warriors",
            "totalRuns": 15,
            "totalWickets": 1,
            "overs": "1.0"
          },
          {
            "battingTeam": "Delhi Dragons",
            "totalRuns": 12,
            "totalWickets": 2,
            "overs": "0.5"
          }
        ]
      }
    ]
  }
}
```

The `superOvers` array is only present when the match has super over innings (`innings.is_super_over = true`). Empty array or omitted for matches without super overs.

---

```
PUT    /api/v1/matches/:id/toss
```
Record toss result and select opening players. Transitions match status from `toss` to `live`.

**Request:**
```json
{
  "winnerId": "team_uuid",
  "decision": "bat",
  "openingStrikerId": "uuid",
  "openingNonStrikerId": "uuid",
  "openingBowlerId": "uuid"
}
```

**Response (200):** Updated match object with status `live`, first innings created.

**Errors:**
- `400` — Opening players not in the match's playing XI.
- `400` — Opening bowler is from the batting team.
- `400` — Striker and non-striker are the same player.

---

```
POST   /api/v1/matches/:id/playing-xi
```
Select the playing XI for one team in a match. Must be called for both teams before toss.

**Request:**
```json
{
  "teamId": "uuid",
  "playerIds": ["uuid", "uuid", "...11 player UUIDs"],
  "captainId": "uuid",
  "keeperId": "uuid"
}
```

**Response (201):**
```json
{
  "matchId": "uuid",
  "teamId": "uuid",
  "players": [
    {
      "playerId": "uuid",
      "displayName": "Rohit Sharma",
      "isCaptain": true,
      "isKeeper": false
    }
  ]
}
```

**Errors:**
- `400` — `playerIds` must contain exactly 11 UUIDs.
- `400` — `captainId` / `keeperId` must be in `playerIds`.
- `400` — One or more players not in the team roster.
- `409` — Playing XI already submitted for this team in this match.

---

```
PUT    /api/v1/matches/:id/status
```
Update match status.

**Request:**
```json
{
  "status": "live"
}
```

Valid transitions: `setup → toss → live → innings_break → live → completed`

---

```
POST   /api/v1/matches/:id/abandon
```
Abandon a match. Sets status to ABANDONED. Only the scorer.

**Response (200):** Updated match object with status `abandoned` and `match_result` with `result_type = 'no_result'`.

**Errors:**
- `403` — Not the match scorer.
- `409` — Match already completed or abandoned.

---

```
POST   /api/v1/matches/:id/declare
```
Declare the current innings (voluntary end). Only the scorer.

**Response (200):** Updated match object. Current innings marked completed with `completed_reason = 'declared'`.

**Errors:**
- `403` — Not the match scorer.
- `400` — Match not in LIVE state.

---

```
POST   /api/v1/matches/:id/reopen
```
Reopen a completed innings or match. Only the scorer.

**Request:**
```json
{
  "target": "innings"
}
```

`target` values: `"innings"` (reopen last completed innings) or `"match"` (reopen completed match, removes `match_result`).

**Response (200):** Updated match object with reopened state.

**Errors:**
- `403` — Not the match scorer.
- `400` — Invalid target or nothing to reopen.

---

```
POST   /api/v1/matches/:id/super-over
```
Create a super over innings pair for a tied knockout match. Only the scorer.

**Response (201):** Two new innings records with `is_super_over = true`, `super_over_number` auto-incremented.

**Errors:**
- `403` — Not the match scorer.
- `400` — Match is not tied or not a knockout fixture.

---

```
PUT    /api/v1/matches/:id/scorer
```
Transfer scorer role to another user. Only the current scorer.

**Request:**
```json
{
  "scorerId": "uuid"
}
```

**Response (200):** Updated match object with new `scorerId`.

**Errors:**
- `403` — Not the current scorer.
- `400` — New scorer not found or not a valid user.

---

```
GET    /api/v1/matches/:id/scorecard
```
Full scorecard with batting and bowling cards for all innings.

**Response (200):**
```json
{
  "match": { "..." },
  "innings": [
    {
      "inningsNumber": 1,
      "battingTeam": "...",
      "total": "156/7 (20.0 ov)",
      "batting": [
        {
          "name": "R. Sharma",
          "dismissal": "c Kohli b Bumrah",
          "runs": 45,
          "balls": 32,
          "fours": 5,
          "sixes": 2,
          "strikeRate": 140.63
        }
      ],
      "bowling": [
        {
          "name": "J. Bumrah",
          "overs": "4.0",
          "maidens": 1,
          "runs": 22,
          "wickets": 2,
          "economy": 5.50
        }
      ],
      "extras": { "total": 8, "wides": 3, "noBalls": 2, "byes": 1, "legByes": 2 },
      "fallOfWickets": [
        { "wicket": 1, "runs": 23, "overs": "3.4", "batter": "S. Dhawan" }
      ]
    }
  ]
}
```

---

### 1.4 Scoring (REST — Primary Write Path)

REST is the **primary write path** for all scoring mutations. The scorer's app records deliveries locally, then syncs via REST. WebSocket is **broadcast-only** (read path for viewers). This eliminates the risk of duplicate deliveries from dual REST+WS write paths.

```
POST   /api/v1/matches/:id/deliveries
```
Record a delivery.

**Request:**
```json
{
  "overNumber": 5,
  "ballNumber": 3,
  "strikerId": "uuid",
  "nonStrikerId": "uuid",
  "bowlerId": "uuid",
  "runsFromBat": 4,
  "isWide": false,
  "isNoBall": false,
  "isBye": false,
  "isLegBye": false,
  "wideRuns": 0,
  "noBallRuns": 0,
  "byeRuns": 0,
  "legByeRuns": 0,
  "isWicket": false,
  "isBoundaryFour": true,
  "isBoundarySix": false,
  "wicket": null
}
```

> **Note:** `wagonWheelZoneId` is deferred to post-MVP. Wagon wheel visualization will estimate shot direction from run count and shot type.

**Wicket object (when `isWicket` is true):**
```json
{
  "wicket": {
    "dismissedPlayerId": "uuid",
    "dismissalTypeId": 2,
    "fielderId": "uuid",
    "bowlerCredited": true
  }
}
```

---

```
DELETE /api/v1/matches/:id/deliveries/:did
```
Undo last delivery. Only allowed for the most recent delivery.

---

```
GET    /api/v1/matches/:id/deliveries
```
Get deliveries for a match with required innings filter and offset pagination.

**Query params:** `?inningsId=uuid&page=1&limit=50`

- `inningsId` — **Required.** UUID of the innings to fetch deliveries for.
- `page` — Page number, default 1.
- `limit` — Items per page, default 50, max 100.

**Response (200):**
```json
{
  "deliveries": [ { "...delivery fields..." } ],
  "total": 120,
  "page": 1
}
```

**Usage:** Commentary tab uses infinite scroll loading older pages. Scoring page "current over" is derived from local ScoringState (no API call).

---

### 1.5 Players

```
GET    /api/v1/players/search
```
Search players by name. Case-insensitive partial match.

**Query params:** `?q=<name>&limit=10`

**Response (200):**
```json
{
  "players": [
    {
      "id": "uuid",
      "displayName": "Rohit Sharma",
      "battingStyle": "right_hand",
      "bowlingStyle": "right_arm_medium",
      "location": "Mumbai"
    }
  ]
}
```

---

```
GET    /api/v1/players/:id
```
Get player profile.

**Response (200):**
```json
{
  "player": {
    "id": "uuid",
    "displayName": "Rohit Sharma",
    "phone": "string",
    "email": "string",
    "battingStyle": "right_hand",
    "bowlingStyle": "right_arm_medium",
    "playerRole": "batter",
    "location": "Mumbai",
    "avatarUrl": "https://...",
    "teams": [
      { "id": "uuid", "name": "Mumbai Warriors", "role": "captain" }
    ]
  }
}
```

---

```
GET    /api/v1/players/:id/stats
```
Career stats (batting, bowling, fielding).

**Query params:** `?format=T20` (optional filter)

**Response (200):**
```json
{
  "player": { "..." },
  "stats": {
    "batting": {
      "matches": 45,
      "innings": 42,
      "runs": 1250,
      "highestScore": 98,
      "average": 32.05,
      "strikeRate": 135.87,
      "fifties": 8,
      "hundreds": 0,
      "fours": 120,
      "sixes": 45,
      "notOuts": 3
    },
    "bowling": {
      "innings": 30,
      "overs": 95.3,
      "runs": 680,
      "wickets": 38,
      "average": 17.89,
      "economy": 7.12,
      "strikeRate": 15.08,
      "bestBowling": "4/22",
      "threeWicketHauls": 5,
      "fiveWicketHauls": 0
    },
    "fielding": {
      "catches": 22,
      "runOuts": 5,
      "stumpings": 0
    }
  }
}
```

---

```
GET    /api/v1/players/:id/matches
```
Match history for a player.

**Query params:** `?page=1&limit=20&format=T20`

---

### 1.6 Analytics

```
GET    /api/v1/matches/:id/analytics/wagon-wheel/:batterId
```
Wagon wheel shot data for a specific batter in a match.

**Response (200):**
```json
{
  "batterId": "uuid",
  "batterName": "R. Sharma",
  "shots": [
    {
      "zoneCode": "OF3",
      "label": "Cover",
      "runs": 4,
      "isBoundary": true,
      "deliveryNumber": 15
    }
  ],
  "zoneSummary": [
    { "zoneCode": "OF3", "totalRuns": 28, "shotCount": 8 }
  ]
}
```

---

```
GET    /api/v1/matches/:id/analytics/manhattan/:inningsId
```
Manhattan chart data (runs scored per over).

**Response (200):**
```json
{
  "inningsId": "uuid",
  "overs": [
    { "overNumber": 1, "runs": 8, "wickets": 0 },
    { "overNumber": 2, "runs": 12, "wickets": 1 }
  ]
}
```

---

```
GET    /api/v1/matches/:id/analytics/worm
```
Worm graph data (cumulative runs for both innings).

**Response (200):**
```json
{
  "innings1": {
    "team": "Mumbai Warriors",
    "data": [
      { "over": 1, "cumulative": 8 },
      { "over": 2, "cumulative": 20 }
    ]
  },
  "innings2": {
    "team": "Delhi Dragons",
    "data": [
      { "over": 1, "cumulative": 6 },
      { "over": 2, "cumulative": 15 }
    ]
  }
}
```

---

```
GET    /api/v1/matches/:id/analytics/mvp
```
MVP rankings for the match.

**Response (200):**
```json
{
  "mvpRankings": [
    {
      "rank": 1,
      "playerId": "uuid",
      "playerName": "R. Sharma",
      "team": "Mumbai Warriors",
      "totalScore": 45.5,
      "breakdown": {
        "battingPoints": 32.0,
        "bowlingPoints": 8.5,
        "fieldingPoints": 5.0
      }
    }
  ]
}
```

---

### 1.7 Sync (Offline)

```
POST   /api/v1/sync/push
```
Push offline changes to server. Accepts all scoring entities in a single call.

**Request:**
```json
{
  "deliveries": [
    { "localId": "local_uuid", "...delivery_data..." }
  ],
  "innings": [
    { "localId": "local_uuid", "...innings_data..." }
  ],
  "battingStats": [
    { "localId": "local_uuid", "...batting_stats_data..." }
  ],
  "bowlingStats": [
    { "localId": "local_uuid", "...bowling_stats_data..." }
  ],
  "fieldingStats": [
    { "localId": "local_uuid", "...fielding_stats_data..." }
  ],
  "fallOfWickets": [
    { "localId": "local_uuid", "...fow_data..." }
  ],
  "overs": [
    { "localId": "local_uuid", "...overs_data..." }
  ],
  "matchPlayers": [
    { "localId": "local_uuid", "...match_players_data..." }
  ],
  "matchResult": { "localId": "local_uuid", "...match_result_data..." },
  "timestamp": "2025-03-15T10:30:00Z"
}
```

All entity arrays are optional — only include entities that have pending changes.

**Batching rules:**
- Single endpoint accepts all entity types in one request.
- Server processes entities in dependency order: match → innings → deliveries → stats → fallOfWickets → overs → matchResult.
- Maximum 50 deliveries per request. If pending deliveries > 50, split into multiple requests with deliveries batched; other entity types (innings, stats, etc.) sent only in the first request.
- `matchResult` is a single object (not array) — null when no result to sync.

**Response (200):**
```json
{
  "synced": 15,
  "idMappings": [
    { "localId": "local_uuid", "serverId": "server_uuid", "entityType": "delivery" }
  ],
  "conflicts": [
    {
      "entityType": "innings",
      "entityId": "uuid",
      "serverVersion": { "...server_entity_data..." },
      "serverUpdatedAt": "2025-03-15T10:32:00Z",
      "resolution": "server_wins"
    }
  ]
}
```

---

```
GET    /api/v1/sync/pull?since=timestamp
```
Pull changes since last sync.

**Response (200):**
```json
{
  "deliveries": [
    {
      "id": "uuid",
      "inningsId": "uuid",
      "overNumber": 5,
      "ballNumber": 3,
      "sequenceNumber": 28,
      "strikerId": "uuid",
      "nonStrikerId": "uuid",
      "bowlerId": "uuid",
      "runsFromBat": 4,
      "isWide": false,
      "isNoBall": false,
      "isBye": false,
      "isLegBye": false,
      "wideRuns": 0,
      "noBallRuns": 0,
      "byeRuns": 0,
      "legByeRuns": 0,
      "totalRuns": 4,
      "isWicket": false,
      "isLegal": true,
      "isBoundaryFour": true,
      "isBoundarySix": false,
      "isFreeHit": false,
      "timestamp": "2025-03-15T10:30:00Z"
    }
  ],
  "matches": [
    {
      "id": "uuid",
      "status": "live",
      "tossWinnerId": "uuid",
      "tossDecision": "bat",
      "updatedAt": "2025-03-15T10:35:00Z"
    }
  ],
  "innings": [
    {
      "id": "uuid",
      "matchId": "uuid",
      "inningsNumber": 1,
      "battingTeamId": "uuid",
      "bowlingTeamId": "uuid",
      "totalRuns": 87,
      "totalWickets": 3,
      "totalOvers": "12.3",
      "isCompleted": false,
      "updatedAt": "2025-03-15T10:35:00Z"
    }
  ],
  "battingStats": [
    {
      "id": "uuid",
      "inningsId": "uuid",
      "playerId": "uuid",
      "runsScored": 45,
      "ballsFaced": 32,
      "fours": 5,
      "sixes": 2,
      "isNotOut": true,
      "updatedAt": "2025-03-15T10:35:00Z"
    }
  ],
  "bowlingStats": [
    {
      "id": "uuid",
      "inningsId": "uuid",
      "playerId": "uuid",
      "oversBowled": "3.3",
      "maidens": 0,
      "runsConceded": 22,
      "wicketsTaken": 1,
      "updatedAt": "2025-03-15T10:35:00Z"
    }
  ],
  "updatedAt": "2025-03-15T10:35:00Z"
}
```

#### Sync Conflict Resolution

**Strategy:** Last-write-wins using `updated_at` timestamps. Server is authoritative.

- When the same entity is modified both locally and on the server, the server's `updated_at` wins.
- The `conflicts[]` array in the sync push response includes the server's version of conflicted entities so the client can update its local copy.
- Single-scorer model means conflicts are extremely rare (only possible for match setup edits from multiple devices).
- Client behavior on conflict: silently accept server version, update local DB, continue.

---

### 1.8 Health

```
GET    /api/v1/health
```

**Response (200):**
```json
{
  "status": "ok",
  "version": "0.1.0",
  "uptime": 3600,
  "database": "connected"
}
```

---

### 1.9 Uploads

```
POST   /api/v1/uploads/image
```
Upload an image (team logos). Auth required. Multipart/form-data.

**Constraints:**
- Max file size: 2MB
- Accepted types: JPEG, PNG only
- Server-side processing: compress to max 200x200px, < 100KB

**Storage:** VPS filesystem at `C:\Apps\uploads\teams\{uuid}.jpg`, served via Nginx static file config.

**Request:** `multipart/form-data` with `image` field.

**Response (201):**
```json
{
  "url": "https://domain.com/uploads/teams/{uuid}.jpg"
}
```

**Errors:**
- `400` — File exceeds 2MB or unsupported format.
- `401` — Not authenticated.

---

### 1.10 Tournaments

```
POST   /api/v1/tournaments
```
Create a new tournament. Authenticated user becomes the organizer.

**Request:**
```json
{
  "name": "Weekend Warriors Cup",
  "format": "group_knockout",
  "oversPerMatch": 20,
  "ballTypeId": 1,
  "pointsWin": 2,
  "pointsTie": 1,
  "pointsNoResult": 1,
  "pointsLoss": 0,
  "numGroups": 2,
  "qualifyPerGroup": 2,
  "hasThirdPlaceMatch": false,
  "startDate": "2026-03-01",
  "endDate": "2026-03-15",
  "playersPerSide": 11,
  "maxOversPerBowler": null,
  "wideRuns": 1,
  "noBallRuns": 1,
  "powerplayOvers": null
}
```

New optional fields (match rules template):
- `playersPerSide` — integer, default 11, range 2-11. Flexible team sizes (6-a-side, 8-a-side, etc.)
- `maxOversPerBowler` — integer or null, range 1-50. NULL = use default formula ceil(totalOvers/5)
- `wideRuns` — integer, default 1, range 1-5. Runs penalized per wide delivery
- `noBallRuns` — integer, default 1, range 1-5. Runs penalized per no-ball delivery
- `powerplayOvers` — integer or null, range 1-oversPerMatch. NULL = no powerplay

**Response (201):**
```json
{
  "tournament": {
    "id": "uuid",
    "name": "Weekend Warriors Cup",
    "format": "group_knockout",
    "oversPerMatch": 20,
    "ballTypeId": 1,
    "status": "draft",
    "pointsWin": 2,
    "pointsTie": 1,
    "pointsNoResult": 1,
    "pointsLoss": 0,
    "numGroups": 2,
    "qualifyPerGroup": 2,
    "hasThirdPlaceMatch": false,
    "playersPerSide": 11,
    "maxOversPerBowler": null,
    "wideRuns": 1,
    "noBallRuns": 1,
    "powerplayOvers": null,
    "createdBy": "uuid",
    "startDate": "2026-03-01",
    "endDate": "2026-03-15",
    "createdAt": "2026-02-10T10:00:00Z"
  }
}
```

**Errors:**
- `400` — Invalid format (must be "round_robin", "knockout", or "group_knockout").
- `400` — `oversPerMatch` outside 1-50 range.
- `400` — `numGroups` required when format is "group_knockout".
- `400` — `playersPerSide` outside 2-11 range.
- `400` — `maxOversPerBowler` outside 1-50 range (when provided).
- `400` — `powerplayOvers` exceeds `oversPerMatch` (when provided).

---

```
GET    /api/v1/tournaments
```
List tournaments the authenticated user created or has teams participating in.

**Query params:** `?status=live&page=1&limit=20`

**Response (200):**
```json
{
  "tournaments": [
    {
      "id": "uuid",
      "name": "Weekend Warriors Cup",
      "format": "group_knockout",
      "oversPerMatch": 20,
      "status": "live",
      "teamCount": 8,
      "startDate": "2026-03-01",
      "endDate": "2026-03-15"
    }
  ],
  "total": 5,
  "page": 1
}
```

---

```
GET    /api/v1/tournaments/:id
```
Get tournament details including teams, groups, and configuration.

**Response (200):**
```json
{
  "tournament": {
    "id": "uuid",
    "name": "Weekend Warriors Cup",
    "format": "group_knockout",
    "oversPerMatch": 20,
    "ballTypeId": 1,
    "status": "live",
    "pointsWin": 2,
    "pointsTie": 1,
    "pointsNoResult": 1,
    "pointsLoss": 0,
    "numGroups": 2,
    "qualifyPerGroup": 2,
    "hasThirdPlaceMatch": false,
    "playersPerSide": 11,
    "maxOversPerBowler": null,
    "wideRuns": 1,
    "noBallRuns": 1,
    "powerplayOvers": null,
    "createdBy": "uuid",
    "startDate": "2026-03-01",
    "endDate": "2026-03-15",
    "teams": [
      {
        "teamId": "uuid",
        "teamName": "Mumbai Warriors",
        "groupName": "A",
        "seedNumber": 1
      }
    ],
    "groups": [
      { "name": "A", "teamCount": 4 },
      { "name": "B", "teamCount": 4 }
    ]
  }
}
```

---

```
PUT    /api/v1/tournaments/:id
```
Update tournament settings. Only the organizer. Only allowed when status is "draft" or "registration".

**Request:**
```json
{
  "name": "Updated Cup Name",
  "oversPerMatch": 10,
  "pointsWin": 3,
  "startDate": "2026-03-05",
  "playersPerSide": 8,
  "maxOversPerBowler": 4,
  "wideRuns": 2,
  "noBallRuns": 1,
  "powerplayOvers": 4
}
```
All fields optional — only provided fields are updated. Includes the 5 match rule template fields.

**Response (200):** Updated tournament object.

**Errors:**
- `403` — Not the tournament organizer.
- `409` — Cannot update settings after tournament is "live" or "completed".

---

```
PUT    /api/v1/tournaments/:id/status
```
Transition tournament status.

**Request:**
```json
{
  "status": "live"
}
```

Valid transitions: `draft → registration → live → completed`

**Errors:**
- `400` — Invalid transition (e.g., draft → live).
- `400` — Cannot move to "live" without at least 2 teams and generated fixtures.
- `403` — Not the tournament organizer.

**Response (200):** Updated tournament object with new status.

---

```
POST   /api/v1/tournaments/:id/teams
```
Add a team to the tournament directly (organizer bypass). Only the organizer. Only allowed when status is "draft" or "registration". Bypasses the registration request flow.

**Request:**
```json
{
  "teamId": "uuid",
  "groupName": "A",
  "seedNumber": 1
}
```

**Response (201):**
```json
{
  "tournamentId": "uuid",
  "teamId": "uuid",
  "teamName": "Mumbai Warriors",
  "groupName": "A",
  "seedNumber": 1,
  "joinedAt": "2026-02-10T12:00:00Z"
}
```

**Errors:**
- `400` — Team already in tournament.
- `400` — Team roster has fewer than `playersPerSide` members.
- `403` — Not the tournament organizer.
- `409` — Cannot add teams after tournament is "live".

---

```
POST   /api/v1/tournaments/:id/register
```
Team requests to join a tournament. Requires tournament status = "registration". The requesting user must be a captain or admin of the team.

**Request:**
```json
{
  "teamId": "uuid"
}
```

**Response (201):**
```json
{
  "request": {
    "id": "uuid",
    "tournamentId": "uuid",
    "teamId": "uuid",
    "teamName": "Mumbai Warriors",
    "requestedBy": "uuid",
    "status": "pending",
    "requestedAt": "2026-02-10T12:00:00Z"
  }
}
```

**Errors:**
- `400` — Tournament status is not "registration".
- `400` — Team roster has fewer than `playersPerSide` members. Error message: "Team must have at least {n} players in roster".
- `400` — Requesting user is not team captain or admin.
- `409` — Team already has a pending or approved request for this tournament.
- `409` — Team is already registered in this tournament.

---

```
GET    /api/v1/tournaments/:id/requests
```
List registration requests for a tournament. Only the organizer.

**Query params:** `?status=pending` (optional filter: "pending", "approved", "rejected")

**Response (200):**
```json
{
  "requests": [
    {
      "id": "uuid",
      "teamId": "uuid",
      "teamName": "Mumbai Warriors",
      "teamCity": "Mumbai",
      "rosterCount": 15,
      "requestedBy": "uuid",
      "requestedByName": "Rohit Sharma",
      "status": "pending",
      "rejectionReason": null,
      "requestedAt": "2026-02-10T12:00:00Z",
      "resolvedAt": null
    }
  ],
  "total": 5
}
```

**Errors:**
- `403` — Not the tournament organizer.

---

```
PUT    /api/v1/tournaments/:id/requests/:requestId
```
Approve or reject a registration request. Only the organizer.

**Request (approve):**
```json
{
  "status": "approved",
  "groupName": "A",
  "seedNumber": 1
}
```

**Request (reject):**
```json
{
  "status": "rejected",
  "rejectionReason": "Team roster is incomplete"
}
```

**Response (200):**
```json
{
  "request": {
    "id": "uuid",
    "tournamentId": "uuid",
    "teamId": "uuid",
    "teamName": "Mumbai Warriors",
    "status": "approved",
    "resolvedAt": "2026-02-10T14:00:00Z"
  }
}
```

On approval: auto-inserts team into `tournament_teams` and sets `resolved_at`.
On rejection: sets `status = "rejected"`, `resolved_at`, and optional `rejection_reason`.

**Errors:**
- `400` — Invalid status (must be "approved" or "rejected").
- `400` — Request is not in "pending" status.
- `403` — Not the tournament organizer.
- `404` — Request not found.

---

```
DELETE /api/v1/tournaments/:id/teams/:teamId
```
Remove a team from the tournament. Only the organizer. Only allowed when status is "draft" or "registration".

**Response (200):**
```json
{
  "message": "Team removed from tournament"
}
```

**Errors:**
- `403` — Not the tournament organizer.
- `409` — Cannot remove teams after tournament is "live".

---

```
POST   /api/v1/tournaments/:id/fixtures/generate
```
Auto-generate fixtures based on tournament format and registered teams. Only the organizer.

**Request:** (no body required — generates based on current teams and format)

**Response (201):**
```json
{
  "fixtures": [
    {
      "id": "uuid",
      "roundNumber": 1,
      "roundType": "group",
      "fixtureOrder": 1,
      "groupName": "A",
      "homeTeamId": "uuid",
      "homeTeamName": "Mumbai Warriors",
      "awayTeamId": "uuid",
      "awayTeamName": "Delhi Strikers",
      "scheduledDate": null,
      "venue": null
    }
  ],
  "totalFixtures": 12
}
```

**Errors:**
- `400` — Not enough teams to generate fixtures (minimum 2).
- `403` — Not the tournament organizer.
- `409` — Fixtures already generated (delete existing fixtures first or use edit).

---

```
GET    /api/v1/tournaments/:id/fixtures
```
List all fixtures for a tournament.

**Query params:** `?roundType=group&groupName=A`

**Response (200):**
```json
{
  "fixtures": [
    {
      "id": "uuid",
      "roundNumber": 1,
      "roundType": "group",
      "fixtureOrder": 1,
      "groupName": "A",
      "homeTeam": { "id": "uuid", "name": "Mumbai Warriors" },
      "awayTeam": { "id": "uuid", "name": "Delhi Strikers" },
      "matchId": "uuid",
      "scheduledDate": "2026-03-01",
      "scheduledTime": "09:00",
      "estimatedDurationMinutes": 180,
      "venue": "Shivaji Park",
      "result": {
        "winner": "Mumbai Warriors",
        "summary": "Mumbai Warriors won by 5 wickets"
      }
    }
  ],
  "total": 12
}
```

---

```
PUT    /api/v1/tournaments/:id/fixtures/:fixtureId
```
Edit a fixture (schedule date/time, venue, swap teams). Only the organizer.

**Request:**
```json
{
  "scheduledDate": "2026-03-05",
  "scheduledTime": "14:30",
  "estimatedDurationMinutes": 180,
  "venue": "Wankhede Stadium",
  "homeTeamId": "uuid",
  "awayTeamId": "uuid"
}
```
All fields optional.

**Response (200):** Updated fixture object. May include a `scheduleWarning` if a venue conflict is detected:
```json
{
  "fixture": { "...updated fixture..." },
  "scheduleWarning": "Another fixture at Wankhede Stadium on 2026-03-05 overlaps (Match #3 at 12:00, ~180 min)"
}
```

**Schedule conflict detection:** When `scheduledDate` + `scheduledTime` + `venue` are all set, the server checks if another fixture at the same venue on the same date overlaps within `estimatedDurationMinutes`. Returns a warning in the response but does not block the operation.

**Errors:**
- `403` — Not the tournament organizer.
- `409` — Cannot edit a fixture whose match is already completed.

---

```
GET    /api/v1/tournaments/:id/standings
```
Get the points table / standings for the tournament.

**Query params:** `?groupName=A` (optional, filter by group)

**Response (200):**
```json
{
  "standings": [
    {
      "position": 1,
      "teamId": "uuid",
      "teamName": "Mumbai Warriors",
      "groupName": "A",
      "played": 3,
      "won": 2,
      "lost": 1,
      "tied": 0,
      "noResult": 0,
      "points": 4,
      "nrr": "+1.250"
    }
  ],
  "groups": ["A", "B"]
}
```

---

```
GET    /api/v1/tournaments/:id/leaderboard
```
Tournament-scoped player leaderboard.

**Query params:** `?category=runs&limit=10` (categories: "runs", "wickets", "batting_avg", "economy")

**Response (200):**
```json
{
  "category": "runs",
  "leaderboard": [
    {
      "rank": 1,
      "playerId": "uuid",
      "playerName": "Arjun Mehta",
      "teamName": "Mumbai Warriors",
      "value": 245,
      "matches": 3,
      "details": {
        "innings": 3,
        "highestScore": 98,
        "average": 81.67,
        "strikeRate": 142.44
      }
    }
  ]
}
```

---

## 2. WebSocket Protocol

### 2.1 Connection

**URL:** `wss://api.cricapp.com/ws?token=<firebase_jwt>`

Connection is authenticated via JWT query parameter. Server verifies the token and associates the WebSocket with the user.

**Anonymous viewers:** Read-only WebSocket connections (viewers) do not require authentication. Connect without a `token` parameter to join match rooms as a subscriber. WebSocket is broadcast-only — all scoring mutations go through REST. Anonymous connections receive all broadcast messages (`match_state`, `score_update`, `wicket`, `innings_complete`, `match_complete`, `delivery_undone`). Scorers still require a valid Firebase JWT for REST scoring endpoints.

### 2.2 Client to Server Messages

**Join match room:**
```json
{
  "type": "join_match",
  "matchId": "uuid"
}
```

**Leave match room:**
```json
{
  "type": "leave_match",
  "matchId": "uuid"
}
```

**Fast-path score relay (scorer → viewers, zero DB):**
```json
{
  "type": "publish_score",
  "matchId": "uuid",
  "payload": { }
}
```

The scorer sends `publish_score` immediately after each delivery is written to local DB. The server relays the `payload` as-is to all room subscribers via Bun's `ws.publish` (sender excluded). No DB read or write occurs on this path — viewer latency is sub-10ms. The durable path (REST sync → DB persist → `match_state` broadcast) follows within ~2s as the SyncService timer fires.

> **Note:** All scoring mutations are written to local SQLite first (offline-first). The REST sync path (`POST /matches/:id/deliveries`, `DELETE /matches/:id/deliveries/:did`) is the authoritative write path. WebSocket serves two broadcast roles: (1) fast-path relay of `publish_score` payloads for near-instant viewer updates, and (2) durable reconciliation via `match_state` broadcasts after the server persists each delivery.

### 2.3 Server to Client Messages

**Score update (broadcast to all match subscribers):**
```json
{
  "type": "score_update",
  "matchId": "uuid",
  "data": {
    "totalRuns": 87,
    "totalWickets": 3,
    "overs": "12.3",
    "currentRunRate": 6.96,
    "requiredRunRate": 8.45,
    "lastDelivery": {
      "runs": 4,
      "isWide": false,
      "isWicket": false,
      "description": "FOUR! Cover drive"
    },
    "striker": {
      "id": "uuid",
      "name": "R. Sharma",
      "runs": 45,
      "balls": 32,
      "fours": 5,
      "sixes": 2,
      "strikeRate": 140.63
    },
    "nonStriker": {
      "id": "uuid",
      "name": "V. Kohli",
      "runs": 22,
      "balls": 18
    },
    "bowler": {
      "id": "uuid",
      "name": "J. Bumrah",
      "overs": "3.3",
      "maidens": 0,
      "runs": 22,
      "wickets": 1,
      "economy": 6.29
    },
    "currentOver": [
      { "runs": 0, "display": "." },
      { "runs": 1, "display": "1" },
      { "runs": 4, "display": "4" },
      { "runs": 0, "display": "W", "isWicket": true }
    ],
    "deliveryCount": 75
  }
}
```

> **Gap detection:** `deliveryCount` is an incrementing counter of total deliveries in the current innings. Viewers track the last seen count and detect gaps (missed messages) when `incoming != lastSeen + 1`. On gap detection, the viewer re-sends `join_match` to get a full `match_state` snapshot. `deliveryCount=0` means backward-compatible (old scorer), no gap check performed. Counter resets to 0 on innings change.

**Wicket notification:**
```json
{
  "type": "wicket",
  "matchId": "uuid",
  "data": {
    "dismissedPlayer": "S. Dhawan",
    "dismissalType": "caught",
    "fielder": "V. Kohli",
    "bowler": "J. Bumrah",
    "description": "c Kohli b Bumrah",
    "teamScore": "87/3",
    "overs": "12.3"
  }
}
```

**Innings complete:**
```json
{
  "type": "innings_complete",
  "matchId": "uuid",
  "data": {
    "inningsNumber": 1,
    "battingTeam": "Mumbai Warriors",
    "totalRuns": 156,
    "totalWickets": 7,
    "overs": "20.0",
    "target": 157
  }
}
```

**Match complete:**
```json
{
  "type": "match_complete",
  "matchId": "uuid",
  "data": {
    "winner": "Mumbai Warriors",
    "resultType": "wickets",
    "margin": 5,
    "summary": "Mumbai Warriors won by 5 wickets",
    "manOfMatch": { "id": "uuid", "name": "R. Sharma" },
    "superOverPlayed": false
  }
}
```

**Delivery undone (broadcast to all match subscribers):**
```json
{
  "type": "delivery_undone",
  "matchId": "uuid",
  "data": {
    "inningsId": "uuid",
    "removedDeliveryId": "uuid",
    "updatedScore": {
      "runs": 85,
      "wickets": 3,
      "overs": "12.3"
    },
    "updatedBatterStats": {
      "strikerId": "uuid",
      "strikerRuns": 45,
      "strikerBalls": 30,
      "strikerFours": 5,
      "strikerSixes": 2
    },
    "updatedBowlerStats": {
      "bowlerId": "uuid",
      "bowlerOvers": "4.3",
      "bowlerRuns": 28,
      "bowlerWickets": 1,
      "bowlerMaidens": 0
    },
    "currentOver": [
      { "runs": 0, "display": "." },
      { "runs": 1, "display": "1" }
    ]
  }
}
```

**Error:**
```json
{
  "type": "error",
  "message": "Not authorized to score this match"
}
```

### 2.4 Room Management

- Each match = one WebSocket room (topic: `match:<matchId>`)
- **All connections** are subscribers (receive broadcast messages)
- **Dual-path broadcast:** (1) **Fast path** — scorer sends `publish_score` WS message → server relays payload to room subscribers (zero DB, sub-10ms); (2) **Durable path** — REST sync (timer: 2s, batch threshold: 1) → server persists to DB → broadcasts `match_state` reconciliation snapshot. Scoring mutations never originate from WebSocket; REST is the authoritative write path.
- Uses Bun's native `server.publish(topic, message)` for broadcasting
- On join/rejoin, server sends `match_state` snapshot to the connecting client
- Automatic cleanup when all connections leave a room

### 2.5 Reconnection & Catch-Up

When a viewer or scorer disconnects and reconnects:
1. Client re-sends `join_match` message with `matchId`.
2. Server responds with a **full state snapshot** via a `match_state` message containing: complete current score, batting/bowling stats, current over deliveries, and last 6 deliveries.
3. No delivery replay or message queue needed — the snapshot provides the complete current state. WebSocket resumes from there with new real-time updates.
4. If scorer reconnects, the `scorer_id` lock is still in place — no re-authentication beyond the existing Firebase JWT on the WebSocket connection.

**`match_state` message (sent on join/rejoin):**
```json
{
  "type": "match_state",
  "matchId": "uuid",
  "data": {
    "status": "live",
    "inningsNumber": 1,
    "totalRuns": 87,
    "totalWickets": 3,
    "overs": "12.3",
    "currentRunRate": 6.96,
    "requiredRunRate": null,
    "target": null,
    "striker": { "id": "uuid", "name": "R. Sharma", "runs": 45, "balls": 32, "fours": 5, "sixes": 2, "strikeRate": 140.63 },
    "nonStriker": { "id": "uuid", "name": "V. Kohli", "runs": 22, "balls": 18 },
    "bowler": { "id": "uuid", "name": "J. Bumrah", "overs": "3.3", "maidens": 0, "runs": 22, "wickets": 1, "economy": 6.29 },
    "currentOver": [
      { "runs": 0, "display": "." },
      { "runs": 1, "display": "1" },
      { "runs": 4, "display": "4" }
    ],
    "recentDeliveries": [ "...last 6 deliveries..." ],
    "deliveryCount": 75
  }
}
```

### 2.6 Concurrent Scoring Prevention

The `matches.scorer_id` field acts as a lock. Only the designated scorer can submit deliveries or undo actions:
- Server validates that the authenticated user's ID matches `matches.scorer_id` on every REST scoring endpoint (`POST /matches/:id/deliveries`, `DELETE /matches/:id/deliveries/:did`, `POST /sync/push`).
- If a non-scorer attempts a scoring mutation, the server responds with `403 FORBIDDEN: "Not authorized to score this match"`.
- WebSocket connections do not perform scoring mutations — they only receive broadcasts.

---

## 3. Error Responses

All errors follow a consistent format:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Human-readable error message",
    "details": { }
  }
}
```

**Error codes:**
| Code | HTTP Status | Description |
|------|-------------|-------------|
| UNAUTHORIZED | 401 | Missing or invalid auth token |
| FORBIDDEN | 403 | Not authorized for this action |
| NOT_FOUND | 404 | Resource not found |
| VALIDATION_ERROR | 400 | Invalid request data |
| CONFLICT | 409 | Duplicate or conflicting operation |
| RATE_LIMITED | 429 | Too many requests |
| INTERNAL_ERROR | 500 | Server error |

---

## 4. Rate Limiting

| Endpoint | Limit |
|----------|-------|
| Auth endpoints | 10 req/min |
| Scoring endpoints | 120 req/min (2 per second) |
| Read endpoints | 60 req/min |
| Sync endpoints | 10 req/min |
| Tournament endpoints | 30 req/min |
| WebSocket messages | 5 msg/sec per connection |

---

## 5. CORS Policy

`CORS_ORIGIN=*` for MVP. Mobile Dio client does not send `Origin` headers, so CORS is irrelevant for the app. Wildcard allows a future web dashboard without reconfiguration. Lock down to specific domains post-MVP.

---

## 6. Request Validation Rules

All validation enforced via Elysia TypeBox schemas on request bodies and query parameters.

| Field | Rule |
|-------|------|
| Phone number | `^[6-9]\d{9}$` (10 digits, Indian mobile starting with 6-9) |
| Display name | 2-50 chars, trimmed |
| Team name | 2-30 chars |
| Tournament name | 2-50 chars |
| Total overs | integer 1-50 |
| Venue | optional, 0-100 chars |
| Players per side | integer 2-15 |
| Points values (win/tie/NR/loss) | integer 0-10 |
| Groups count | integer 1-8 |
| Top N qualify | integer 1-4 |
| Scheduled date | ISO 8601 date string |
| UUID fields | valid UUID v4 format |
| Page number | integer ≥ 1 |
| Limit | integer 1-100 (default varies by endpoint) |
