import { eq, and } from 'drizzle-orm';
import { db } from '../db/index.ts';
import { users } from '../db/schema/users.ts';
import type { FirebaseUser } from '../types/auth.ts';

interface ProfileUpdate {
  displayName?: string;
  battingStyle?: string;
  bowlingStyle?: string;
  playerRole?: string;
  location?: string;
}

export async function verifyAndGetUser(firebaseUser: FirebaseUser) {
  const existing = await db
    .select()
    .from(users)
    .where(eq(users.firebaseUid, firebaseUser.uid))
    .limit(1);

  if (existing[0]) {
    return { user: existing[0], isNewUser: false };
  }

  // Auto-claim: check for unverified placeholder user with matching phone
  if (firebaseUser.phone) {
    const [placeholder] = await db
      .select()
      .from(users)
      .where(and(eq(users.phone, firebaseUser.phone), eq(users.isVerified, false)))
      .limit(1);

    if (placeholder) {
      const [claimed] = await db
        .update(users)
        .set({ firebaseUid: firebaseUser.uid, isVerified: true })
        .where(eq(users.id, placeholder.id))
        .returning();
      return { user: claimed!, isNewUser: false };
    }
  }

  const phoneSuffix = firebaseUser.phone?.slice(-4);
  const displayName = phoneSuffix ? `Player ${phoneSuffix}` : 'New Player';

  const [newUser] = await db
    .insert(users)
    .values({
      firebaseUid: firebaseUser.uid,
      phone: firebaseUser.phone,
      email: firebaseUser.email,
      displayName,
      isVerified: true,
    })
    .returning();

  return { user: newUser!, isNewUser: true };
}

export async function updateProfile(
  firebaseUid: string,
  updates: ProfileUpdate,
) {
  const [updated] = await db
    .update(users)
    .set(updates)
    .where(eq(users.firebaseUid, firebaseUid))
    .returning();

  return updated ?? null;
}

export async function getUserByFirebaseUid(firebaseUid: string) {
  const result = await db
    .select()
    .from(users)
    .where(eq(users.firebaseUid, firebaseUid))
    .limit(1);

  return result[0] ?? null;
}
