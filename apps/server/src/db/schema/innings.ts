import { pgTable, uuid, varchar, integer, boolean, decimal, timestamp, unique } from 'drizzle-orm/pg-core';
import { users } from './users.ts';
import { teams } from './teams.ts';
import { matches } from './matches.ts';

export const innings = pgTable('innings', {
  id: uuid('id').defaultRandom().primaryKey(),
  matchId: uuid('match_id').notNull().references(() => matches.id, { onDelete: 'cascade' }),
  inningsNumber: integer('innings_number').notNull(),
  battingTeamId: uuid('batting_team_id').notNull().references(() => teams.id, { onDelete: 'restrict' }),
  bowlingTeamId: uuid('bowling_team_id').notNull().references(() => teams.id, { onDelete: 'restrict' }),
  totalRuns: integer('total_runs').default(0).notNull(),
  totalWickets: integer('total_wickets').default(0).notNull(),
  totalOvers: decimal('total_overs', { precision: 5, scale: 1 }).default('0.0').notNull(),
  totalExtras: integer('total_extras').default(0).notNull(),
  totalWides: integer('total_wides').default(0).notNull(),
  totalNoBalls: integer('total_no_balls').default(0).notNull(),
  totalByes: integer('total_byes').default(0).notNull(),
  totalLegByes: integer('total_leg_byes').default(0).notNull(),
  isSuperOver: boolean('is_super_over').default(false).notNull(),
  superOverNumber: integer('super_over_number'),
  isCompleted: boolean('is_completed').default(false).notNull(),
  completedReason: varchar('completed_reason', { length: 30 }),
  target: integer('target'),
  penaltyRuns: integer('penalty_runs').default(0).notNull(),
  runRate: decimal('run_rate', { precision: 5, scale: 2 }),
  dotBallPercentage: decimal('dot_ball_percentage', { precision: 5, scale: 2 }),
  boundaryPercentage: decimal('boundary_percentage', { precision: 5, scale: 2 }),
  createdAt: timestamp('created_at', { mode: 'date' }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { mode: 'date' }).defaultNow().notNull().$onUpdate(() => new Date()),
});

export const overs = pgTable('overs', {
  id: uuid('id').defaultRandom().primaryKey(),
  inningsId: uuid('innings_id').notNull().references(() => innings.id, { onDelete: 'cascade' }),
  overNumber: integer('over_number').notNull(),
  bowlerId: uuid('bowler_id').notNull().references(() => users.id, { onDelete: 'restrict' }),
  runsConceded: integer('runs_conceded').default(0).notNull(),
  wicketsTaken: integer('wickets_taken').default(0).notNull(),
  wides: integer('wides').default(0).notNull(),
  noBalls: integer('no_balls').default(0).notNull(),
  isMaiden: boolean('is_maiden').default(false).notNull(),
  isCompleted: boolean('is_completed').default(false).notNull(),
  createdAt: timestamp('created_at', { mode: 'date' }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { mode: 'date' }).defaultNow().notNull().$onUpdate(() => new Date()),
}, (table) => [
  unique('uq_overs_innings_over').on(table.inningsId, table.overNumber),
]);
