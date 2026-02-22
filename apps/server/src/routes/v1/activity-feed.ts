import { Elysia, t } from 'elysia';
import { authMiddleware } from '../../middleware/auth.ts';
import { AppError } from '../../middleware/error-handler.ts';
import { getUserByFirebaseUid } from '../../services/auth.service.ts';
import {
  getActivityFeed,
  markEventsAsRead,
  getUnreadCount,
} from '../../services/activity-feed.service.ts';

export const activityFeedRoutes = new Elysia({ prefix: '/api/v1/activity-feed' })
  .use(authMiddleware)
  .get(
    '/',
    async (ctx) => {
      const { firebaseUser } = ctx as typeof ctx & {
        firebaseUser: { uid: string; phone: string | null; email: string | null };
      };
      const user = await getUserByFirebaseUid(firebaseUser.uid);
      if (!user) throw new AppError('UNAUTHORIZED', 'User not found', 401);

      const page = Number(ctx.query.page) || 1;
      const limit = Math.min(Number(ctx.query.limit) || 20, 50);

      return await getActivityFeed(user.id, page, limit);
    },
    {
      query: t.Object({
        page: t.Optional(t.String()),
        limit: t.Optional(t.String()),
      }),
    },
  )
  .post(
    '/read',
    async (ctx) => {
      const { firebaseUser } = ctx as typeof ctx & {
        firebaseUser: { uid: string; phone: string | null; email: string | null };
      };
      const user = await getUserByFirebaseUid(firebaseUser.uid);
      if (!user) throw new AppError('UNAUTHORIZED', 'User not found', 401);

      await markEventsAsRead(user.id, ctx.body.eventIds);
      return { message: 'Events marked as read' };
    },
    {
      body: t.Object({
        eventIds: t.Array(t.String()),
      }),
    },
  )
  .get(
    '/unread-count',
    async (ctx) => {
      const { firebaseUser } = ctx as typeof ctx & {
        firebaseUser: { uid: string; phone: string | null; email: string | null };
      };
      const user = await getUserByFirebaseUid(firebaseUser.uid);
      if (!user) throw new AppError('UNAUTHORIZED', 'User not found', 401);

      const count = await getUnreadCount(user.id);
      return { count };
    },
  );
