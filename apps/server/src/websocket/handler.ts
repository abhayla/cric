import { Elysia, t } from 'elysia';
import { eq } from 'drizzle-orm';
import { getMatchState, matchTopic, userTopic } from './rooms.ts';
import { getFirebaseAuth } from '../config/firebase.ts';
import { db } from '../db/index.ts';
import { matches } from '../db/schema/matches.ts';
import { users } from '../db/schema/users.ts';
import type { ClientMessage, ErrorMessage } from '../types/websocket.ts';

// ============================================================
// WebSocket Handler — Elysia plugin
// ============================================================

// Maps WS connection identity → verified Firebase UID
const verifiedConnections = new Map<object, string>();

// Caches UID → Set of matchIds they are authorized to score
const scorerMatchAuth = new Map<string, Set<string>>();

function getWsKey(ws: { raw: unknown }): object {
  // Elysia WS wraps Bun's ServerWebSocket; use raw as map key
  return (ws.raw ?? ws) as object;
}

async function verifyScorerForMatch(uid: string, matchId: string): Promise<boolean> {
  // Check cache first
  const cached = scorerMatchAuth.get(uid);
  if (cached?.has(matchId)) return true;

  // Query DB: matches.scorerId → users.firebaseUid
  const [match] = await db
    .select({ scorerFirebaseUid: users.firebaseUid })
    .from(matches)
    .innerJoin(users, eq(matches.scorerId, users.id))
    .where(eq(matches.id, matchId))
    .limit(1);

  if (!match || match.scorerFirebaseUid !== uid) return false;

  // Cache the authorization
  if (!scorerMatchAuth.has(uid)) {
    scorerMatchAuth.set(uid, new Set());
  }
  scorerMatchAuth.get(uid)!.add(matchId);
  return true;
}

export const websocketHandler = new Elysia({ name: 'websocket' }).ws('/ws', {
  idleTimeout: 120,
  body: t.Any(),
  query: t.Object({
    token: t.Optional(t.String()),
  }),

  async open(ws) {
    const token = ws.data.query?.token;
    if (!token) return; // Anonymous viewer — allowed but can't publish

    try {
      // In test mode with explicit opt-in, accept any token as the test user
      if (process.env.NODE_ENV === 'test' && process.env.ENABLE_TEST_AUTH === 'true') {
        verifiedConnections.set(getWsKey(ws), 'test-user-e2e-001');
        ws.subscribe(userTopic('test-user-e2e-001'));
        return;
      }

      const decodedToken = await getFirebaseAuth().verifyIdToken(token);
      verifiedConnections.set(getWsKey(ws), decodedToken.uid);

      // Subscribe to user-specific topic for team/tournament notifications
      const [userRow] = await db
        .select({ id: users.id })
        .from(users)
        .where(eq(users.firebaseUid, decodedToken.uid))
        .limit(1);

      if (userRow) {
        ws.subscribe(userTopic(userRow.id));
      }
    } catch {
      // Token invalid — connection stays open as anonymous viewer
      // They just won't be able to publish scores
    }
  },

  async message(ws, rawMessage) {
    let msg: ClientMessage;
    try {
      // rawMessage comes as parsed JSON if body is t.Any()
      msg =
        typeof rawMessage === 'string'
          ? JSON.parse(rawMessage)
          : (rawMessage as ClientMessage);
    } catch {
      const err: ErrorMessage = { type: 'error', message: 'Invalid JSON' };
      ws.send(JSON.stringify(err));
      return;
    }

    if (!msg || typeof msg !== 'object' || !('type' in msg)) {
      const err: ErrorMessage = {
        type: 'error',
        message: 'Invalid message format',
      };
      ws.send(JSON.stringify(err));
      return;
    }

    switch (msg.type) {
      case 'join_match': {
        if (!msg.matchId || typeof msg.matchId !== 'string') {
          const err: ErrorMessage = {
            type: 'error',
            message: 'matchId is required',
          };
          ws.send(JSON.stringify(err));
          return;
        }

        // Subscribe to match room
        ws.subscribe(matchTopic(msg.matchId));

        // Send full state snapshot
        try {
          const state = await getMatchState(msg.matchId);
          ws.send(JSON.stringify(state));
        } catch {
          const err: ErrorMessage = {
            type: 'error',
            message: 'Match not found',
          };
          ws.send(JSON.stringify(err));
        }
        break;
      }

      case 'leave_match': {
        if (!msg.matchId || typeof msg.matchId !== 'string') {
          const err: ErrorMessage = {
            type: 'error',
            message: 'matchId is required',
          };
          ws.send(JSON.stringify(err));
          return;
        }

        ws.unsubscribe(matchTopic(msg.matchId));
        break;
      }

      case 'ping': {
        ws.send(JSON.stringify({ type: 'pong' }));
        break;
      }

      case 'publish_score': {
        if (!msg.matchId || typeof msg.matchId !== 'string') {
          const err: ErrorMessage = {
            type: 'error',
            message: 'matchId is required',
          };
          ws.send(JSON.stringify(err));
          return;
        }
        if (!msg.payload || typeof msg.payload !== 'object') {
          const err: ErrorMessage = {
            type: 'error',
            message: 'payload is required',
          };
          ws.send(JSON.stringify(err));
          return;
        }

        // Verify the connection is authenticated
        const uid = verifiedConnections.get(getWsKey(ws));
        if (!uid) {
          const err: ErrorMessage = {
            type: 'error',
            message: 'Authentication required to publish scores',
          };
          ws.send(JSON.stringify(err));
          return;
        }

        // Verify the user is the scorer for this match
        const isScorer = await verifyScorerForMatch(uid, msg.matchId);
        if (!isScorer) {
          const err: ErrorMessage = {
            type: 'error',
            message: 'Only the match scorer can publish scores',
          };
          ws.send(JSON.stringify(err));
          return;
        }

        // Relay payload as-is to all subscribers (excludes sender via Bun's publish)
        ws.publish(matchTopic(msg.matchId), JSON.stringify(msg.payload));
        break;
      }

      default: {
        const err: ErrorMessage = {
          type: 'error',
          message: `Unknown message type: ${(msg as { type: string }).type}`,
        };
        ws.send(JSON.stringify(err));
      }
    }
  },

  close(ws) {
    // Clean up auth maps
    const key = getWsKey(ws);
    const uid = verifiedConnections.get(key);
    if (uid) {
      verifiedConnections.delete(key);
      // Don't clean scorerMatchAuth — it caches UID→match mapping
      // that's valid across reconnects
    }
    // Bun automatically unsubscribes from all topics on close
  },
});
