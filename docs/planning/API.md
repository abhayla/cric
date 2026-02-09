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
  },
  "token": "server_jwt_if_needed"
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
  "city": "Mumbai"
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
  "city": "Mumbai",
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
      "city": "Mumbai",
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
    "city": "Mumbai",
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
    }
  }
}
```

---

```
PUT    /api/v1/matches/:id/toss
```
Record toss result.

**Request:**
```json
{
  "winnerId": "team_uuid",
  "decision": "bat"
}
```

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

### 1.4 Scoring (REST Fallback)

Primary scoring happens via WebSocket. REST endpoints are fallback for poor connectivity.

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
  "wagonWheelZoneId": 3,
  "wicket": null
}
```

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
Get all deliveries for a match.

**Query params:** `?inningsId=uuid`

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
      "city": "Mumbai"
    }
  ]
}
```

---

```
GET    /api/v1/players/:id
```
Get player profile.

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
Push offline changes to server.

**Request:**
```json
{
  "deliveries": [
    { "localId": "local_uuid", "...delivery_data..." }
  ],
  "timestamp": "2025-03-15T10:30:00Z"
}
```

**Response (200):**
```json
{
  "synced": 5,
  "idMappings": [
    { "localId": "local_uuid", "serverId": "server_uuid" }
  ],
  "conflicts": []
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
  "deliveries": [ "..." ],
  "matches": [ "..." ],
  "updatedAt": "2025-03-15T10:35:00Z"
}
```

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

## 2. WebSocket Protocol

### 2.1 Connection

**URL:** `wss://api.cricapp.com/ws?token=<firebase_jwt>`

Connection is authenticated via JWT query parameter. Server verifies the token and associates the WebSocket with the user.

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

**Record delivery (scorer only):**
```json
{
  "type": "delivery",
  "matchId": "uuid",
  "data": {
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
    "isWicket": false,
    "wagonWheelZone": "OF3"
  }
}
```

**Undo delivery (scorer only):**
```json
{
  "type": "undo_delivery",
  "matchId": "uuid",
  "deliveryId": "uuid"
}
```

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
    ]
  }
}
```

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
    "manOfMatch": { "id": "uuid", "name": "R. Sharma" }
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
- **Scorer** joins as publisher (can send delivery/undo messages)
- **Viewers** join as subscribers (receive-only)
- Uses Bun's native `server.publish(topic, message)` for broadcasting
- Automatic cleanup when all connections leave a room

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
| WebSocket messages | 5 msg/sec per connection |
