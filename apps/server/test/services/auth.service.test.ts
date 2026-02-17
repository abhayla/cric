import { describe, expect, it, beforeAll, afterAll } from 'bun:test';
import { eq } from 'drizzle-orm';
import { db } from '../../src/db/index.ts';
import { users } from '../../src/db/schema/users.ts';
import {
  verifyAndGetUser,
  updateProfile,
  getUserByFirebaseUid,
} from '../../src/services/auth.service.ts';

const TEST_UID = `test-uid-${Date.now()}`;
const TEST_PHONE = '+919876543210';

const CLAIM_PHONE = `+91999${Date.now().toString().slice(-7)}`;
const CLAIM_UID = `claim-uid-${Date.now()}`;
const PLACEHOLDER_UID = `placeholder-${Date.now()}`;

afterAll(async () => {
  await db.delete(users).where(eq(users.firebaseUid, TEST_UID));
  await db.delete(users).where(eq(users.firebaseUid, CLAIM_UID));
  await db.delete(users).where(eq(users.firebaseUid, PLACEHOLDER_UID));
});

describe('Auth Service', () => {
  describe('verifyAndGetUser', () => {
    it('creates a new user when firebase_uid does not exist', async () => {
      const { user, isNewUser } = await verifyAndGetUser({
        uid: TEST_UID,
        phone: TEST_PHONE,
        email: null,
      });

      expect(isNewUser).toBe(true);
      expect(user!.firebaseUid).toBe(TEST_UID);
      expect(user!.phone).toBe(TEST_PHONE);
      expect(user!.displayName).toBe(`Player ${TEST_PHONE.slice(-4)}`);
      expect(user!.id).toBeTruthy();
    });

    it('retrieves existing user on second call', async () => {
      const { user, isNewUser } = await verifyAndGetUser({
        uid: TEST_UID,
        phone: TEST_PHONE,
        email: null,
      });

      expect(isNewUser).toBe(false);
      expect(user!.firebaseUid).toBe(TEST_UID);
    });
  });

  describe('auto-claim placeholder', () => {
    it('claims placeholder user when phone matches', async () => {
      // Create a placeholder user
      const [placeholder] = await db
        .insert(users)
        .values({
          firebaseUid: PLACEHOLDER_UID,
          phone: CLAIM_PHONE,
          displayName: 'Offline Player',
          isVerified: false,
        })
        .returning();

      // Register with same phone → should claim
      const { user, isNewUser } = await verifyAndGetUser({
        uid: CLAIM_UID,
        phone: CLAIM_PHONE,
        email: null,
      });

      expect(isNewUser).toBe(false);
      expect(user!.id).toBe(placeholder!.id); // Same user ID preserved
      expect(user!.firebaseUid).toBe(CLAIM_UID); // Updated to real UID
      expect(user!.isVerified).toBe(true);
      expect(user!.displayName).toBe('Offline Player'); // Name preserved
    });

    it('does NOT claim already-verified users by phone', async () => {
      // The claimed user from previous test is now verified with CLAIM_PHONE
      // A new registration with same phone should create a new user
      const newUid = `new-uid-${Date.now()}`;
      const { user, isNewUser } = await verifyAndGetUser({
        uid: newUid,
        phone: CLAIM_PHONE,
        email: null,
      });

      expect(isNewUser).toBe(true);
      expect(user!.firebaseUid).toBe(newUid);
      // Clean up
      await db.delete(users).where(eq(users.firebaseUid, newUid));
    });

    it('new users always get isVerified true', async () => {
      const freshUid = `fresh-uid-${Date.now()}`;
      const freshPhone = `+91888${Date.now().toString().slice(-7)}`;
      const { user, isNewUser } = await verifyAndGetUser({
        uid: freshUid,
        phone: freshPhone,
        email: null,
      });

      expect(isNewUser).toBe(true);
      expect(user!.isVerified).toBe(true);
      // Clean up
      await db.delete(users).where(eq(users.firebaseUid, freshUid));
    });
  });

  describe('updateProfile', () => {
    it('updates user profile fields', async () => {
      const updated = await updateProfile(TEST_UID, {
        displayName: 'Test Player',
        battingStyle: 'right_hand',
        bowlingStyle: 'right_arm_fast',
        playerRole: 'all_rounder',
        location: 'Mumbai',
      });

      expect(updated).not.toBeNull();
      expect(updated!.displayName).toBe('Test Player');
      expect(updated!.battingStyle).toBe('right_hand');
      expect(updated!.bowlingStyle).toBe('right_arm_fast');
      expect(updated!.playerRole).toBe('all_rounder');
      expect(updated!.location).toBe('Mumbai');
    });

    it('returns null for non-existent user', async () => {
      const updated = await updateProfile('non-existent-uid', {
        displayName: 'Ghost',
      });
      expect(updated).toBeNull();
    });
  });

  describe('getUserByFirebaseUid', () => {
    it('returns user by firebase uid', async () => {
      const user = await getUserByFirebaseUid(TEST_UID);
      expect(user).not.toBeNull();
      expect(user!.firebaseUid).toBe(TEST_UID);
    });

    it('returns null for non-existent uid', async () => {
      const user = await getUserByFirebaseUid('non-existent');
      expect(user).toBeNull();
    });
  });
});
