import { Elysia, t } from 'elysia';
import { authMiddleware } from '../../middleware/auth.ts';
import { AppError } from '../../middleware/error-handler.ts';
import { getUserByFirebaseUid } from '../../services/auth.service.ts';
import {
  recordDelivery,
  undoDelivery,
  getDeliveries,
  abandonMatch,
  declareInnings,
  reopenInnings,
  reopenMatch,
} from '../../services/scoring.service.ts';

export const scoringRoutes = new Elysia({ prefix: '/api/v1/matches' })
  .use(authMiddleware)
  .post(
    '/:id/deliveries',
    async (ctx) => {
      const { firebaseUser } = ctx as typeof ctx & {
        firebaseUser: { uid: string; phone: string | null; email: string | null };
      };
      const user = await getUserByFirebaseUid(firebaseUser.uid);
      if (!user) throw new AppError('UNAUTHORIZED', 'User not found', 401);

      const result = await recordDelivery(ctx.params.id, user.id, {
        inningsId: ctx.body.inningsId,
        overNumber: ctx.body.overNumber,
        ballNumber: ctx.body.ballNumber,
        strikerId: ctx.body.strikerId,
        nonStrikerId: ctx.body.nonStrikerId,
        bowlerId: ctx.body.bowlerId,
        runsFromBat: ctx.body.runsFromBat,
        isWide: ctx.body.isWide,
        isNoBall: ctx.body.isNoBall,
        isBye: ctx.body.isBye,
        isLegBye: ctx.body.isLegBye,
        wideRuns: ctx.body.wideRuns,
        noBallRuns: ctx.body.noBallRuns,
        byeRuns: ctx.body.byeRuns,
        legByeRuns: ctx.body.legByeRuns,
        isWicket: ctx.body.isWicket,
        isBoundaryFour: ctx.body.isBoundaryFour,
        isBoundarySix: ctx.body.isBoundarySix,
        isPenalty: ctx.body.isPenalty,
        wicket: ctx.body.wicket,
      });

      ctx.set.status = 201;
      return result;
    },
    {
      params: t.Object({ id: t.String() }),
      body: t.Object({
        inningsId: t.String(),
        overNumber: t.Number({ minimum: 0 }),
        ballNumber: t.Number({ minimum: 1 }),
        strikerId: t.String(),
        nonStrikerId: t.String(),
        bowlerId: t.String(),
        runsFromBat: t.Number({ minimum: 0 }),
        isWide: t.Boolean(),
        isNoBall: t.Boolean(),
        isBye: t.Boolean(),
        isLegBye: t.Boolean(),
        wideRuns: t.Number({ minimum: 0 }),
        noBallRuns: t.Number({ minimum: 0 }),
        byeRuns: t.Number({ minimum: 0 }),
        legByeRuns: t.Number({ minimum: 0 }),
        isWicket: t.Boolean(),
        isBoundaryFour: t.Boolean(),
        isBoundarySix: t.Boolean(),
        isPenalty: t.Optional(t.Boolean()),
        wicket: t.Optional(
          t.Object({
            dismissedPlayerId: t.String(),
            dismissalTypeId: t.Number(),
            fielderId: t.Optional(t.String()),
            bowlerCredited: t.Boolean(),
          }),
        ),
      }),
    },
  )
  .delete(
    '/:id/deliveries/:did',
    async (ctx) => {
      const { firebaseUser } = ctx as typeof ctx & {
        firebaseUser: { uid: string; phone: string | null; email: string | null };
      };
      const user = await getUserByFirebaseUid(firebaseUser.uid);
      if (!user) throw new AppError('UNAUTHORIZED', 'User not found', 401);

      await undoDelivery(ctx.params.id, ctx.params.did, user.id);

      return { success: true };
    },
    {
      params: t.Object({ id: t.String(), did: t.String() }),
    },
  )
  .get(
    '/:id/deliveries',
    async (ctx) => {
      const inningsId = ctx.query.inningsId;
      if (!inningsId) {
        throw new AppError('VALIDATION_ERROR', 'inningsId query parameter is required', 400);
      }

      const page = Number(ctx.query.page) || 1;
      const limit = Math.min(Number(ctx.query.limit) || 50, 100);

      return await getDeliveries(inningsId, page, limit);
    },
    {
      params: t.Object({ id: t.String() }),
      query: t.Object({
        inningsId: t.Optional(t.String()),
        page: t.Optional(t.String()),
        limit: t.Optional(t.String()),
      }),
    },
  )
  .post(
    '/:id/abandon',
    async (ctx) => {
      const { firebaseUser } = ctx as typeof ctx & {
        firebaseUser: { uid: string; phone: string | null; email: string | null };
      };
      const user = await getUserByFirebaseUid(firebaseUser.uid);
      if (!user) throw new AppError('UNAUTHORIZED', 'User not found', 401);

      await abandonMatch(ctx.params.id, user.id);

      return { success: true };
    },
    {
      params: t.Object({ id: t.String() }),
    },
  )
  .post(
    '/:id/declare',
    async (ctx) => {
      const { firebaseUser } = ctx as typeof ctx & {
        firebaseUser: { uid: string; phone: string | null; email: string | null };
      };
      const user = await getUserByFirebaseUid(firebaseUser.uid);
      if (!user) throw new AppError('UNAUTHORIZED', 'User not found', 401);

      await declareInnings(ctx.params.id, user.id);

      return { success: true };
    },
    {
      params: t.Object({ id: t.String() }),
    },
  )
  .post(
    '/:id/reopen',
    async (ctx) => {
      const { firebaseUser } = ctx as typeof ctx & {
        firebaseUser: { uid: string; phone: string | null; email: string | null };
      };
      const user = await getUserByFirebaseUid(firebaseUser.uid);
      if (!user) throw new AppError('UNAUTHORIZED', 'User not found', 401);

      const target = ctx.body.target;

      if (target === 'innings') {
        await reopenInnings(ctx.params.id, user.id);
      } else if (target === 'match') {
        await reopenMatch(ctx.params.id, user.id);
      } else {
        throw new AppError('VALIDATION_ERROR', 'target must be "innings" or "match"', 400);
      }

      return { success: true };
    },
    {
      params: t.Object({ id: t.String() }),
      body: t.Object({
        target: t.Union([t.Literal('innings'), t.Literal('match')]),
      }),
    },
  );
