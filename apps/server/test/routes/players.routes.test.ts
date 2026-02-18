import { describe, expect, it, beforeAll, afterAll } from 'bun:test';
import { Elysia } from 'elysia';
import { eq, inArray } from 'drizzle-orm';
import { db } from '../../src/db/index.ts';
import { users } from '../../src/db/schema/users.ts';
import { playerRoutes } from '../../src/routes/v1/players.ts';
import { errorHandler } from '../../src/middleware/error-handler.ts';

const app = new Elysia().use(errorHandler).use(playerRoutes);

const BASE = 'http://localhost/api/v1/players';
const TEST_SUFFIX = Date.now();
const JSON_HEADERS = { 'Content-Type': 'application/json' };

let testUserId: string;
let createdPlayerId: string;
const createdPlayerIds: string[] = [];

beforeAll(async () => {
  // Ensure test user (auth middleware returns firebaseUid 'test-user-e2e-001')
  const existing = await db
    .select()
    .from(users)
    .where(eq(users.firebaseUid, 'test-user-e2e-001'))
    .limit(1);

  if (existing[0]) {
    testUserId = existing[0].id;
  } else {
    const [u] = await db
      .insert(users)
      .values({
        firebaseUid: 'test-user-e2e-001',
        phone: '+919999900001',
        displayName: 'Route Test User',
      })
      .returning();
    testUserId = u!.id;
  }
});

afterAll(async () => {
  // Clean up players created during tests
  if (createdPlayerIds.length > 0) {
    await db.delete(users).where(inArray(users.id, createdPlayerIds));
  }
});

describe('Players Routes', () => {
  // ---- POST / ----
  describe('POST /', () => {
    it('creates a player with valid data -> 201', async () => {
      const res = await app.handle(
        new Request(BASE, {
          method: 'POST',
          headers: JSON_HEADERS,
          body: JSON.stringify({
            displayName: `PRoute Player ${TEST_SUFFIX}`,
            playerRole: 'batter',
            battingStyle: 'right_hand',
          }),
        }),
      );

      expect(res.status).toBe(201);
      const body = await res.json();
      expect(body.player).toBeDefined();
      expect(body.player.id).toBeTruthy();
      expect(body.player.displayName).toBe(`PRoute Player ${TEST_SUFFIX}`);
      createdPlayerId = body.player.id;
      createdPlayerIds.push(createdPlayerId);
    });

    it('rejects invalid playerRole -> 400', async () => {
      const res = await app.handle(
        new Request(BASE, {
          method: 'POST',
          headers: JSON_HEADERS,
          body: JSON.stringify({
            displayName: 'Invalid Role Player',
            playerRole: 'goalkeeper',
          }),
        }),
      );

      expect(res.status).toBe(400);
      const body = await res.json();
      expect(body.error).toBeDefined();
      expect(body.error.code).toBe('VALIDATION_ERROR');
    });
  });

  // ---- GET /search ----
  describe('GET /search', () => {
    it('searches players by name -> 200', async () => {
      const res = await app.handle(
        new Request(`${BASE}/search?q=PRoute`),
      );

      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.players).toBeDefined();
      expect(Array.isArray(body.players)).toBe(true);
    });

    it('returns empty array without q -> 200', async () => {
      const res = await app.handle(new Request(`${BASE}/search`));

      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.players).toBeDefined();
      // searchPlayersByName returns [] for empty/short queries
      expect(Array.isArray(body.players)).toBe(true);
    });
  });

  // ---- GET /search-by-phone ----
  describe('GET /search-by-phone', () => {
    it('searches by phone -> 200', async () => {
      const res = await app.handle(
        new Request(`${BASE}/search-by-phone?phone=+919999900001`),
      );

      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body).toHaveProperty('player');
    });
  });

  // ---- GET /:id ----
  describe('GET /:id', () => {
    it('returns player profile -> 200', async () => {
      const res = await app.handle(
        new Request(`${BASE}/${testUserId}`),
      );

      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.player).toBeDefined();
    });
  });

  // ---- GET /:id/stats ----
  describe('GET /:id/stats', () => {
    it('returns player stats -> 200', async () => {
      const res = await app.handle(
        new Request(`${BASE}/${testUserId}/stats`),
      );

      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.stats).toBeDefined();
    });
  });
});
