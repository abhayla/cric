import { pgTable, uuid, integer, boolean, timestamp, decimal, index } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { users } from './users.ts';
import { innings } from './innings.ts';
import { dismissalTypes, wagonWheelZones } from './master-data.ts';

export const deliveries = pgTable('deliveries', {
  id: uuid('id').defaultRandom().primaryKey(),
  inningsId: uuid('innings_id').notNull().references(() => innings.id, { onDelete: 'cascade' }),
  overNumber: integer('over_number').notNull(),
  ballNumber: integer('ball_number').notNull(),
  sequenceNumber: integer('sequence_number').notNull(),
  strikerId: uuid('striker_id').notNull().references(() => users.id, { onDelete: 'restrict' }),
  nonStrikerId: uuid('non_striker_id').notNull().references(() => users.id, { onDelete: 'restrict' }),
  bowlerId: uuid('bowler_id').references(() => users.id, { onDelete: 'restrict' }),
  runsFromBat: integer('runs_from_bat').default(0).notNull(),
  isWide: boolean('is_wide').default(false).notNull(),
  wideRuns: integer('wide_runs').default(0).notNull(),
  isNoBall: boolean('is_no_ball').default(false).notNull(),
  noBallRuns: integer('no_ball_runs').default(0).notNull(),
  isBye: boolean('is_bye').default(false).notNull(),
  byeRuns: integer('bye_runs').default(0).notNull(),
  isLegBye: boolean('is_leg_bye').default(false).notNull(),
  legByeRuns: integer('leg_bye_runs').default(0).notNull(),
  totalRuns: integer('total_runs').default(0).notNull(),
  isWicket: boolean('is_wicket').default(false).notNull(),
  isLegal: boolean('is_legal').default(true).notNull(),
  isBoundaryFour: boolean('is_boundary_four').default(false).notNull(),
  isBoundarySix: boolean('is_boundary_six').default(false).notNull(),
  isFreeHit: boolean('is_free_hit').default(false).notNull(),
  isPenalty: boolean('is_penalty').default(false).notNull(),
  wagonWheelZoneId: integer('wagon_wheel_zone_id').references(() => wagonWheelZones.id, { onDelete: 'set null' }),
  timestamp: timestamp('timestamp', { mode: 'date' }).defaultNow().notNull(),
  synced: boolean('synced').default(false).notNull(),
  createdAt: timestamp('created_at', { mode: 'date' }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { mode: 'date' }).defaultNow().notNull().$onUpdate(() => new Date()),
}, (table) => [
  index('idx_deliveries_innings').on(table.inningsId),
  index('idx_deliveries_bowler').on(table.bowlerId),
  index('idx_deliveries_striker').on(table.strikerId),
  index('idx_deliveries_over').on(table.inningsId, table.overNumber),
  index('idx_deliveries_synced').on(table.synced).where(sql`synced = false`),
  index('idx_deliveries_sequence').on(table.inningsId, table.sequenceNumber),
]);

export const wicketsByDelivery = pgTable('wickets_by_delivery', {
  id: uuid('id').defaultRandom().primaryKey(),
  deliveryId: uuid('delivery_id').notNull().references(() => deliveries.id, { onDelete: 'cascade' }),
  dismissedPlayerId: uuid('dismissed_player_id').notNull().references(() => users.id, { onDelete: 'restrict' }),
  dismissalTypeId: integer('dismissal_type_id').notNull().references(() => dismissalTypes.id, { onDelete: 'restrict' }),
  fielderId: uuid('fielder_id').references(() => users.id, { onDelete: 'set null' }),
  bowlerCredited: boolean('bowler_credited').notNull(),
  createdAt: timestamp('created_at', { mode: 'date' }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { mode: 'date' }).defaultNow().notNull().$onUpdate(() => new Date()),
}, (table) => [
  index('idx_wickets_delivery').on(table.deliveryId),
  index('idx_wickets_dismissed_player').on(table.dismissedPlayerId),
]);

export const fallOfWickets = pgTable('fall_of_wickets', {
  id: uuid('id').defaultRandom().primaryKey(),
  inningsId: uuid('innings_id').notNull().references(() => innings.id, { onDelete: 'cascade' }),
  wicketNumber: integer('wicket_number').notNull(),
  runsAtFall: integer('runs_at_fall').notNull(),
  oversAtFall: decimal('overs_at_fall', { precision: 5, scale: 1 }).notNull(),
  dismissedPlayerId: uuid('dismissed_player_id').notNull().references(() => users.id, { onDelete: 'restrict' }),
  deliveryId: uuid('delivery_id').notNull().references(() => deliveries.id, { onDelete: 'cascade' }),
  createdAt: timestamp('created_at', { mode: 'date' }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { mode: 'date' }).defaultNow().notNull().$onUpdate(() => new Date()),
});
