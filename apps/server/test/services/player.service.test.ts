import { describe, expect, it, afterAll } from 'bun:test';
import { eq } from 'drizzle-orm';
import { db } from '../../src/db/index.ts';
import { users } from '../../src/db/schema/users.ts';
import {
  searchPlayersByName,
  searchPlayerByPhone,
  createPlayer,
} from '../../src/services/player.service.ts';

const TEST_SUFFIX = Date.now();
const createdPlayerIds: string[] = [];

afterAll(async () => {
  for (const id of createdPlayerIds) {
    await db.delete(users).where(eq(users.id, id));
  }
});

describe('Player Service', () => {
  describe('createPlayer', () => {
    it('creates a placeholder player', async () => {
      const player = await createPlayer({
        displayName: `SearchTest Player ${TEST_SUFFIX}`,
        phone: '+919999990001',
        playerRole: 'batter',
        battingStyle: 'right_hand',
        bowlingStyle: 'none',
      });

      expect(player).toBeDefined();
      expect(player.id).toBeTruthy();
      expect(player.displayName).toBe(`SearchTest Player ${TEST_SUFFIX}`);
      expect(player.phone).toBe('+919999990001');
      expect(player.firebaseUid).toContain('placeholder-');
      createdPlayerIds.push(player.id);
    });

    it('trims display name', async () => {
      const player = await createPlayer({
        displayName: `  Trimmed ${TEST_SUFFIX}  `,
      });
      expect(player.displayName).toBe(`Trimmed ${TEST_SUFFIX}`);
      createdPlayerIds.push(player.id);
    });

    it('rejects short name', async () => {
      await expect(
        createPlayer({ displayName: 'A' }),
      ).rejects.toThrow('Display name must be 2-50 characters');
    });
  });

  describe('searchPlayersByName', () => {
    it('finds players by partial name', async () => {
      const results = await searchPlayersByName(`SearchTest`);
      expect(results.length).toBeGreaterThanOrEqual(1);
      const found = results.find((p) => p.displayName === `SearchTest Player ${TEST_SUFFIX}`);
      expect(found).toBeDefined();
    });

    it('is case insensitive', async () => {
      const results = await searchPlayersByName(`searchtest`);
      expect(results.length).toBeGreaterThanOrEqual(1);
    });

    it('returns empty for short query', async () => {
      const results = await searchPlayersByName('Z');
      expect(results.length).toBe(0);
    });

    it('returns empty for no match', async () => {
      const results = await searchPlayersByName('ZZZNONEXISTENT999');
      expect(results.length).toBe(0);
    });

    it('respects limit', async () => {
      const results = await searchPlayersByName('SearchTest', 1);
      expect(results.length).toBeLessThanOrEqual(1);
    });
  });

  describe('searchPlayerByPhone', () => {
    it('finds player by exact phone', async () => {
      const player = await searchPlayerByPhone('+919999990001');
      expect(player).not.toBeNull();
      expect(player!.displayName).toBe(`SearchTest Player ${TEST_SUFFIX}`);
    });

    it('returns null for non-existent phone', async () => {
      const player = await searchPlayerByPhone('+910000000000');
      expect(player).toBeNull();
    });
  });
});
