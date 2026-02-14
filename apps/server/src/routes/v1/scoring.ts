import { Elysia, t } from 'elysia';
import { eq, and, desc } from 'drizzle-orm';
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
import { db } from '../../db/index.ts';
import { deliveries } from '../../db/schema/deliveries.ts';
import { innings } from '../../db/schema/innings.ts';
import { battingStats, bowlingStats } from '../../db/schema/stats.ts';
import { users } from '../../db/schema/users.ts';
import { teams } from '../../db/schema/teams.ts';
import { matchResult } from '../../db/schema/matches.ts';
import { wicketsByDelivery } from '../../db/schema/deliveries.ts';
import { dismissalTypes } from '../../db/schema/master-data.ts';
import {
  buildScoreUpdate,
  buildWicketMessage,
  buildInningsCompleteMessage,
  buildMatchCompleteMessage,
  buildDeliveryUndoneMessage,
  getMatchState,
} from '../../websocket/rooms.ts';
import {
  broadcastScoreUpdate,
  broadcastWicket,
  broadcastInningsComplete,
  broadcastMatchComplete,
  broadcastDeliveryUndone,
  broadcastMatchState,
} from '../../websocket/broadcaster.ts';
import type { OverBallDisplay } from '../../types/websocket.ts';

// Helper: convert delivery to OverBallDisplay
function deliveryToOverBall(d: typeof deliveries.$inferSelect): OverBallDisplay {
  let display: string;
  if (d.isWicket) {
    display = 'W';
  } else if (d.isWide) {
    display = d.totalRuns > 1 ? `${d.totalRuns}Wd` : 'Wd';
  } else if (d.isNoBall) {
    display = d.totalRuns > 1 ? `${d.totalRuns}Nb` : 'Nb';
  } else if (d.isBoundarySix) {
    display = '6';
  } else if (d.isBoundaryFour) {
    display = '4';
  } else if (d.isBye) {
    display = d.byeRuns > 0 ? `${d.byeRuns}B` : 'B';
  } else if (d.isLegBye) {
    display = d.legByeRuns > 0 ? `${d.legByeRuns}Lb` : 'Lb';
  } else if (d.totalRuns === 0) {
    display = '.';
  } else {
    display = String(d.runsFromBat);
  }

  return {
    runs: d.totalRuns,
    display,
    ...(d.isWicket ? { isWicket: true } : {}),
  };
}

// Helper: get current over balls for broadcast
async function getCurrentOverBalls(inningsId: string, overNumber: number): Promise<OverBallDisplay[]> {
  const overDeliveries = await db
    .select()
    .from(deliveries)
    .where(
      and(
        eq(deliveries.inningsId, inningsId),
        eq(deliveries.overNumber, overNumber),
      ),
    )
    .orderBy(deliveries.sequenceNumber);

  return overDeliveries.map(deliveryToOverBall);
}

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

      const matchId = ctx.params.id;
      const result = await recordDelivery(matchId, user.id, {
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

      // --- Broadcast score_update ---
      try {
        // Get striker batting stat + name
        const [strikerStat] = await db
          .select({
            playerId: battingStats.playerId,
            runs: battingStats.runsScored,
            balls: battingStats.ballsFaced,
            fours: battingStats.fours,
            sixes: battingStats.sixes,
            name: users.displayName,
          })
          .from(battingStats)
          .innerJoin(users, eq(users.id, battingStats.playerId))
          .where(
            and(
              eq(battingStats.inningsId, ctx.body.inningsId),
              eq(battingStats.playerId, ctx.body.strikerId),
            ),
          )
          .limit(1);

        // Get bowler bowling stat + name
        const [bowlerStat] = await db
          .select({
            playerId: bowlingStats.playerId,
            overs: bowlingStats.oversBowled,
            maidens: bowlingStats.maidens,
            runs: bowlingStats.runsConceded,
            wickets: bowlingStats.wicketsTaken,
            name: users.displayName,
          })
          .from(bowlingStats)
          .innerJoin(users, eq(users.id, bowlingStats.playerId))
          .where(
            and(
              eq(bowlingStats.inningsId, ctx.body.inningsId),
              eq(bowlingStats.playerId, ctx.body.bowlerId),
            ),
          )
          .limit(1);

        const currentOver = await getCurrentOverBalls(ctx.body.inningsId, ctx.body.overNumber);

        const scoreUpdateMsg = buildScoreUpdate(
          matchId,
          result.delivery,
          result.updatedInnings!,
          strikerStat ? { playerId: strikerStat.playerId, name: strikerStat.name, runs: strikerStat.runs, balls: strikerStat.balls, fours: strikerStat.fours, sixes: strikerStat.sixes } : null,
          bowlerStat ? { playerId: bowlerStat.playerId, name: bowlerStat.name, overs: String(bowlerStat.overs), maidens: bowlerStat.maidens, runs: bowlerStat.runs, wickets: bowlerStat.wickets } : null,
          currentOver,
        );
        broadcastScoreUpdate(matchId, scoreUpdateMsg);

        // Broadcast wicket if applicable
        if (result.delivery.isWicket && ctx.body.wicket) {
          const [wicketRecord] = await db
            .select({
              dismissedPlayerId: wicketsByDelivery.dismissedPlayerId,
              dismissalTypeId: wicketsByDelivery.dismissalTypeId,
              fielderId: wicketsByDelivery.fielderId,
            })
            .from(wicketsByDelivery)
            .where(eq(wicketsByDelivery.deliveryId, result.delivery.id))
            .limit(1);

          if (wicketRecord) {
            const [dismissedPlayer] = await db.select({ name: users.displayName }).from(users).where(eq(users.id, wicketRecord.dismissedPlayerId)).limit(1);
            const [dismissalType] = await db.select({ name: dismissalTypes.name }).from(dismissalTypes).where(eq(dismissalTypes.id, wicketRecord.dismissalTypeId)).limit(1);
            const fielderName = wicketRecord.fielderId
              ? (await db.select({ name: users.displayName }).from(users).where(eq(users.id, wicketRecord.fielderId)).limit(1))[0]?.name ?? null
              : null;
            const [bowlerUser] = await db.select({ name: users.displayName }).from(users).where(eq(users.id, ctx.body.bowlerId)).limit(1);

            const wicketMsg = buildWicketMessage(
              matchId,
              dismissedPlayer?.name ?? 'Unknown',
              dismissalType?.name ?? 'unknown',
              fielderName,
              bowlerUser?.name ?? null,
              `${result.updatedInnings!.totalRuns}/${result.updatedInnings!.totalWickets}`,
              String(result.updatedInnings!.totalOvers),
            );
            broadcastWicket(matchId, wicketMsg);
          }
        }

        // Broadcast innings complete if applicable
        if (result.inningsComplete && result.updatedInnings) {
          const [battingTeam] = await db
            .select({ name: teams.name })
            .from(teams)
            .where(eq(teams.id, result.updatedInnings.battingTeamId))
            .limit(1);

          const inningsMsg = buildInningsCompleteMessage(
            matchId,
            result.updatedInnings,
            battingTeam?.name ?? 'Unknown',
          );
          broadcastInningsComplete(matchId, inningsMsg);
        }

        // Broadcast match complete if applicable
        if (result.matchComplete) {
          const [mr] = await db
            .select()
            .from(matchResult)
            .where(eq(matchResult.matchId, matchId))
            .limit(1);

          if (mr) {
            const winnerName = mr.winnerTeamId
              ? (await db.select({ name: teams.name }).from(teams).where(eq(teams.id, mr.winnerTeamId)).limit(1))[0]?.name ?? null
              : null;

            const matchMsg = buildMatchCompleteMessage(matchId, mr, winnerName);
            broadcastMatchComplete(matchId, matchMsg);
          }
        }
      } catch (err) {
        // Don't let broadcast errors affect the HTTP response
        console.error('Broadcast error after delivery:', err);
      }

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

      const matchId = ctx.params.id;
      const deliveryId = ctx.params.did;

      // Read delivery info before undo (it gets deleted)
      const [deliveryInfo] = await db
        .select({
          inningsId: deliveries.inningsId,
          strikerId: deliveries.strikerId,
          bowlerId: deliveries.bowlerId,
          overNumber: deliveries.overNumber,
        })
        .from(deliveries)
        .where(eq(deliveries.id, deliveryId))
        .limit(1);

      await undoDelivery(matchId, deliveryId, user.id);

      // --- Broadcast delivery_undone ---
      try {
        if (deliveryInfo) {
          const [updatedInn] = await db
            .select()
            .from(innings)
            .where(eq(innings.id, deliveryInfo.inningsId))
            .limit(1);

          const [batterStat] = await db
            .select({
              playerId: battingStats.playerId,
              runs: battingStats.runsScored,
              balls: battingStats.ballsFaced,
              fours: battingStats.fours,
              sixes: battingStats.sixes,
            })
            .from(battingStats)
            .where(
              and(
                eq(battingStats.inningsId, deliveryInfo.inningsId),
                eq(battingStats.playerId, deliveryInfo.strikerId),
              ),
            )
            .limit(1);

          const [bowlerStat] = deliveryInfo.bowlerId
            ? await db
                .select({
                  playerId: bowlingStats.playerId,
                  overs: bowlingStats.oversBowled,
                  runs: bowlingStats.runsConceded,
                  wickets: bowlingStats.wicketsTaken,
                  maidens: bowlingStats.maidens,
                })
                .from(bowlingStats)
                .where(
                  and(
                    eq(bowlingStats.inningsId, deliveryInfo.inningsId),
                    eq(bowlingStats.playerId, deliveryInfo.bowlerId),
                  ),
                )
                .limit(1)
            : [undefined];

          // Get current over after undo — find last delivery to determine current over
          const [lastDel] = await db
            .select({ overNumber: deliveries.overNumber })
            .from(deliveries)
            .where(eq(deliveries.inningsId, deliveryInfo.inningsId))
            .orderBy(desc(deliveries.sequenceNumber))
            .limit(1);

          const currentOverNumber = lastDel?.overNumber ?? 0;
          const currentOver = await getCurrentOverBalls(deliveryInfo.inningsId, currentOverNumber);

          if (updatedInn) {
            const undoMsg = buildDeliveryUndoneMessage(
              matchId,
              deliveryId,
              updatedInn,
              batterStat ?? null,
              bowlerStat ? { playerId: bowlerStat.playerId, overs: String(bowlerStat.overs), runs: bowlerStat.runs, wickets: bowlerStat.wickets, maidens: bowlerStat.maidens } : null,
              currentOver,
            );
            broadcastDeliveryUndone(matchId, undoMsg);
          }
        }
      } catch (err) {
        console.error('Broadcast error after undo:', err);
      }

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

      const matchId = ctx.params.id;
      await abandonMatch(matchId, user.id);

      // --- Broadcast match_complete (abandoned) ---
      try {
        const [mr] = await db
          .select()
          .from(matchResult)
          .where(eq(matchResult.matchId, matchId))
          .limit(1);

        if (mr) {
          const matchMsg = buildMatchCompleteMessage(matchId, mr, null);
          broadcastMatchComplete(matchId, matchMsg);
        }
      } catch (err) {
        console.error('Broadcast error after abandon:', err);
      }

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

      const matchId = ctx.params.id;
      await declareInnings(matchId, user.id);

      // --- Broadcast innings_complete ---
      try {
        // Find the most recently completed innings
        const [completedInnings] = await db
          .select()
          .from(innings)
          .where(
            and(
              eq(innings.matchId, matchId),
              eq(innings.isCompleted, true),
            ),
          )
          .orderBy(desc(innings.inningsNumber))
          .limit(1);

        if (completedInnings) {
          const [battingTeam] = await db
            .select({ name: teams.name })
            .from(teams)
            .where(eq(teams.id, completedInnings.battingTeamId))
            .limit(1);

          const inningsMsg = buildInningsCompleteMessage(
            matchId,
            completedInnings,
            battingTeam?.name ?? 'Unknown',
          );
          broadcastInningsComplete(matchId, inningsMsg);
        }
      } catch (err) {
        console.error('Broadcast error after declare:', err);
      }

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

      const matchId = ctx.params.id;
      const target = ctx.body.target;

      if (target === 'innings') {
        await reopenInnings(matchId, user.id);
      } else if (target === 'match') {
        await reopenMatch(matchId, user.id);
      } else {
        throw new AppError('VALIDATION_ERROR', 'target must be "innings" or "match"', 400);
      }

      // --- Broadcast match_state (full refresh) ---
      try {
        const state = await getMatchState(matchId);
        broadcastMatchState(matchId, state);
      } catch (err) {
        console.error('Broadcast error after reopen:', err);
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
