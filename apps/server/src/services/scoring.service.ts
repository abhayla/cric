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
// Cricket Overs Arithmetic Helpers
// ============================================================

/** Decrement cricket overs decimal by 1 ball: "2.3" → "2.2", "3.0" → "2.5" */
function decrementOvers(currentOvers: string): string {
  const parts = String(currentOvers).split('.');
  let completedOvers = parseInt(parts[0]!, 10);
  let balls = parseInt(parts[1] || '0', 10);
  balls -= 1;
  if (balls < 0) {
    completedOvers -= 1;
    balls = 5;
  }
  if (completedOvers < 0) return '0.0';
  return `${completedOvers}.${balls}`;
}

// ============================================================
// Types
// ============================================================

export interface DeliveryInput {
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

export interface DeliveryResult {
  delivery: typeof deliveries.$inferSelect;
  inningsComplete: boolean;
  matchComplete: boolean;
  updatedInnings?: typeof innings.$inferSelect;
}

// ============================================================
// Record Delivery — 10-step pipeline
// ============================================================

// Transaction handle type used by helper functions
type TxHandle = Parameters<Parameters<typeof db.transaction>[0]>[0];

/**
 * Core delivery recording logic, designed to run inside an existing transaction.
 * Used by both single `recordDelivery()` and batch `recordDeliveryBatch()`.
 *
 * @param tx - Drizzle transaction handle
 * @param matchId - Match UUID
 * @param txMatch - Pre-fetched match row (read once per transaction, not per delivery)
 * @param inningsCache - Shared cache mapping inningsNumber → innings row. Checked before DB query, updated after mutations.
 * @param input - Delivery input data
 */
export async function recordDeliveryInTx(
  tx: TxHandle,
  matchId: string,
  txMatch: typeof matches.$inferSelect,
  inningsCache: Map<number, typeof innings.$inferSelect>,
  input: DeliveryInput,
  precomputed?: { sequenceNumber?: number; isFreeHit?: boolean },
): Promise<DeliveryResult> {
  // ── Step 1: VALIDATE (within transaction) ──
  // Resolve innings: by ID or by innings number
  let resolvedInningsId = input.inningsId;
  let inn: typeof innings.$inferSelect | undefined;

  if (!resolvedInningsId && input.inningsNumber) {
    // Check cache first
    const cached = inningsCache.get(input.inningsNumber);
    if (cached && cached.matchId === matchId) {
      resolvedInningsId = cached.id;
      inn = cached;
    } else {
      const [innByNumber] = await tx
        .select()
        .from(innings)
        .where(and(eq(innings.matchId, matchId), eq(innings.inningsNumber, input.inningsNumber)))
        .limit(1);
      if (!innByNumber) {
        throw new AppError('NOT_FOUND', `Innings #${input.inningsNumber} not found for this match`, 404);
      }
      resolvedInningsId = innByNumber.id;
      inn = innByNumber;
      inningsCache.set(innByNumber.inningsNumber, innByNumber);
    }
  }

  if (!resolvedInningsId) {
    throw new AppError('VALIDATION_ERROR', 'Either inningsId or inningsNumber is required', 400);
  }

  // Validate innings exists and belongs to match (if not already resolved from cache)
  if (!inn) {
    const [innRow] = await tx
      .select()
      .from(innings)
      .where(and(eq(innings.id, resolvedInningsId), eq(innings.matchId, matchId)))
      .limit(1);

    if (!innRow) {
      throw new AppError('NOT_FOUND', 'Innings not found for this match', 404);
    }
    inn = innRow;
    inningsCache.set(innRow.inningsNumber, innRow);
  }

  if (inn.isCompleted) {
    throw new AppError('VALIDATION_ERROR', 'Cannot record delivery in a completed innings', 400);
  }

  // If match is in innings_break and we're recording in the 2nd innings, transition to live
  if (txMatch.status === 'innings_break' && inn.inningsNumber >= 2) {
    await tx
      .update(matches)
      .set({ status: 'live' })
      .where(eq(matches.id, matchId));
  }

  // ── Step 2: CALCULATE ──
  const isLegal = !input.isWide && !input.isNoBall && !input.isPenalty;

  // Step 2.5: Magic Over — configurable multiplier
  const magicOverNumbers = txMatch.magicOverNumbers as number[] | null;
  const isMagicOver = magicOverNumbers != null && magicOverNumbers.includes(input.overNumber);
  const multiplier = isMagicOver ? txMatch.magicOverRunMultiplier : 1;

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
  const magicOverPenalty = isMagicOver && input.isWicket ? txMatch.magicOverWicketPenalty : 0;
  const totalRuns = effectiveRunsFromBat + effectiveWideRuns + effectiveNoBallRuns + effectiveByeRuns + effectiveLegByeRuns + magicOverPenalty;

  // Get next sequence number (skip DB query if precomputed by batch caller)
  let sequenceNumber: number;
  if (precomputed?.sequenceNumber != null) {
    sequenceNumber = precomputed.sequenceNumber;
  } else {
    const [seqResult] = await tx
      .select({ maxSeq: max(deliveries.sequenceNumber) })
      .from(deliveries)
      .where(eq(deliveries.inningsId, resolvedInningsId!));
    sequenceNumber = (seqResult?.maxSeq ?? 0) + 1;
  }

  // Determine isFreeHit from previous delivery (skip DB query if precomputed by batch caller)
  let isFreeHit = false;
  if (precomputed?.isFreeHit != null) {
    isFreeHit = precomputed.isFreeHit;
  } else if (sequenceNumber > 1) {
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

  const [updatedInnings] = await tx
    .update(innings)
    .set(inningsUpdate)
    .where(eq(innings.id, resolvedInningsId!))
    .returning();

  // ── Step 8: CHECK OVER COMPLETION ──
  if (isLegal) {
    await checkOverCompletion(tx, resolvedInningsId!, input.overNumber, input.bowlerId);
  }

  // ── Step 9: CHECK INNINGS COMPLETION ──

  // Update the cache with fresh innings data
  inningsCache.set(updatedInnings!.inningsNumber, updatedInnings!);

  const { inningsComplete, matchComplete, completedReason } = checkInningsCompletion(
    updatedInnings!,
    txMatch,
  );

  if (inningsComplete && completedReason) {
    await tx
      .update(innings)
      .set({
        isCompleted: true,
        completedReason,
      })
      .where(eq(innings.id, resolvedInningsId!));

    // Update cache to reflect completion
    inningsCache.set(updatedInnings!.inningsNumber, {
      ...updatedInnings!,
      isCompleted: true,
      completedReason,
    });

    // Handle match state transition
    if (matchComplete) {
      await completeMatch(tx, matchId, txMatch);
    } else if (updatedInnings!.inningsNumber === 1) {
      // Transition to innings_break
      await tx
        .update(matches)
        .set({ status: 'innings_break' })
        .where(eq(matches.id, matchId));

      // Auto-create 2nd innings with teams swapped (skip if already exists, e.g. batch pre-created it)
      if (!inningsCache.has(2)) {
        const target = updatedInnings!.totalRuns + 1;
        const [newInnings] = await tx.insert(innings).values({
          matchId,
          inningsNumber: 2,
          battingTeamId: updatedInnings!.bowlingTeamId,
          bowlingTeamId: updatedInnings!.battingTeamId,
          target,
        }).returning();

        if (newInnings) {
          inningsCache.set(2, newInnings);
        }
      } else {
        // Update cached innings 2 with target from completed innings 1
        const cachedInn2 = inningsCache.get(2)!;
        const target = updatedInnings!.totalRuns + 1;
        if (cachedInn2.target !== target) {
          await tx
            .update(innings)
            .set({ target })
            .where(eq(innings.id, cachedInn2.id));
          inningsCache.set(2, { ...cachedInn2, target });
        }
      }
    }
  }

  // ── Step 10: RETURN ──
  return {
    delivery: delivery!,
    inningsComplete,
    matchComplete,
    updatedInnings: updatedInnings!,
  };
}

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

  const result = await db.transaction(async (tx) => {
    // Re-read match inside tx for consistency (once per transaction)
    const [txMatch] = await tx
      .select()
      .from(matches)
      .where(eq(matches.id, matchId))
      .limit(1);

    if (!txMatch || (txMatch.status !== 'live' && txMatch.status !== 'innings_break')) {
      throw new AppError('VALIDATION_ERROR', 'Match must be in live status to record deliveries', 400);
    }

    // Load existing innings into cache
    const inningsCache = new Map<number, typeof innings.$inferSelect>();
    const existingInnings = await tx
      .select()
      .from(innings)
      .where(eq(innings.matchId, matchId));

    for (const inn of existingInnings) {
      inningsCache.set(inn.inningsNumber, inn);
    }

    // Pre-create missing innings (same logic as batch endpoint)
    if (input.inningsNumber && input.inningsNumber > 1 && !inningsCache.has(input.inningsNumber)) {
      const inn1 = inningsCache.get(1);
      if (!inn1) {
        throw new AppError('VALIDATION_ERROR', 'Cannot create innings 2 — innings 1 not found', 400);
      }

      const target = inn1.isCompleted ? inn1.totalRuns + 1 : null;
      const [newInnings] = await tx.insert(innings).values({
        matchId,
        inningsNumber: input.inningsNumber,
        battingTeamId: inn1.bowlingTeamId,
        bowlingTeamId: inn1.battingTeamId,
        target,
      }).returning();

      if (newInnings) {
        inningsCache.set(input.inningsNumber, newInnings);
      }

      // If match was in innings_break, transition to live
      if (txMatch.status === 'innings_break') {
        await tx
          .update(matches)
          .set({ status: 'live' })
          .where(eq(matches.id, matchId));
      }
    }

    return recordDeliveryInTx(tx, matchId, txMatch, inningsCache, input);
  });

  if (result.matchComplete) {
    try {
      await db.transaction(async (tx) => {
        await refreshMatchPlayerCareerStats(tx, matchId);
      });
    } catch (err) {
      console.error(`[Scoring] Career stats refresh failed for match=${matchId}:`, err);
    }
  }

  return result;
}

// ============================================================
// Record Delivery Batch
// ============================================================

export interface BatchDeliveryInput {
  deliveries: DeliveryInput[];
}

export interface BatchDeliveryResult {
  processed: number;
  skipped: number;
  inningsComplete: boolean;
  matchComplete: boolean;
}

export async function recordDeliveryBatch(
  matchId: string,
  userId: string,
  input: BatchDeliveryInput,
): Promise<BatchDeliveryResult> {
  if (input.deliveries.length === 0) {
    return { processed: 0, skipped: 0, inningsComplete: false, matchComplete: false };
  }

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

  // Sort deliveries defensively: by inningsNumber → overNumber → ballNumber
  const sorted = [...input.deliveries].sort((a, b) => {
    const innDiff = (a.inningsNumber ?? 0) - (b.inningsNumber ?? 0);
    if (innDiff !== 0) return innDiff;
    const overDiff = a.overNumber - b.overNumber;
    if (overDiff !== 0) return overDiff;
    return a.ballNumber - b.ballNumber;
  });

  const result = await db.transaction(async (tx) => {
    // Re-read match inside tx (once for the whole batch)
    const [txMatch] = await tx
      .select()
      .from(matches)
      .where(eq(matches.id, matchId))
      .limit(1);

    if (!txMatch || (txMatch.status !== 'live' && txMatch.status !== 'innings_break')) {
      throw new AppError('VALIDATION_ERROR', 'Match must be in live status to record deliveries', 400);
    }

    // Pre-create missing innings: scan batch for unique inningsNumbers
    const uniqueInningsNumbers = [...new Set(
      sorted.map(d => d.inningsNumber).filter((n): n is number => n != null),
    )].sort((a, b) => a - b);

    // Load all existing innings for this match into cache
    const inningsCache = new Map<number, typeof innings.$inferSelect>();
    const existingInnings = await tx
      .select()
      .from(innings)
      .where(eq(innings.matchId, matchId));

    for (const inn of existingInnings) {
      inningsCache.set(inn.inningsNumber, inn);
    }

    // Pre-create missing innings (innings 2+ only)
    for (const inningsNum of uniqueInningsNumbers) {
      if (inningsCache.has(inningsNum)) continue;

      if (inningsNum === 1) {
        throw new AppError('VALIDATION_ERROR', 'Innings 1 must already exist (created at toss)', 400);
      }

      // Auto-create innings 2+ by swapping teams from innings 1
      const inn1 = inningsCache.get(1);
      if (!inn1) {
        throw new AppError('VALIDATION_ERROR', 'Cannot create innings 2 — innings 1 not found', 400);
      }

      const target = inn1.isCompleted ? inn1.totalRuns + 1 : null;
      const [newInnings] = await tx.insert(innings).values({
        matchId,
        inningsNumber: inningsNum,
        battingTeamId: inn1.bowlingTeamId,
        bowlingTeamId: inn1.battingTeamId,
        target,
      }).returning();

      if (newInnings) {
        inningsCache.set(inningsNum, newInnings);
      }

      // If match was in innings_break, transition to live
      if (txMatch.status === 'innings_break') {
        await tx
          .update(matches)
          .set({ status: 'live' })
          .where(eq(matches.id, matchId));
      }
    }

    // ── Precompute sequence numbers and free-hit state per innings ──
    // Query MAX(sequence_number) ONCE per unique innings in the batch
    const sequenceCounters = new Map<string, number>();
    const freeHitByInnings = new Map<string, boolean>();

    for (const inningsNum of uniqueInningsNumbers) {
      const inn = inningsCache.get(inningsNum);
      if (!inn) continue;

      const [seqResult] = await tx
        .select({ maxSeq: max(deliveries.sequenceNumber) })
        .from(deliveries)
        .where(eq(deliveries.inningsId, inn.id));

      sequenceCounters.set(inn.id, (seqResult?.maxSeq ?? 0) + 1);

      // Get last delivery's state for initial free-hit determination
      const lastSeq = seqResult?.maxSeq ?? 0;
      if (lastSeq > 0) {
        const [prevDelivery] = await tx
          .select({
            isNoBall: deliveries.isNoBall,
            isFreeHit: deliveries.isFreeHit,
            isLegal: deliveries.isLegal,
          })
          .from(deliveries)
          .where(eq(deliveries.inningsId, inn.id))
          .orderBy(desc(deliveries.sequenceNumber))
          .limit(1);

        if (prevDelivery) {
          if (prevDelivery.isNoBall) {
            freeHitByInnings.set(inn.id, true);
          } else if (prevDelivery.isFreeHit && !prevDelivery.isLegal) {
            freeHitByInnings.set(inn.id, true);
          } else {
            freeHitByInnings.set(inn.id, false);
          }
        } else {
          freeHitByInnings.set(inn.id, false);
        }
      } else {
        freeHitByInnings.set(inn.id, false);
      }
    }

    // Process deliveries sequentially
    let processed = 0;
    let skipped = 0;
    let batchInningsComplete = false;
    let batchMatchComplete = false;

    for (const delivery of sorted) {
      // Stop if match already completed mid-batch
      if (batchMatchComplete) break;

      // Idempotent check: skip if UUID already exists
      if (delivery.id) {
        const [existing] = await tx
          .select({ id: deliveries.id })
          .from(deliveries)
          .where(eq(deliveries.id, delivery.id))
          .limit(1);
        if (existing) {
          skipped++;
          continue;
        }
      }

      // Resolve innings ID for precomputed lookups
      let deliveryInningsId: string | undefined;
      if (delivery.inningsId) {
        deliveryInningsId = delivery.inningsId;
      } else if (delivery.inningsNumber) {
        deliveryInningsId = inningsCache.get(delivery.inningsNumber)?.id;
      }

      // Build precomputed values if we have them for this innings
      const precomputed = deliveryInningsId && sequenceCounters.has(deliveryInningsId)
        ? {
            sequenceNumber: sequenceCounters.get(deliveryInningsId)!,
            isFreeHit: freeHitByInnings.get(deliveryInningsId) ?? false,
          }
        : undefined;

      const result = await recordDeliveryInTx(tx, matchId, txMatch, inningsCache, delivery, precomputed);
      processed++;

      // Update precomputed counters for next delivery in this innings
      if (deliveryInningsId && precomputed) {
        sequenceCounters.set(deliveryInningsId, precomputed.sequenceNumber + 1);

        // Update free-hit state: NB triggers free-hit, free-hit persists through illegals
        const currentFreeHit = freeHitByInnings.get(deliveryInningsId) ?? false;
        const isLegal = !delivery.isWide && !delivery.isNoBall;
        const nextFreeHit = delivery.isNoBall || (currentFreeHit && !isLegal);
        freeHitByInnings.set(deliveryInningsId, nextFreeHit);
      }

      if (result.inningsComplete) batchInningsComplete = true;
      if (result.matchComplete) batchMatchComplete = true;
    }

    return {
      processed,
      skipped,
      inningsComplete: batchInningsComplete,
      matchComplete: batchMatchComplete,
    };
  });

  if (result.matchComplete) {
    try {
      await db.transaction(async (tx) => {
        await refreshMatchPlayerCareerStats(tx, matchId);
      });
    } catch (err) {
      console.error(`[Scoring] Career stats refresh failed for match=${matchId}:`, err);
    }
  }

  return result;
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

        // Reverse overs bowled for legal deliveries
        if (delivery.isLegal) {
          bowlerUpdates.oversBowled = decrementOvers(String(bowlerStat.oversBowled));
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

  // Build ON CONFLICT SET clause for striker
  const strikerConflictSet: Record<string, unknown> = {};

  if (!input.isWide) {
    strikerConflictSet.runsScored = sql`${battingStats.runsScored} + ${input.runsFromBat}`;
    if (delivery.isLegal) {
      strikerConflictSet.ballsFaced = sql`${battingStats.ballsFaced} + 1`;
    }
    if (input.isBoundaryFour) {
      strikerConflictSet.fours = sql`${battingStats.fours} + 1`;
    }
    if (input.isBoundarySix) {
      strikerConflictSet.sixes = sql`${battingStats.sixes} + 1`;
    }
  }

  const isStrikerDismissed = input.isWicket && input.wicket?.dismissedPlayerId === input.strikerId;
  if (isStrikerDismissed && input.wicket) {
    strikerConflictSet.isNotOut = false;
    strikerConflictSet.dismissalTypeId = input.wicket.dismissalTypeId;
    if (input.wicket.bowlerCredited) {
      strikerConflictSet.dismissedById = input.bowlerId;
    }
    if (input.wicket.fielderId) {
      strikerConflictSet.fielderId = input.wicket.fielderId;
    }
  }

  // Batting position for new inserts: use subquery for next available position
  const nextBattingPosition = sql<number>`(SELECT COALESCE(MAX(${battingStats.battingPosition}), 0) + 1 FROM ${battingStats} WHERE ${battingStats.inningsId} = ${inningsId})`;

  if (Object.keys(strikerConflictSet).length > 0) {
    await tx.insert(battingStats).values({
      inningsId,
      playerId: input.strikerId,
      battingPosition: nextBattingPosition as unknown as number,
      runsScored: input.isWide ? 0 : input.runsFromBat,
      ballsFaced: (!input.isWide && delivery.isLegal) ? 1 : 0,
      fours: input.isBoundaryFour ? 1 : 0,
      sixes: input.isBoundarySix ? 1 : 0,
      isNotOut: !isStrikerDismissed,
      dismissalTypeId: (isStrikerDismissed && input.wicket) ? input.wicket.dismissalTypeId : null,
      dismissedById: (isStrikerDismissed && input.wicket?.bowlerCredited) ? input.bowlerId : null,
      fielderId: (isStrikerDismissed && input.wicket?.fielderId) ? input.wicket.fielderId : null,
    }).onConflictDoUpdate({
      target: [battingStats.inningsId, battingStats.playerId],
      set: strikerConflictSet,
    });
  } else {
    // Wide with no wicket on striker — just ensure row exists
    await tx.insert(battingStats).values({
      inningsId,
      playerId: input.strikerId,
      battingPosition: nextBattingPosition as unknown as number,
      runsScored: 0,
      ballsFaced: 0,
      fours: 0,
      sixes: 0,
      isNotOut: true,
    }).onConflictDoNothing({
      target: [battingStats.inningsId, battingStats.playerId],
    });
  }

  // Non-striker: ensure row exists (INSERT...ON CONFLICT DO NOTHING)
  await tx.insert(battingStats).values({
    inningsId,
    playerId: input.nonStrikerId,
    battingPosition: nextBattingPosition as unknown as number,
    runsScored: 0,
    ballsFaced: 0,
    fours: 0,
    sixes: 0,
    isNotOut: true,
  }).onConflictDoNothing({
    target: [battingStats.inningsId, battingStats.playerId],
  });
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

  // Build ON CONFLICT SET clause
  const conflictSet: Record<string, unknown> = {
    runsConceded: sql`${bowlingStats.runsConceded} + ${runsConcededByBowler}`,
  };

  if (input.isWide) {
    conflictSet.wides = sql`${bowlingStats.wides} + 1`;
  }
  if (input.isNoBall) {
    conflictSet.noBalls = sql`${bowlingStats.noBalls} + 1`;
  }
  if (delivery.totalRuns === 0 && delivery.isLegal) {
    conflictSet.dotBalls = sql`${bowlingStats.dotBalls} + 1`;
  }
  if (input.isBoundaryFour) {
    conflictSet.foursConceded = sql`${bowlingStats.foursConceded} + 1`;
  }
  if (input.isBoundarySix) {
    conflictSet.sixesConceded = sql`${bowlingStats.sixesConceded} + 1`;
  }
  if (input.isWicket && input.wicket?.bowlerCredited) {
    conflictSet.wicketsTaken = sql`${bowlingStats.wicketsTaken} + 1`;
  }

  // Cricket overs math via SQL CASE: 0.5 → 1.0, otherwise increment tenths digit
  if (delivery.isLegal) {
    conflictSet.oversBowled = sql`CASE
      WHEN (${bowlingStats.oversBowled}::numeric * 10) % 10 >= 5
      THEN ((${bowlingStats.oversBowled}::numeric)::int + 1)::decimal(4,1)
      ELSE (${bowlingStats.oversBowled}::numeric + 0.1)::decimal(4,1)
    END`;
  }

  await tx.insert(bowlingStats).values({
    inningsId,
    playerId: input.bowlerId,
    oversBowled: delivery.isLegal ? '0.1' : '0.0',
    runsConceded: runsConcededByBowler,
    wides: input.isWide ? 1 : 0,
    noBalls: input.isNoBall ? 1 : 0,
    dotBalls: (delivery.totalRuns === 0 && delivery.isLegal) ? 1 : 0,
    foursConceded: input.isBoundaryFour ? 1 : 0,
    sixesConceded: input.isBoundarySix ? 1 : 0,
    wicketsTaken: (input.isWicket && input.wicket?.bowlerCredited) ? 1 : 0,
  }).onConflictDoUpdate({
    target: [bowlingStats.inningsId, bowlingStats.playerId],
    set: conflictSet,
  });
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

  const fieldName = dt?.name;
  const isCatch = fieldName === 'caught' || fieldName === 'caught_and_bowled';
  const isRunOut = fieldName === 'run_out';
  const isStumping = fieldName === 'stumped';

  // Build ON CONFLICT SET clause
  const conflictSet: Record<string, unknown> = {};
  if (isCatch) {
    conflictSet.catches = sql`${fieldingStats.catches} + 1`;
  }
  if (isRunOut) {
    conflictSet.runOuts = sql`${fieldingStats.runOuts} + 1`;
  }
  if (isStumping) {
    conflictSet.stumpings = sql`${fieldingStats.stumpings} + 1`;
  }

  if (Object.keys(conflictSet).length > 0) {
    await tx.insert(fieldingStats).values({
      inningsId,
      playerId: wicket.fielderId,
      catches: isCatch ? 1 : 0,
      runOuts: isRunOut ? 1 : 0,
      stumpings: isStumping ? 1 : 0,
      directHits: 0,
    }).onConflictDoUpdate({
      target: [fieldingStats.inningsId, fieldingStats.playerId],
      set: conflictSet,
    });
  } else {
    await tx.insert(fieldingStats).values({
      inningsId,
      playerId: wicket.fielderId,
      catches: 0,
      runOuts: 0,
      stumpings: 0,
      directHits: 0,
    }).onConflictDoNothing({
      target: [fieldingStats.inningsId, fieldingStats.playerId],
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
