import { Elysia, t } from 'elysia';
import { authMiddleware } from '../../middleware/auth.ts';
import { AppError } from '../../middleware/error-handler.ts';
import { getUserByFirebaseUid } from '../../services/auth.service.ts';
import {
  createTeam,
  getTeams,
  getTeam,
  updateTeam,
  deleteTeam,
  addPlayer,
  removePlayer,
} from '../../services/team.service.ts';

const ROSTER_ROLES = ['captain', 'vice_captain', 'player'] as const;

export const teamRoutes = new Elysia({ prefix: '/api/v1/teams' })
  .use(authMiddleware)
  .post(
    '/',
    async (ctx) => {
      const { firebaseUser } = ctx as typeof ctx & {
        firebaseUser: { uid: string; phone: string | null; email: string | null };
      };
      const user = await getUserByFirebaseUid(firebaseUser.uid);
      if (!user) throw new AppError('UNAUTHORIZED', 'User not found', 401);

      const team = await createTeam({
        name: ctx.body.name,
        location: ctx.body.location,
        logoUrl: ctx.body.logoUrl,
        createdBy: user.id,
      });

      ctx.set.status = 201;
      return { team };
    },
    {
      body: t.Object({
        name: t.String({ minLength: 2, maxLength: 50 }),
        location: t.Optional(t.String({ maxLength: 100 })),
        logoUrl: t.Optional(t.String()),
      }),
    },
  )
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

      return await getTeams(user.id, page, limit);
    },
    {
      query: t.Object({
        page: t.Optional(t.String()),
        limit: t.Optional(t.String()),
      }),
    },
  )
  .get(
    '/:id',
    async (ctx) => {
      const { firebaseUser } = ctx as typeof ctx & {
        firebaseUser: { uid: string; phone: string | null; email: string | null };
      };
      const user = await getUserByFirebaseUid(firebaseUser.uid);
      if (!user) throw new AppError('UNAUTHORIZED', 'User not found', 401);

      const team = await getTeam(ctx.params.id);
      if (!team) throw new AppError('NOT_FOUND', 'Team not found', 404);

      // Compute user's role relative to this team
      let role = 'member';
      if (team.createdBy === user.id) {
        role = 'owner';
      } else {
        const rosterEntry = team.roster.find((r: any) => r.playerId === user.id);
        if (rosterEntry) {
          role = (rosterEntry as any).role;
        }
      }

      const teamObj = JSON.parse(JSON.stringify(team));
      teamObj.role = role;
      return { team: teamObj };
    },
    {
      params: t.Object({
        id: t.String(),
      }),
    },
  )
  .put(
    '/:id',
    async (ctx) => {
      const { firebaseUser } = ctx as typeof ctx & {
        firebaseUser: { uid: string; phone: string | null; email: string | null };
      };
      const user = await getUserByFirebaseUid(firebaseUser.uid);
      if (!user) throw new AppError('UNAUTHORIZED', 'User not found', 401);

      const updated = await updateTeam(ctx.params.id, user.id, {
        name: ctx.body.name,
        location: ctx.body.location,
        logoUrl: ctx.body.logoUrl,
      });

      return { team: updated };
    },
    {
      params: t.Object({ id: t.String() }),
      body: t.Object({
        name: t.Optional(t.String({ minLength: 2, maxLength: 50 })),
        location: t.Optional(t.String({ maxLength: 100 })),
        logoUrl: t.Optional(t.String()),
      }),
    },
  )
  .delete(
    '/:id',
    async (ctx) => {
      const { firebaseUser } = ctx as typeof ctx & {
        firebaseUser: { uid: string; phone: string | null; email: string | null };
      };
      const user = await getUserByFirebaseUid(firebaseUser.uid);
      if (!user) throw new AppError('UNAUTHORIZED', 'User not found', 401);

      await deleteTeam(ctx.params.id, user.id);
      return { message: 'Team deleted successfully' };
    },
    {
      params: t.Object({ id: t.String() }),
    },
  )
  .post(
    '/:id/players',
    async (ctx) => {
      const { firebaseUser } = ctx as typeof ctx & {
        firebaseUser: { uid: string; phone: string | null; email: string | null };
      };
      const user = await getUserByFirebaseUid(firebaseUser.uid);
      if (!user) throw new AppError('UNAUTHORIZED', 'User not found', 401);

      const entry = await addPlayer(ctx.params.id, user.id, {
        playerId: ctx.body.playerId,
        jerseyNumber: ctx.body.jerseyNumber,
        role: ctx.body.role,
      });

      ctx.set.status = 201;
      return { rosterEntry: entry };
    },
    {
      params: t.Object({ id: t.String() }),
      body: t.Object({
        playerId: t.String(),
        jerseyNumber: t.Optional(t.Number({ minimum: 0, maximum: 999 })),
        role: t.Optional(t.Union(ROSTER_ROLES.map((r) => t.Literal(r)))),
      }),
    },
  )
  .delete(
    '/:id/players/:pid',
    async (ctx) => {
      const { firebaseUser } = ctx as typeof ctx & {
        firebaseUser: { uid: string; phone: string | null; email: string | null };
      };
      const user = await getUserByFirebaseUid(firebaseUser.uid);
      if (!user) throw new AppError('UNAUTHORIZED', 'User not found', 401);

      await removePlayer(ctx.params.id, user.id, ctx.params.pid);
      return { message: 'Player removed from roster' };
    },
    {
      params: t.Object({ id: t.String(), pid: t.String() }),
    },
  );
