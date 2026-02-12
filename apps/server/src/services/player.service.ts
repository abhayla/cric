import { eq, ilike } from 'drizzle-orm';
import { db } from '../db/index.ts';
import { users } from '../db/schema/users.ts';

interface CreatePlayerInput {
  displayName: string;
  phone?: string;
  playerRole?: string;
  battingStyle?: string;
  bowlingStyle?: string;
}

export async function searchPlayersByName(query: string, limit: number = 10) {
  if (!query || query.trim().length < 2) {
    return [];
  }

  const results = await db
    .select({
      id: users.id,
      displayName: users.displayName,
      phone: users.phone,
      battingStyle: users.battingStyle,
      bowlingStyle: users.bowlingStyle,
      playerRole: users.playerRole,
      location: users.location,
      avatarUrl: users.avatarUrl,
    })
    .from(users)
    .where(ilike(users.displayName, `%${query.trim()}%`))
    .limit(limit);

  return results;
}

export async function searchPlayerByPhone(phone: string) {
  const [player] = await db
    .select({
      id: users.id,
      displayName: users.displayName,
      phone: users.phone,
      battingStyle: users.battingStyle,
      bowlingStyle: users.bowlingStyle,
      playerRole: users.playerRole,
      location: users.location,
      avatarUrl: users.avatarUrl,
    })
    .from(users)
    .where(eq(users.phone, phone))
    .limit(1);

  return player ?? null;
}

export async function createPlayer(input: CreatePlayerInput) {
  const trimmedName = input.displayName.trim();
  if (trimmedName.length < 2 || trimmedName.length > 50) {
    throw new Error('Display name must be 2-50 characters');
  }

  // Create a placeholder user (no firebase_uid — will be claimed on sign-up)
  const placeholderUid = `placeholder-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;

  const [player] = await db
    .insert(users)
    .values({
      firebaseUid: placeholderUid,
      displayName: trimmedName,
      phone: input.phone || null,
      playerRole: input.playerRole || null,
      battingStyle: input.battingStyle || null,
      bowlingStyle: input.bowlingStyle || null,
    })
    .returning();

  return player!;
}
