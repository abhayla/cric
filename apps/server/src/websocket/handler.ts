import { Elysia, t } from 'elysia';
import { getMatchState, matchTopic } from './rooms.ts';
import type { ClientMessage, ErrorMessage } from '../types/websocket.ts';

// ============================================================
// WebSocket Handler — Elysia plugin
// ============================================================

export const websocketHandler = new Elysia({ name: 'websocket' }).ws('/ws', {
  idleTimeout: 120,
  body: t.Any(),
  query: t.Object({
    token: t.Optional(t.String()),
  }),

  open(_ws) {
    // Optional JWT auth — anonymous viewers allowed
    // Token validation deferred to when they try to score (REST only)
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

  close(_ws) {
    // Bun automatically unsubscribes from all topics on close
  },
});
