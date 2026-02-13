import { Elysia, t } from 'elysia';
import { authMiddleware } from '../../middleware/auth.ts';
import { AppError } from '../../middleware/error-handler.ts';
import { getUserByFirebaseUid } from '../../services/auth.service.ts';
import {
  createMatch,
  getMatches,
  getMatch,
  setPlayingXI,
  recordToss,
} from '../../services/match.service.ts';

const MATCH_FORMATS = ['T20', 'ODI', 'test', 'custom'] as const;
const TOSS_DECISIONS = ['bat', 'bowl'] as const;

export const matchRoutes = new Elysia({ prefix: '/api/v1/matches' })
  .use(authMiddleware)
  .post(
    '/',
    async (ctx) => {
      const { firebaseUser } = ctx as typeof ctx & {
        firebaseUser: { uid: string; phone: string | null; email: string | null };
      };
      const user = await getUserByFirebaseUid(firebaseUser.uid);
      if (!user) throw new AppError('UNAUTHORIZED', 'User not found', 401);

      const match = await createMatch({
        homeTeamId: ctx.body.homeTeamId,
        awayTeamId: ctx.body.awayTeamId,
        format: ctx.body.format,
        totalOvers: ctx.body.totalOvers,
        ballTypeId: ctx.body.ballTypeId,
        venue: ctx.body.venue,
        matchDate: ctx.body.matchDate,
        playersPerSide: ctx.body.playersPerSide,
        maxOversPerBowler: ctx.body.maxOversPerBowler,
        wideRuns: ctx.body.wideRuns,
        noBallRuns: ctx.body.noBallRuns,
        powerplayOvers: ctx.body.powerplayOvers,
        createdBy: user.id,
      });

      ctx.set.status = 201;
      return { match };
    },
    {
      body: t.Object({
        homeTeamId: t.String(),
        awayTeamId: t.String(),
        format: t.Union(MATCH_FORMATS.map((f) => t.Literal(f))),
        totalOvers: t.Number({ minimum: 1, maximum: 50 }),
        ballTypeId: t.Number(),
        venue: t.Optional(t.String({ maxLength: 200 })),
        matchDate: t.String(),
        playersPerSide: t.Optional(t.Number({ minimum: 2, maximum: 11 })),
        maxOversPerBowler: t.Optional(t.Number({ minimum: 1 })),
        wideRuns: t.Optional(t.Number({ minimum: 1, maximum: 5 })),
        noBallRuns: t.Optional(t.Number({ minimum: 1, maximum: 5 })),
        powerplayOvers: t.Optional(t.Number({ minimum: 0 })),
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

      return await getMatches(user.id, {
        status: ctx.query.status,
        page,
        limit,
      });
    },
    {
      query: t.Object({
        status: t.Optional(t.String()),
        page: t.Optional(t.String()),
        limit: t.Optional(t.String()),
      }),
    },
  )
  .get(
    '/:id',
    async (ctx) => {
      const match = await getMatch(ctx.params.id);
      if (!match) throw new AppError('NOT_FOUND', 'Match not found', 404);
      return { match };
    },
    {
      params: t.Object({ id: t.String() }),
    },
  )
  .post(
    '/:id/playing-xi',
    async (ctx) => {
      const { firebaseUser } = ctx as typeof ctx & {
        firebaseUser: { uid: string; phone: string | null; email: string | null };
      };
      const user = await getUserByFirebaseUid(firebaseUser.uid);
      if (!user) throw new AppError('UNAUTHORIZED', 'User not found', 401);

      const players = await setPlayingXI(ctx.params.id, {
        teamId: ctx.body.teamId,
        playerIds: ctx.body.playerIds,
        captainId: ctx.body.captainId,
        keeperId: ctx.body.keeperId,
        userId: user.id,
      });

      ctx.set.status = 201;
      return { players };
    },
    {
      params: t.Object({ id: t.String() }),
      body: t.Object({
        teamId: t.String(),
        playerIds: t.Array(t.String()),
        captainId: t.String(),
        keeperId: t.String(),
      }),
    },
  )
  .put(
    '/:id/toss',
    async (ctx) => {
      const { firebaseUser } = ctx as typeof ctx & {
        firebaseUser: { uid: string; phone: string | null; email: string | null };
      };
      const user = await getUserByFirebaseUid(firebaseUser.uid);
      if (!user) throw new AppError('UNAUTHORIZED', 'User not found', 401);

      const result = await recordToss(ctx.params.id, {
        winnerId: ctx.body.winnerId,
        decision: ctx.body.decision,
        openingStrikerId: ctx.body.openingStrikerId,
        openingNonStrikerId: ctx.body.openingNonStrikerId,
        openingBowlerId: ctx.body.openingBowlerId,
        userId: user.id,
      });

      return result;
    },
    {
      params: t.Object({ id: t.String() }),
      body: t.Object({
        winnerId: t.String(),
        decision: t.Union(TOSS_DECISIONS.map((d) => t.Literal(d))),
        openingStrikerId: t.String(),
        openingNonStrikerId: t.String(),
        openingBowlerId: t.String(),
      }),
    },
  );
