import { Elysia, t } from 'elysia';
import { authMiddleware } from '../../middleware/auth.ts';
import { AppError } from '../../middleware/error-handler.ts';
import {
  verifyAndGetUser,
  updateProfile,
} from '../../services/auth.service.ts';

function formatUserResponse(
  user: {
    id: string;
    firebaseUid: string;
    displayName: string;
    phone: string | null;
    email: string | null;
    battingStyle: string | null;
    bowlingStyle: string | null;
    playerRole: string | null;
    location: string | null;
  },
  isNewUser: boolean,
) {
  return {
    user: {
      id: user.id,
      firebaseUid: user.firebaseUid,
      displayName: user.displayName,
      phone: user.phone,
      email: user.email,
      battingStyle: user.battingStyle,
      bowlingStyle: user.bowlingStyle,
      playerRole: user.playerRole,
      location: user.location,
      isNewUser,
    },
  };
}

const BATTING_STYLES = ['right_hand', 'left_hand'] as const;
const BOWLING_STYLES = [
  'right_arm_fast',
  'right_arm_medium',
  'right_arm_off_spin',
  'right_arm_leg_spin',
  'left_arm_fast',
  'left_arm_medium',
  'left_arm_orthodox',
  'left_arm_chinaman',
  'none',
] as const;
const PLAYER_ROLES = ['batter', 'bowler', 'all_rounder', 'wk_batter'] as const;

export const authRoutes = new Elysia({ prefix: '/api/v1/auth' })
  .post(
    '/verify',
    async ({ body }) => {
      const { getFirebaseAuth } = await import('../../config/firebase.ts');

      let decodedToken;
      try {
        decodedToken = await getFirebaseAuth().verifyIdToken(body.idToken);
      } catch {
        throw new AppError('UNAUTHORIZED', 'Invalid Firebase token', 401);
      }

      const firebaseUser = {
        uid: decodedToken.uid,
        phone: decodedToken.phone_number ?? null,
        email: decodedToken.email ?? null,
      };

      const { user, isNewUser } = await verifyAndGetUser(firebaseUser);
      return formatUserResponse(user!, isNewUser);
    },
    {
      body: t.Object({
        idToken: t.String({ minLength: 1 }),
      }),
    },
  )
  .use(authMiddleware)
  .put(
    '/profile',
    async (ctx) => {
      const { firebaseUser } = ctx as typeof ctx & {
        firebaseUser: { uid: string; phone: string | null; email: string | null };
      };
      const { body } = ctx;

      const updates: Record<string, string | undefined> = {};

      if (body.displayName !== undefined) {
        const trimmed = body.displayName.trim();
        if (trimmed.length < 2 || trimmed.length > 50) {
          throw new AppError(
            'VALIDATION_ERROR',
            'Display name must be 2-50 characters',
            400,
          );
        }
        updates.displayName = trimmed;
      }
      if (body.battingStyle !== undefined) updates.battingStyle = body.battingStyle;
      if (body.bowlingStyle !== undefined) updates.bowlingStyle = body.bowlingStyle;
      if (body.playerRole !== undefined) updates.playerRole = body.playerRole;
      if (body.location !== undefined) updates.location = body.location;

      const updated = await updateProfile(firebaseUser.uid, updates);
      if (!updated) {
        throw new AppError('NOT_FOUND', 'User not found', 404);
      }

      return formatUserResponse(updated, false);
    },
    {
      body: t.Object({
        displayName: t.Optional(t.String()),
        battingStyle: t.Optional(t.Union(BATTING_STYLES.map((s) => t.Literal(s)))),
        bowlingStyle: t.Optional(
          t.Union(BOWLING_STYLES.map((s) => t.Literal(s))),
        ),
        playerRole: t.Optional(t.Union(PLAYER_ROLES.map((s) => t.Literal(s)))),
        location: t.Optional(t.String({ maxLength: 100 })),
      }),
    },
  );
