import { matchTopic } from './rooms.ts';
import type {
  ScoreUpdateMessage,
  WicketMessage,
  InningsCompleteMessage,
  MatchCompleteMessage,
  DeliveryUndoneMessage,
  MatchStateMessage,
} from '../types/websocket.ts';

// ============================================================
// Broadcaster — Holds server reference for pub/sub
// ============================================================

// Use a minimal interface so we don't need the generic Server<T> type
interface PubSubServer {
  publish(topic: string, data: string | ArrayBuffer | Uint8Array): number;
}

let server: PubSubServer | null = null;

export function initBroadcaster(s: PubSubServer): void {
  server = s;
}

export function getBroadcasterServer(): PubSubServer | null {
  return server;
}

function publish(matchId: string, message: object): void {
  if (!server) return;
  server.publish(matchTopic(matchId), JSON.stringify(message));
}

export function broadcastScoreUpdate(matchId: string, data: ScoreUpdateMessage): void {
  publish(matchId, data);
}

export function broadcastWicket(matchId: string, data: WicketMessage): void {
  publish(matchId, data);
}

export function broadcastInningsComplete(matchId: string, data: InningsCompleteMessage): void {
  publish(matchId, data);
}

export function broadcastMatchComplete(matchId: string, data: MatchCompleteMessage): void {
  publish(matchId, data);
}

export function broadcastDeliveryUndone(matchId: string, data: DeliveryUndoneMessage): void {
  publish(matchId, data);
}

export function broadcastMatchState(matchId: string, data: MatchStateMessage): void {
  publish(matchId, data);
}
