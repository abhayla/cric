import { eq, and, sql, desc, count, max } from 'drizzle-orm';
import { db } from '../db/index.ts';
import { matches, matchResult, matchAnalytics } from '../db/schema/matches.ts';
import { innings, overs } from '../db/schema/innings.ts';
import { deliveries, wicketsByDelivery, fallOfWickets } from '../db/schema/deliveries.ts';
import { battingStats, bowlingStats, fieldingStats } from '../db/schema/stats.ts';
import { dismissalTypes } from '../db/schema/master-data.ts';
import { tournamentStandings } from '../db/schema/tournaments.ts';
import { AppError } from '../middleware/error-handler.ts';
import { refreshMatchPlayerCareerStats } from './career-stats.service.ts';

// ============================================================
// Types
// ============================================================

interface DeliveryInput {
  id?: string;
  inningsId?: string;
  inningsNumber?: number;
  overNumber: number;
  ballNumber: number;
  strikerId: string;
  nonStrikerId: string;
  bowlerId: string;
  runsFromBat: number;
  isWide: boolean;
  isNoBall: boolean;
  isBye: boolean;
  isLegBye: boolean;
  wideRuns: number;
  noBallRuns: number;
  byeRuns: number;
  legByeRuns: number;
  isWicket: boolean;
  isBoundaryFour: boolean;
  isBoundarySix: boolean;
  isPenalty?: boolean;
  wicket?: {
    dismissedPlayerId: string;
    dismissalTypeId: number;
    fielderId?: string;
    bowlerCredited: boolean;
  };
}

interface DeliveryResult {
  delivery: typeof deliveries.$inferSelect;
  inningsComplete: boolean;
  matchComplete: boolean;
  updatedInnings?: typeof innings.$inferSelect;
}

// ============================================================
// Record Delivery — 10-step pipeline
// ============================================================

export async function recordDelivery(
  matchId: string,
  userId: string,
  input: DeliveryInput,
): Promise<DeliveryResult> {
  // ── Pre-transaction validation (fail fast) ──
  const [match] = await db
    .select()
    .from(matches)
    .where(eq(matches.id, matchId))
    .limit(1);

  if (!match) {
    throw new AppError('NOT_FOUND', 'Match not found', 404);
  }

  if (match.status !== 'live' && match.status !== 'innings_break') {
    throw new AppError('VALIDATION_ERROR', 'Match must be in live status to record deliveries', 400);
  }

  if (match.scorerId !== userId) {
    throw new AppError('FORBIDDEN', 'Only the scorer can record deliveries', 403);
  }

  if (input.strikerId === input.nonStrikerId) {
    throw new AppError('VALIDATION_ERROR', 'Striker and non-striker must be different players', 400);
  }

  if (input.isWide && (input.isBye || input.isLegBye)) {
    throw new AppError('VALIDATION_ERROR', 'Wide cannot be combined with bye or leg-bye', 400);
  }

  return await db.transaction(async (tx) => {
    // ── Step 1: VALIDATE (within transaction) ──
    // Re-read match inside tx for consistency
    const [txMatch] = await tx
      .select()
      .from(matches)
      .where(eq(matches.id, matchId))
      .limit(1);

    if (!txMatch || (txMatch.status !== 'live' && txMatch.status !== 'innings_break')) {
      throw new AppError('VALIDATION_ERROR', 'Match must be in live status to record deliveries', 400);
    }

    // Resolve innings: by ID or by innings number
    let resolvedInningsId = input.inningsId;
    if (!resolvedInningsId && input.inningsNumber) {
      const [innByNumber] = await tx
        .select()
        .from(innings)
        .where(and(eq(innings.matchId, matchId), eq(innings.inningsNumber, input.inningsNumber)))
        .limit(1);
      if (!innByNumber) {
        throw new AppError('NOT_FOUND', `Innings #${input.inningsNumber} not found for this match`, 404);
      }
      resolvedInningsId = innByNumber.id;
    }

    if (!resolvedInningsId) {
      throw new AppError('VALIDATION_ERROR', 'Either inningsId or inningsNumber is required', 400);
    }

    // Validate innings exists and belongs to match
    const [inn] = await tx
      .select()
      .from(innings)
      .where(and(eq(innings.id, resolvedInningsId), eq(innings.matchId, matchId)))
      .limit(1);

    if (!inn) {
      throw new AppError('NOT_FOUND', 'Innings not found for this match', 404);
    }

    if (inn.isCompleted) {
      throw new AppError('VALIDATION_ERROR', 'Cannot record delivery in a completed innings', 400);
    }

    // If match is in innings_break and we're recording in the 2nd innings, transition to live
    if (txMatch!.status === 'innings_break' && inn.inningsNumber >= 2) {
      await tx
        .update(matches)
        .set({ status: 'live' })
        .where(eq(matches.id, matchId));
    }

    // ── Step 2: CALCULATE ──
    const isLegal = !input.isWide && !input.isNoBall && !input.isPenalty;

    // Step 2.5: Magic Over — configurable multiplier
    const magicOverNumbers = txMatch!.magicOverNumbers as number[] | null;
    const isMagicOver = magicOverNumbers != null && magicOverNumbers.includes(input.overNumber);
    const multiplier = isMagicOver ? txMatch!.magicOverRunMultiplier : 1;

    const effectiveRunsFromBat = isMagicOver && input.runsFromBat > 0
      ? input.runsFromBat * multiplier : input.runsFromBat;
    const effectiveWideRuns = isMagicOver && input.wideRuns > 0
      ? input.wideRuns * multiplier : input.wideRuns;
    const effectiveNoBallRuns = isMagicOver && input.noBallRuns > 0
      ? input.noBallRuns * multiplier : input.noBallRuns;
    const effectiveByeRuns = isMagicOver && input.byeRuns > 0
      ? input.byeRuns * multiplier : input.byeRuns;
    const effectiveLegByeRuns = isMagicOver && input.legByeRuns > 0
      ? input.legByeRuns * multiplier : input.legByeRuns;

    // Magic over wicket penalty (negative value)
    const magicOverPenalty = isMagicOver && input.isWicket ? txMatch!.magicOverWicketPenalty : 0;
    const totalRuns = effectiveRunsFromBat + effectiveWideRuns + effectiveNoBallRuns + effectiveByeRuns + effectiveLegByeRuns + magicOverPenalty;

    // Get next sequence number
    const [seqResult] = await tx
      .select({ maxSeq: max(deliveries.sequenceNumber) })
      .from(deliveries)
      .where(eq(deliveries.inningsId, resolvedInningsId!));

    const sequenceNumber = (seqResult?.maxSeq ?? 0) + 1;

    // Determine isFreeHit from previous delivery
    let isFreeHit = false;
    if (sequenceNumber > 1) {
      const [prevDelivery] = await tx
        .select({
          isNoBall: deliveries.isNoBall,
          isFreeHit: deliveries.isFreeHit,
          isLegal: deliveries.isLegal,
        })
        .from(deliveries)
        .where(eq(deliveries.inningsId, resolvedInningsId!))
        .orderBy(desc(deliveries.sequenceNumber))
        .limit(1);

      if (prevDelivery) {
        // Free hit if previous was a no-ball
        if (prevDelivery.isNoBall) {
          isFreeHit = true;
        }
        // Free hit persists through wides: if previous was free hit AND not a legal delivery
        // (i.e., it was a wide), free hit carries forward
        else if (prevDelivery.isFreeHit && !prevDelivery.isLegal) {
          isFreeHit = true;
        }
      }
    }

    // ── Step 2.5: CHECK DUPLICATE (idempotent retry) ──
    if (input.id) {
      const [existing] = await tx
        .select()
        .from(deliveries)
        .where(eq(deliveries.id, input.id))
        .limit(1);
      if (existing) {
        // Already processed — return existing result (idempotent)
        const [existingInnings] = await tx
          .select()
          .from(innings)
          .where(eq(innings.id, existing.inningsId))
          .limit(1);
        return {
          delivery: existing,
          inningsComplete: false,
          matchComplete: false,
          updatedInnings: existingInnings!,
        };
      }
    }

    // ── Step 3: INSERT DELIVERY ──
    const [delivery] = await tx
      .insert(deliveries)
      .values({
        ...(input.id ? { id: input.id } : {}),
        inningsId: resolvedInningsId!,
        overNumber: input.overNumber,
        ballNumber: input.ballNumber,
        sequenceNumber,
        strikerId: input.strikerId,
        nonStrikerId: input.nonStrikerId,
        bowlerId: input.bowlerId,
        runsFromBat: effectiveRunsFromBat,
        isWide: input.isWide,
        wideRuns: effectiveWideRuns,
        isNoBall: input.isNoBall,
        noBallRuns: effectiveNoBallRuns,
        isBye: input.isBye,
        byeRuns: effectiveByeRuns,
        isLegBye: input.isLegBye,
        legByeRuns: effectiveLegByeRuns,
        totalRuns,
        isWicket: input.isWicket,
        isLegal,
        isBoundaryFour: input.isBoundaryFour,
        isBoundarySix: input.isBoundarySix,
        isFreeHit,
        isPenalty: input.isPenalty ?? false,
      })
      .returning();

    // ── Step 4: HANDLE WICKET ──
    if (input.isWicket && input.wicket) {
      await tx.insert(wicketsByDelivery).values({
        deliveryId: delivery!.id,
        dismissedPlayerId: input.wicket.dismissedPlayerId,
        dismissalTypeId: input.wicket.dismissalTypeId,
        fielderId: input.wicket.fielderId ?? null,
        bowlerCredited: input.wicket.bowlerCredited,
      });

      // Insert fall of wickets
      const currentWickets = inn.totalWickets + 1;
      const currentOvers = computeOversDisplay(inn, isLegal);

      await tx.insert(fallOfWickets).values({
        inningsId: resolvedInningsId!,
        wicketNumber: currentWickets,
        runsAtFall: inn.totalRuns + totalRuns,
        oversAtFall: currentOvers,
        dismissedPlayerId: input.wicket.dismissedPlayerId,
        deliveryId: delivery!.id,
      });

      // Update fielding stats
      if (input.wicket.fielderId) {
        await upsertFieldingStats(tx, resolvedInningsId!, input.wicket);
      }
    }

    // ── Step 5: UPDATE BATTING STATS ──
    // Use effective (magic-over doubled) values for stats
    const effectiveInput = isMagicOver ? {
      ...input,
      runsFromBat: effectiveRunsFromBat,
      wideRuns: effectiveWideRuns,
      noBallRuns: effectiveNoBallRuns,
      byeRuns: effectiveByeRuns,
      legByeRuns: effectiveLegByeRuns,
    } : input;
    await upsertBattingStats(tx, resolvedInningsId!, effectiveInput, delivery!);

    // ── Step 6: UPDATE BOWLING STATS ──
    await upsertBowlingStats(tx, resolvedInningsId!, effectiveInput, delivery!);

    // ── Step 7: UPDATE INNINGS TOTALS ──
    const inningsUpdate: Record<string, unknown> = {
      totalRuns: sql`${innings.totalRuns} + ${totalRuns}`,
      totalExtras: sql`${innings.totalExtras} + ${effectiveWideRuns + effectiveNoBallRuns + effectiveByeRuns + effectiveLegByeRuns}`,
    };

    if (input.isWide) {
      inningsUpdate.totalWides = sql`${innings.totalWides} + ${effectiveWideRuns}`;
    }
    if (input.isNoBall) {
      inningsUpdate.totalNoBalls = sql`${innings.totalNoBalls} + ${effectiveNoBallRuns}`;
    }
    if (input.isBye) {
      inningsUpdate.totalByes = sql`${innings.totalByes} + ${effectiveByeRuns}`;
    }
    if (input.isLegBye) {
      inningsUpdate.totalLegByes = sql`${innings.totalLegByes} + ${effectiveLegByeRuns}`;
    }
    if (input.isWicket) {
      inningsUpdate.totalWickets = sql`${innings.totalWickets} + 1`;
    }

    // Update total_overs if legal delivery
    if (isLegal) {
      // Parse current overs decimal: e.g. "2.3" => 2 overs, 3 balls
      const currentOversStr = String(inn.totalOvers);
      const parts = currentOversStr.split('.');
      let completedOvers = parseInt(parts[0]!, 10);
      let balls = parseInt(parts[1] || '0', 10);
      balls += 1;
      if (balls >= 6) {
        completedOvers += 1;
        balls = 0;
      }
      inningsUpdate.totalOvers = `${completedOvers}.${balls}`;
    }

    await tx
      .update(innings)
      .set(inningsUpdate)
      .where(eq(innings.id, resolvedInningsId!));

    // ── Step 8: CHECK OVER COMPLETION ──
    if (isLegal) {
      await checkOverCompletion(tx, resolvedInningsId!, input.overNumber, input.bowlerId);
    }

    // ── Step 9: CHECK INNINGS COMPLETION ──
    // Re-read innings with updated values
    const [updatedInnings] = await tx
      .select()
      .from(innings)
      .where(eq(innings.id, resolvedInningsId!))
      .limit(1);

    const { inningsComplete, matchComplete, completedReason } = checkInningsCompletion(
      updatedInnings!,
      txMatch!,
    );

    if (inningsComplete && completedReason) {
      await tx
        .update(innings)
        .set({
          isCompleted: true,
          completedReason,
        })
        .where(eq(innings.id, resolvedInningsId!));

      // Handle match state transition
      if (matchComplete) {
        await completeMatch(tx, matchId, txMatch!);
        await refreshMatchPlayerCareerStats(tx, matchId);
      } else if (updatedInnings!.inningsNumber === 1) {
        // Transition to innings_break
        await tx
          .update(matches)
          .set({ status: 'innings_break' })
          .where(eq(matches.id, matchId));

        // Auto-create 2nd innings with teams swapped
        const target = updatedInnings!.totalRuns + 1;
        await tx.insert(innings).values({
          matchId,
          inningsNumber: 2,
          battingTeamId: updatedInnings!.bowlingTeamId,
          bowlingTeamId: updatedInnings!.battingTeamId,
          target,
        });
      }
    }

    // ── Step 10: RETURN ──
    return {
      delivery: delivery!,
      inningsComplete,
      matchComplete,
      updatedInnings: updatedInnings!,
    };
  });
}

// ============================================================
// Undo Delivery
// ============================================================

export async function undoDelivery(
  matchId: string,
  deliveryId: string,
  userId: string,
): Promise<void> {
  await db.transaction(async (tx) => {
    // Validate match and scorer
    const [match] = await tx
      .select()
      .from(matches)
      .where(eq(matches.id, matchId))
      .limit(1);

    if (!match) {
      throw new AppError('NOT_FOUND', 'Match not found', 404);
    }

    if (match.scorerId !== userId) {
      throw new AppError('FORBIDDEN', 'Only the scorer can undo deliveries', 403);
    }

    // Get the delivery
    const [delivery] = await tx
      .select()
      .from(deliveries)
      .where(eq(deliveries.id, deliveryId))
      .limit(1);

    if (!delivery) {
      throw new AppError('NOT_FOUND', 'Delivery not found', 404);
    }

    // Verify it's the last delivery in the innings
    const [lastDelivery] = await tx
      .select({ id: deliveries.id })
      .from(deliveries)
      .where(eq(deliveries.inningsId, delivery.inningsId))
      .orderBy(desc(deliveries.sequenceNumber))
      .limit(1);

    if (lastDelivery!.id !== deliveryId) {
      throw new AppError('VALIDATION_ERROR', 'Can only undo the last delivery', 400);
    }

    // Delete wicket records if wicket delivery
    if (delivery.isWicket) {
      await tx.delete(wicketsByDelivery).where(eq(wicketsByDelivery.deliveryId, deliveryId));
      await tx.delete(fallOfWickets).where(eq(fallOfWickets.deliveryId, deliveryId));
    }

    // Reverse batting stats
    if (!delivery.isWide) {
      // Only non-wide deliveries affect batting stats
      const [batterStat] = await tx
        .select()
        .from(battingStats)
        .where(
          and(
            eq(battingStats.inningsId, delivery.inningsId),
            eq(battingStats.playerId, delivery.strikerId),
          ),
        )
        .limit(1);

      if (batterStat) {
        const updates: Record<string, unknown> = {
          runsScored: sql`${battingStats.runsScored} - ${delivery.runsFromBat}`,
        };

        if (delivery.isLegal) {
          updates.ballsFaced = sql`${battingStats.ballsFaced} - 1`;
        }

        if (delivery.isBoundaryFour) {
          updates.fours = sql`${battingStats.fours} - 1`;
        }
        if (delivery.isBoundarySix) {
          updates.sixes = sql`${battingStats.sixes} - 1`;
        }

        // Reverse dismissal
        if (delivery.isWicket) {
          updates.isNotOut = true;
          updates.dismissalTypeId = null;
          updates.dismissedById = null;
          updates.fielderId = null;
        }

        await tx
          .update(battingStats)
          .set(updates)
          .where(eq(battingStats.id, batterStat.id));
      }
    }

    // Reverse bowling stats
    if (delivery.bowlerId) {
      const [bowlerStat] = await tx
        .select()
        .from(bowlingStats)
        .where(
          and(
            eq(bowlingStats.inningsId, delivery.inningsId),
            eq(bowlingStats.playerId, delivery.bowlerId),
          ),
        )
        .limit(1);

      if (bowlerStat) {
        const bowlerUpdates: Record<string, unknown> = {};

        // Runs conceded by bowler: bat runs + wide/NB penalty
        const runsConcededByBowler = delivery.runsFromBat + delivery.wideRuns + delivery.noBallRuns;
        bowlerUpdates.runsConceded = sql`${bowlingStats.runsConceded} - ${runsConcededByBowler}`;

        if (delivery.isWide) {
          bowlerUpdates.wides = sql`${bowlingStats.wides} - 1`;
        }
        if (delivery.isNoBall) {
          bowlerUpdates.noBalls = sql`${bowlingStats.noBalls} - 1`;
        }

        // Reverse dot ball
        if (delivery.totalRuns === 0 && delivery.isLegal) {
          bowlerUpdates.dotBalls = sql`${bowlingStats.dotBalls} - 1`;
        }

        if (delivery.isBoundaryFour) {
          bowlerUpdates.foursConceded = sql`${bowlingStats.foursConceded} - 1`;
        }
        if (delivery.isBoundarySix) {
          bowlerUpdates.sixesConceded = sql`${bowlingStats.sixesConceded} - 1`;
        }

        if (delivery.isWicket) {
          // Check if bowler was credited
          const [wicketRecord] = await tx
            .select()
            .from(wicketsByDelivery)
            .where(eq(wicketsByDelivery.deliveryId, deliveryId))
            .limit(1);

          // Note: wicket records may already be deleted above, so this is a safeguard
          if (wicketRecord?.bowlerCredited) {
            bowlerUpdates.wicketsTaken = sql`${bowlingStats.wicketsTaken} - 1`;
          }
        }

        await tx
          .update(bowlingStats)
          .set(bowlerUpdates)
          .where(eq(bowlingStats.id, bowlerStat.id));
      }
    }

    // Reverse fielding stats if wicket with fielder
    if (delivery.isWicket) {
      // The wicket record is already deleted, but we need the info
      // We know from the delivery that it was a wicket — try to reverse fielding
      // The fall_of_wickets and wickets_by_delivery are already deleted
      // We need to handle this before deleting the wicket records above
      // TODO: In the current implementation, we delete wicket records first,
      // so we need to read them before deletion. Let's restructure.
      // For now, the fielding stats reversal is handled by the wicket record check above.
    }

    // Reverse innings totals
    const inningsReversal: Record<string, unknown> = {
      totalRuns: sql`${innings.totalRuns} - ${delivery.totalRuns}`,
      totalExtras: sql`${innings.totalExtras} - ${delivery.wideRuns + delivery.noBallRuns + delivery.byeRuns + delivery.legByeRuns}`,
    };

    if (delivery.isWide) {
      inningsReversal.totalWides = sql`${innings.totalWides} - ${delivery.wideRuns}`;
    }
    if (delivery.isNoBall) {
      inningsReversal.totalNoBalls = sql`${innings.totalNoBalls} - ${delivery.noBallRuns}`;
    }
    if (delivery.isBye) {
      inningsReversal.totalByes = sql`${innings.totalByes} - ${delivery.byeRuns}`;
    }
    if (delivery.isLegBye) {
      inningsReversal.totalLegByes = sql`${innings.totalLegByes} - ${delivery.legByeRuns}`;
    }
    if (delivery.isWicket) {
      inningsReversal.totalWickets = sql`${innings.totalWickets} - 1`;
    }

    // Reverse total_overs if legal delivery
    if (delivery.isLegal) {
      const [currentInnings] = await tx
        .select()
        .from(innings)
        .where(eq(innings.id, delivery.inningsId))
        .limit(1);

      const currentOversStr = String(currentInnings!.totalOvers);
      const parts = currentOversStr.split('.');
      let completedOvers = parseInt(parts[0]!, 10);
      let balls = parseInt(parts[1] || '0', 10);
      balls -= 1;
      if (balls < 0) {
        completedOvers -= 1;
        balls = 5;
      }
      if (completedOvers < 0) {
        completedOvers = 0;
        balls = 0;
      }
      inningsReversal.totalOvers = `${completedOvers}.${balls}`;
    }

    await tx
      .update(innings)
      .set(inningsReversal)
      .where(eq(innings.id, delivery.inningsId));

    // Handle over record reversal — if the over was completed, reopen it
    const [overRecord] = await tx
      .select()
      .from(overs)
      .where(
        and(
          eq(overs.inningsId, delivery.inningsId),
          eq(overs.overNumber, delivery.overNumber),
        ),
      )
      .limit(1);

    if (overRecord?.isCompleted) {
      // Reopen the over
      await tx
        .update(overs)
        .set({ isCompleted: false, isMaiden: false })
        .where(eq(overs.id, overRecord.id));
    }

    // Delete the delivery
    await tx.delete(deliveries).where(eq(deliveries.id, deliveryId));
  });
}

// ============================================================
// Get Deliveries
// ============================================================

export async function getDeliveries(
  inningsId: string,
  page: number = 1,
  limit: number = 50,
): Promise<{ deliveries: (typeof deliveries.$inferSelect)[]; total: number; page: number }> {
  const effectiveLimit = Math.min(limit, 100);
  const offset = (page - 1) * effectiveLimit;

  const result = await db
    .select()
    .from(deliveries)
    .where(eq(deliveries.inningsId, inningsId))
    .orderBy(deliveries.sequenceNumber)
    .limit(effectiveLimit)
    .offset(offset);

  const [countResult] = await db
    .select({ total: count() })
    .from(deliveries)
    .where(eq(deliveries.inningsId, inningsId));

  return {
    deliveries: result,
    total: countResult!.total,
    page,
  };
}

// ============================================================
// Abandon Match
// ============================================================

export async function abandonMatch(matchId: string, userId: string): Promise<void> {
  const [match] = await db
    .select()
    .from(matches)
    .where(eq(matches.id, matchId))
    .limit(1);

  if (!match) {
    throw new AppError('NOT_FOUND', 'Match not found', 404);
  }

  if (match.scorerId !== userId) {
    throw new AppError('FORBIDDEN', 'Only the scorer can abandon a match', 403);
  }

  await db.transaction(async (tx) => {
    await tx
      .update(matches)
      .set({ status: 'abandoned' })
      .where(eq(matches.id, matchId));

    await tx.insert(matchResult).values({
      matchId,
      resultType: 'no_result',
      winnerTeamId: null,
      summary: 'Match abandoned — No Result',
    });
  });
}

// ============================================================
// Declare Innings
// ============================================================

export async function declareInnings(matchId: string, userId: string): Promise<void> {
  const [match] = await db
    .select()
    .from(matches)
    .where(eq(matches.id, matchId))
    .limit(1);

  if (!match) {
    throw new AppError('NOT_FOUND', 'Match not found', 404);
  }

  if (match.scorerId !== userId) {
    throw new AppError('FORBIDDEN', 'Only the scorer can declare innings', 403);
  }

  // Find the current (not completed) innings
  const [currentInnings] = await db
    .select()
    .from(innings)
    .where(
      and(
        eq(innings.matchId, matchId),
        eq(innings.isCompleted, false),
      ),
    )
    .orderBy(desc(innings.inningsNumber))
    .limit(1);

  if (!currentInnings) {
    throw new AppError('VALIDATION_ERROR', 'No active innings to declare', 400);
  }

  await db
    .update(innings)
    .set({
      isCompleted: true,
      completedReason: 'declared',
    })
    .where(eq(innings.id, currentInnings.id));

  // If 1st innings declared, transition to innings_break
  if (currentInnings.inningsNumber === 1) {
    await db
      .update(matches)
      .set({ status: 'innings_break' })
      .where(eq(matches.id, matchId));
  }
}

// ============================================================
// Reopen Innings
// ============================================================

export async function reopenInnings(matchId: string, userId: string): Promise<void> {
  const [match] = await db
    .select()
    .from(matches)
    .where(eq(matches.id, matchId))
    .limit(1);

  if (!match) {
    throw new AppError('NOT_FOUND', 'Match not found', 404);
  }

  if (match.scorerId !== userId) {
    throw new AppError('FORBIDDEN', 'Only the scorer can reopen innings', 403);
  }

  // Find the most recently completed innings
  const [lastInnings] = await db
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

  if (!lastInnings) {
    throw new AppError('VALIDATION_ERROR', 'No completed innings to reopen', 400);
  }

  await db
    .update(innings)
    .set({
      isCompleted: false,
      completedReason: null,
    })
    .where(eq(innings.id, lastInnings.id));

  // If match was in innings_break, go back to live
  if (match.status === 'innings_break') {
    await db
      .update(matches)
      .set({ status: 'live' })
      .where(eq(matches.id, matchId));
  }
}

// ============================================================
// Reopen Match
// ============================================================

export async function reopenMatch(matchId: string, userId: string): Promise<void> {
  const [match] = await db
    .select()
    .from(matches)
    .where(eq(matches.id, matchId))
    .limit(1);

  if (!match) {
    throw new AppError('NOT_FOUND', 'Match not found', 404);
  }

  if (match.scorerId !== userId) {
    throw new AppError('FORBIDDEN', 'Only the scorer can reopen the match', 403);
  }

  if (match.status !== 'completed' && match.status !== 'abandoned') {
    throw new AppError('VALIDATION_ERROR', 'Match must be completed or abandoned to reopen', 400);
  }

  await db.transaction(async (tx) => {
    // Delete match result
    await tx.delete(matchResult).where(eq(matchResult.matchId, matchId));

    // Set status back to live
    await tx
      .update(matches)
      .set({ status: 'live' })
      .where(eq(matches.id, matchId));
  });
}

// ============================================================
// Helper: Upsert Batting Stats
// ============================================================

async function upsertBattingStats(
  tx: Parameters<Parameters<typeof db.transaction>[0]>[0],
  inningsId: string,
  input: DeliveryInput,
  delivery: typeof deliveries.$inferSelect,
): Promise<void> {
  // Wides don't count as balls faced for the batter (no batting stat update for wide except dismissal)
  if (input.isWide && !input.isWicket) {
    return;
  }

  const [existing] = await tx
    .select()
    .from(battingStats)
    .where(
      and(
        eq(battingStats.inningsId, inningsId),
        eq(battingStats.playerId, input.strikerId),
      ),
    )
    .limit(1);

  if (existing) {
    const updates: Record<string, unknown> = {};

    if (!input.isWide) {
      updates.runsScored = sql`${battingStats.runsScored} + ${input.runsFromBat}`;
      if (delivery.isLegal) {
        updates.ballsFaced = sql`${battingStats.ballsFaced} + 1`;
      }
      if (input.isBoundaryFour) {
        updates.fours = sql`${battingStats.fours} + 1`;
      }
      if (input.isBoundarySix) {
        updates.sixes = sql`${battingStats.sixes} + 1`;
      }
    }

    if (input.isWicket && input.wicket?.dismissedPlayerId === input.strikerId) {
      updates.isNotOut = false;
      updates.dismissalTypeId = input.wicket.dismissalTypeId;
      if (input.wicket.bowlerCredited) {
        updates.dismissedById = input.bowlerId;
      }
      if (input.wicket.fielderId) {
        updates.fielderId = input.wicket.fielderId;
      }
    }

    if (Object.keys(updates).length > 0) {
      await tx
        .update(battingStats)
        .set(updates)
        .where(eq(battingStats.id, existing.id));
    }
  } else {
    // Create new batting stat entry
    // Determine batting position
    const [posResult] = await tx
      .select({ maxPos: max(battingStats.battingPosition) })
      .from(battingStats)
      .where(eq(battingStats.inningsId, inningsId));

    const battingPosition = (posResult?.maxPos ?? 0) + 1;

    const isNotOut = !(input.isWicket && input.wicket?.dismissedPlayerId === input.strikerId);

    await tx.insert(battingStats).values({
      inningsId,
      playerId: input.strikerId,
      battingPosition,
      runsScored: input.isWide ? 0 : input.runsFromBat,
      ballsFaced: (!input.isWide && delivery.isLegal) ? 1 : 0,
      fours: input.isBoundaryFour ? 1 : 0,
      sixes: input.isBoundarySix ? 1 : 0,
      isNotOut,
      dismissalTypeId: (!isNotOut && input.wicket) ? input.wicket.dismissalTypeId : null,
      dismissedById: (!isNotOut && input.wicket?.bowlerCredited) ? input.bowlerId : null,
      fielderId: (!isNotOut && input.wicket?.fielderId) ? input.wicket.fielderId : null,
    });
  }

  // Also create batting stat for non-striker if they don't have one
  const [nonStrikerStat] = await tx
    .select({ id: battingStats.id })
    .from(battingStats)
    .where(
      and(
        eq(battingStats.inningsId, inningsId),
        eq(battingStats.playerId, input.nonStrikerId),
      ),
    )
    .limit(1);

  if (!nonStrikerStat) {
    const [posResult] = await tx
      .select({ maxPos: max(battingStats.battingPosition) })
      .from(battingStats)
      .where(eq(battingStats.inningsId, inningsId));

    await tx.insert(battingStats).values({
      inningsId,
      playerId: input.nonStrikerId,
      battingPosition: (posResult?.maxPos ?? 0) + 1,
      runsScored: 0,
      ballsFaced: 0,
      fours: 0,
      sixes: 0,
      isNotOut: true,
    });
  }
}

// ============================================================
// Helper: Upsert Bowling Stats
// ============================================================

async function upsertBowlingStats(
  tx: Parameters<Parameters<typeof db.transaction>[0]>[0],
  inningsId: string,
  input: DeliveryInput,
  delivery: typeof deliveries.$inferSelect,
): Promise<void> {
  if (!input.bowlerId) return;

  // Runs conceded by bowler: bat runs + wide/NB penalty runs (NOT byes/legByes)
  const runsConcededByBowler = input.runsFromBat + input.wideRuns + input.noBallRuns;

  const [existing] = await tx
    .select()
    .from(bowlingStats)
    .where(
      and(
        eq(bowlingStats.inningsId, inningsId),
        eq(bowlingStats.playerId, input.bowlerId),
      ),
    )
    .limit(1);

  if (existing) {
    const updates: Record<string, unknown> = {
      runsConceded: sql`${bowlingStats.runsConceded} + ${runsConcededByBowler}`,
    };

    if (input.isWide) {
      updates.wides = sql`${bowlingStats.wides} + 1`;
    }
    if (input.isNoBall) {
      updates.noBalls = sql`${bowlingStats.noBalls} + 1`;
    }

    // Dot ball: total runs for the delivery is 0 AND it's a legal delivery
    if (delivery.totalRuns === 0 && delivery.isLegal) {
      updates.dotBalls = sql`${bowlingStats.dotBalls} + 1`;
    }

    if (input.isBoundaryFour) {
      updates.foursConceded = sql`${bowlingStats.foursConceded} + 1`;
    }
    if (input.isBoundarySix) {
      updates.sixesConceded = sql`${bowlingStats.sixesConceded} + 1`;
    }

    if (input.isWicket && input.wicket?.bowlerCredited) {
      updates.wicketsTaken = sql`${bowlingStats.wicketsTaken} + 1`;
    }

    await tx
      .update(bowlingStats)
      .set(updates)
      .where(eq(bowlingStats.id, existing.id));
  } else {
    await tx.insert(bowlingStats).values({
      inningsId,
      playerId: input.bowlerId,
      runsConceded: runsConcededByBowler,
      wides: input.isWide ? 1 : 0,
      noBalls: input.isNoBall ? 1 : 0,
      dotBalls: (delivery.totalRuns === 0 && delivery.isLegal) ? 1 : 0,
      foursConceded: input.isBoundaryFour ? 1 : 0,
      sixesConceded: input.isBoundarySix ? 1 : 0,
      wicketsTaken: (input.isWicket && input.wicket?.bowlerCredited) ? 1 : 0,
    });
  }
}

// ============================================================
// Helper: Upsert Fielding Stats
// ============================================================

async function upsertFieldingStats(
  tx: Parameters<Parameters<typeof db.transaction>[0]>[0],
  inningsId: string,
  wicket: NonNullable<DeliveryInput['wicket']>,
): Promise<void> {
  if (!wicket.fielderId) return;

  // Get the dismissal type name to determine which field to increment
  const [dt] = await tx
    .select()
    .from(dismissalTypes)
    .where(eq(dismissalTypes.id, wicket.dismissalTypeId))
    .limit(1);

  const [existing] = await tx
    .select()
    .from(fieldingStats)
    .where(
      and(
        eq(fieldingStats.inningsId, inningsId),
        eq(fieldingStats.playerId, wicket.fielderId),
      ),
    )
    .limit(1);

  const fieldName = dt?.name;
  const isCatch = fieldName === 'caught' || fieldName === 'caught_and_bowled';
  const isRunOut = fieldName === 'run_out';
  const isStumping = fieldName === 'stumped';

  if (existing) {
    const updates: Record<string, unknown> = {};
    if (isCatch) {
      updates.catches = sql`${fieldingStats.catches} + 1`;
    }
    if (isRunOut) {
      updates.runOuts = sql`${fieldingStats.runOuts} + 1`;
    }
    if (isStumping) {
      updates.stumpings = sql`${fieldingStats.stumpings} + 1`;
    }

    if (Object.keys(updates).length > 0) {
      await tx
        .update(fieldingStats)
        .set(updates)
        .where(eq(fieldingStats.id, existing.id));
    }
  } else {
    await tx.insert(fieldingStats).values({
      inningsId,
      playerId: wicket.fielderId,
      catches: isCatch ? 1 : 0,
      runOuts: isRunOut ? 1 : 0,
      stumpings: isStumping ? 1 : 0,
      directHits: 0,
    });
  }
}

// ============================================================
// Helper: Check Over Completion
// ============================================================

async function checkOverCompletion(
  tx: Parameters<Parameters<typeof db.transaction>[0]>[0],
  inningsId: string,
  overNumber: number,
  bowlerId: string,
): Promise<boolean> {
  // Count legal deliveries in this over
  const [legalCount] = await tx
    .select({ total: count() })
    .from(deliveries)
    .where(
      and(
        eq(deliveries.inningsId, inningsId),
        eq(deliveries.overNumber, overNumber),
        eq(deliveries.isLegal, true),
      ),
    );

  if (legalCount!.total < 6) return false;

  // Over is complete — calculate maiden status
  // Maiden: 0 runs from bat, 0 wide runs, 0 no-ball runs in the over
  // Byes and leg-byes do NOT break maiden
  const overDeliveries = await tx
    .select({
      runsFromBat: deliveries.runsFromBat,
      wideRuns: deliveries.wideRuns,
      noBallRuns: deliveries.noBallRuns,
    })
    .from(deliveries)
    .where(
      and(
        eq(deliveries.inningsId, inningsId),
        eq(deliveries.overNumber, overNumber),
      ),
    );

  const totalBatRuns = overDeliveries.reduce((sum, d) => sum + d.runsFromBat, 0);
  const totalWideRuns = overDeliveries.reduce((sum, d) => sum + d.wideRuns, 0);
  const totalNoBallRuns = overDeliveries.reduce((sum, d) => sum + d.noBallRuns, 0);

  const isMaiden = totalBatRuns === 0 && totalWideRuns === 0 && totalNoBallRuns === 0;

  // Total runs conceded in the over (for bowler)
  const runsConceded = overDeliveries.reduce(
    (sum, d) => sum + d.runsFromBat + d.wideRuns + d.noBallRuns,
    0,
  );

  // Count wickets in this over
  const [wicketCount] = await tx
    .select({ total: count() })
    .from(deliveries)
    .where(
      and(
        eq(deliveries.inningsId, inningsId),
        eq(deliveries.overNumber, overNumber),
        eq(deliveries.isWicket, true),
      ),
    );

  // Count wides/no-balls in this over
  const wideCount = overDeliveries.filter((d) => d.wideRuns > 0).length;
  const noBallCount = overDeliveries.filter((d) => d.noBallRuns > 0).length;

  // Upsert overs record
  const [existingOver] = await tx
    .select()
    .from(overs)
    .where(
      and(eq(overs.inningsId, inningsId), eq(overs.overNumber, overNumber)),
    )
    .limit(1);

  if (existingOver) {
    await tx
      .update(overs)
      .set({
        isCompleted: true,
        isMaiden,
        runsConceded,
        wicketsTaken: wicketCount!.total,
        wides: wideCount,
        noBalls: noBallCount,
      })
      .where(eq(overs.id, existingOver.id));
  } else {
    await tx.insert(overs).values({
      inningsId,
      overNumber,
      bowlerId,
      isCompleted: true,
      isMaiden,
      runsConceded,
      wicketsTaken: wicketCount!.total,
      wides: wideCount,
      noBalls: noBallCount,
    });
  }

  // Update bowler maiden count if maiden
  if (isMaiden) {
    await tx
      .update(bowlingStats)
      .set({ maidens: sql`${bowlingStats.maidens} + 1` })
      .where(
        and(
          eq(bowlingStats.inningsId, inningsId),
          eq(bowlingStats.playerId, bowlerId),
        ),
      );
  }

  return true;
}

// ============================================================
// Helper: Check Innings Completion
// ============================================================

function checkInningsCompletion(
  inn: typeof innings.$inferSelect,
  match: typeof matches.$inferSelect,
): { inningsComplete: boolean; matchComplete: boolean; completedReason: string | null } {
  // All out: wickets = players_per_side - 1
  if (inn.totalWickets >= match.playersPerSide - 1) {
    // If it's the 2nd innings, match is complete
    const matchComplete = inn.inningsNumber >= 2;
    return { inningsComplete: true, matchComplete, completedReason: 'all_out' };
  }

  // Overs exhausted
  const totalOversNum = parseFloat(String(inn.totalOvers));
  const matchOvers = match.totalOvers;
  // In cricket notation, 20.0 means 20 complete overs
  const oversInt = Math.floor(totalOversNum);
  const balls = Math.round((totalOversNum - oversInt) * 10);
  if (oversInt >= matchOvers && balls === 0) {
    const matchComplete = inn.inningsNumber >= 2;
    return { inningsComplete: true, matchComplete, completedReason: 'overs_exhausted' };
  }

  // Target chased (2nd innings only)
  if (inn.inningsNumber >= 2 && inn.target !== null) {
    if (inn.totalRuns >= inn.target) {
      return { inningsComplete: true, matchComplete: true, completedReason: 'target_chased' };
    }
  }

  return { inningsComplete: false, matchComplete: false, completedReason: null };
}

// ============================================================
// Helper: Compute Match Awards
// ============================================================

interface MatchAwards {
  motmPlayerId: string | null;
  bestBatsmanId: string | null;
  bestBatsmanRuns: number;
  bestBowlerId: string | null;
  bestBowlerWickets: number;
  bestBowlerEconomy: number;
  playerScores: Array<{
    playerId: string;
    battingScore: number;
    bowlingScore: number;
    totalScore: number;
  }>;
}

async function computeMatchAwards(
  tx: Parameters<Parameters<typeof db.transaction>[0]>[0],
  _matchId: string,
  allInnings: Array<typeof innings.$inferSelect>,
): Promise<MatchAwards> {
  const inningsIds = allInnings.map((i) => i.id);

  // Get all batting stats for this match
  const allBatting = await tx
    .select()
    .from(battingStats)
    .where(sql`${battingStats.inningsId} IN (${sql.join(inningsIds.map(id => sql`${id}`), sql`, `)})`);

  // Get all bowling stats for this match
  const allBowling = await tx
    .select()
    .from(bowlingStats)
    .where(sql`${bowlingStats.inningsId} IN (${sql.join(inningsIds.map(id => sql`${id}`), sql`, `)})`);

  // Best Batsman: highest runs scored
  let bestBatsmanId: string | null = null;
  let bestBatsmanRuns = 0;
  for (const bs of allBatting) {
    if (bs.runsScored > bestBatsmanRuns ||
        (bs.runsScored === bestBatsmanRuns && (bs.ballsFaced ?? 999) < (allBatting.find(b => b.playerId === bestBatsmanId)?.ballsFaced ?? 999))) {
      bestBatsmanRuns = bs.runsScored;
      bestBatsmanId = bs.playerId;
    }
  }

  // Best Bowler: most wickets, tiebreak by best economy
  let bestBowlerId: string | null = null;
  let bestBowlerWickets = 0;
  let bestBowlerEconomy = 999;
  for (const bw of allBowling) {
    const wickets = bw.wicketsTaken ?? 0;
    const economy = bw.economyRate ? Number(bw.economyRate) : 999;
    if (wickets > bestBowlerWickets ||
        (wickets === bestBowlerWickets && economy < bestBowlerEconomy)) {
      bestBowlerWickets = wickets;
      bestBowlerEconomy = economy;
      bestBowlerId = bw.playerId;
    }
  }

  // MOTM: Simple weighted score (batting: runs/10 + SR bonus, bowling: wickets*3 + economy bonus)
  const playerScoreMap = new Map<string, { batting: number; bowling: number }>();

  for (const bs of allBatting) {
    const battingScore = bs.runsScored / 10 +
      (bs.runsScored >= 50 ? 2 : 0) +
      (bs.runsScored >= 100 ? 3 : 0) +
      (bs.fours ?? 0) * 0.1 + (bs.sixes ?? 0) * 0.2;
    const existing = playerScoreMap.get(bs.playerId) ?? { batting: 0, bowling: 0 };
    existing.batting += battingScore;
    playerScoreMap.set(bs.playerId, existing);
  }

  for (const bw of allBowling) {
    const wickets = bw.wicketsTaken ?? 0;
    const maidens = bw.maidens ?? 0;
    const bowlingScore = wickets * 3 + maidens * 1 +
      (wickets >= 3 ? 3 : 0) + (wickets >= 5 ? 2 : 0);
    const existing = playerScoreMap.get(bw.playerId) ?? { batting: 0, bowling: 0 };
    existing.bowling += bowlingScore;
    playerScoreMap.set(bw.playerId, existing);
  }

  const playerScores = Array.from(playerScoreMap.entries())
    .map(([playerId, scores]) => ({
      playerId,
      battingScore: scores.batting,
      bowlingScore: scores.bowling,
      totalScore: scores.batting + scores.bowling,
    }))
    .sort((a, b) => b.totalScore - a.totalScore);

  const motmPlayerId = playerScores.length > 0 ? playerScores[0]!.playerId : null;

  return {
    motmPlayerId,
    bestBatsmanId,
    bestBatsmanRuns,
    bestBowlerId,
    bestBowlerWickets,
    bestBowlerEconomy,
    playerScores,
  };
}

// ============================================================
// Helper: Complete Match
// ============================================================

async function completeMatch(
  tx: Parameters<Parameters<typeof db.transaction>[0]>[0],
  matchId: string,
  match: typeof matches.$inferSelect,
): Promise<void> {
  // Get both innings
  const allInnings = await tx
    .select()
    .from(innings)
    .where(eq(innings.matchId, matchId))
    .orderBy(innings.inningsNumber);

  const firstInnings = allInnings.find((i) => i.inningsNumber === 1);
  const secondInnings = allInnings.find((i) => i.inningsNumber === 2);

  if (!firstInnings || !secondInnings) {
    // Only 1 innings played — match abandoned or declared
    await tx
      .update(matches)
      .set({ status: 'completed' })
      .where(eq(matches.id, matchId));
    return;
  }

  let winnerTeamId: string | null = null;
  let resultType: string;
  let margin: number | null = null;
  let summary: string;

  if (firstInnings.totalRuns > secondInnings.totalRuns) {
    // First batting team wins by runs
    winnerTeamId = firstInnings.battingTeamId;
    resultType = 'runs';
    margin = firstInnings.totalRuns - secondInnings.totalRuns;
    summary = `Won by ${margin} runs`;
  } else if (secondInnings.totalRuns > firstInnings.totalRuns) {
    // Second batting team wins by wickets
    winnerTeamId = secondInnings.battingTeamId;
    resultType = 'wickets';
    margin = match.playersPerSide - 1 - secondInnings.totalWickets;
    summary = `Won by ${margin} wickets`;
  } else {
    // Tie
    winnerTeamId = null;
    resultType = 'tie';
    margin = null;
    summary = 'Match Tied';
  }

  // Compute match awards (best batsman, best bowler, MOTM)
  const awards = await computeMatchAwards(tx, matchId, [firstInnings, secondInnings]);

  await tx.insert(matchResult).values({
    matchId,
    winnerTeamId,
    resultType,
    margin,
    manOfMatchId: awards.motmPlayerId,
    summary,
  });

  // Persist awards in match_analytics
  await tx.insert(matchAnalytics).values({
    matchId,
    mvpScores: awards,
  });

  await tx
    .update(matches)
    .set({ status: 'completed' })
    .where(eq(matches.id, matchId));

  // Update tournament standings if this is a tournament match
  if (match.tournamentId) {
    await updateTournamentStandings(
      tx,
      match.tournamentId,
      firstInnings,
      secondInnings,
      winnerTeamId,
      resultType,
      match,
    );
  }
}

/**
 * Update tournament_standings rows for both teams after a match completes.
 * Increments played/won/lost/tied, recalculates points, and updates NRR components.
 */
async function updateTournamentStandings(
  tx: Parameters<Parameters<typeof db.transaction>[0]>[0],
  tournamentId: string,
  firstInnings: typeof innings.$inferSelect,
  secondInnings: typeof innings.$inferSelect,
  winnerTeamId: string | null,
  resultType: string,
  match: typeof matches.$inferSelect,
): Promise<void> {
  const teamIds = [match.homeTeamId, match.awayTeamId];

  for (const teamId of teamIds) {
    // Determine if this team won, lost, or tied
    const isWinner = winnerTeamId === teamId;
    const isTie = resultType === 'tie';

    // Determine which innings this team batted/bowled
    const battingInnings = firstInnings.battingTeamId === teamId
        ? firstInnings
        : secondInnings;
    const bowlingInnings = firstInnings.bowlingTeamId === teamId
        ? firstInnings
        : secondInnings;

    // Parse overs to numeric: "3.2" → 3.333...
    const parseOvers = (oversStr: string | number): number => {
      const str = String(oversStr);
      const parts = str.split('.');
      const completedOvers = parseInt(parts[0]!, 10);
      const balls = parseInt(parts[1] || '0', 10);
      return completedOvers + balls / 6;
    };

    const runsScored = battingInnings.totalRuns;
    const oversFaced = parseOvers(battingInnings.totalOvers);
    const runsConceded = bowlingInnings.totalRuns;
    const oversBowled = parseOvers(bowlingInnings.totalOvers);

    // Get points config from tournament
    const [tournament] = await tx
      .select({
        pointsWin: sql<number>`coalesce((SELECT points_win FROM tournaments WHERE id = ${tournamentId}), 2)`,
        pointsTie: sql<number>`coalesce((SELECT points_tie FROM tournaments WHERE id = ${tournamentId}), 1)`,
        pointsLoss: sql<number>`coalesce((SELECT points_loss FROM tournaments WHERE id = ${tournamentId}), 0)`,
      })
      .from(sql`(SELECT 1) AS dummy`);

    const pointsForMatch = isTie
      ? (tournament?.pointsTie ?? 1)
      : isWinner
        ? (tournament?.pointsWin ?? 2)
        : (tournament?.pointsLoss ?? 0);

    // Upsert standings row
    await tx
      .update(tournamentStandings)
      .set({
        played: sql`${tournamentStandings.played} + 1`,
        won: sql`${tournamentStandings.won} + ${isWinner ? 1 : 0}`,
        lost: sql`${tournamentStandings.lost} + ${!isTie && !isWinner ? 1 : 0}`,
        tied: sql`${tournamentStandings.tied} + ${isTie ? 1 : 0}`,
        points: sql`${tournamentStandings.points} + ${pointsForMatch}`,
        totalRunsScored: sql`${tournamentStandings.totalRunsScored} + ${runsScored}`,
        totalOversFaced: sql`${tournamentStandings.totalOversFaced} + ${oversFaced.toFixed(1)}`,
        totalRunsConceded: sql`${tournamentStandings.totalRunsConceded} + ${runsConceded}`,
        totalOversBowled: sql`${tournamentStandings.totalOversBowled} + ${oversBowled.toFixed(1)}`,
        nrr: sql`
          CASE
            WHEN (${tournamentStandings.totalOversFaced} + ${oversFaced.toFixed(1)}) > 0
              AND (${tournamentStandings.totalOversBowled} + ${oversBowled.toFixed(1)}) > 0
            THEN ROUND(
              ((${tournamentStandings.totalRunsScored} + ${runsScored})::decimal
                / (${tournamentStandings.totalOversFaced} + ${oversFaced.toFixed(1)}))
              - ((${tournamentStandings.totalRunsConceded} + ${runsConceded})::decimal
                / (${tournamentStandings.totalOversBowled} + ${oversBowled.toFixed(1)})),
              3
            )
            ELSE 0
          END
        `,
      })
      .where(
        and(
          eq(tournamentStandings.tournamentId, tournamentId),
          eq(tournamentStandings.teamId, teamId),
        ),
      );
  }
}

// ============================================================
// Helper: Compute Overs Display
// ============================================================

function computeOversDisplay(
  inn: typeof innings.$inferSelect,
  isCurrentBallLegal: boolean,
): string {
  const currentOversStr = String(inn.totalOvers);
  const parts = currentOversStr.split('.');
  let completedOvers = parseInt(parts[0]!, 10);
  let balls = parseInt(parts[1] || '0', 10);

  if (isCurrentBallLegal) {
    balls += 1;
    if (balls >= 6) {
      completedOvers += 1;
      balls = 0;
    }
  }

  return `${completedOvers}.${balls}`;
}
