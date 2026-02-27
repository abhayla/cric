import { pgTable, uuid, varchar, integer, boolean, decimal, timestamp, index, unique } from 'drizzle-orm/pg-core';
import { users } from './users.ts';
import { innings } from './innings.ts';
import { dismissalTypes } from './master-data.ts';

export const battingStats = pgTable('batting_stats', {
  id: uuid('id').defaultRandom().primaryKey(),
  inningsId: uuid('innings_id').notNull().references(() => innings.id, { onDelete: 'cascade' }),
  playerId: uuid('player_id').notNull().references(() => users.id, { onDelete: 'restrict' }),
  battingPosition: integer('batting_position').notNull(),
  runsScored: integer('runs_scored').default(0).notNull(),
  ballsFaced: integer('balls_faced').default(0).notNull(),
  fours: integer('fours').default(0).notNull(),
  sixes: integer('sixes').default(0).notNull(),
  strikeRate: decimal('strike_rate', { precision: 6, scale: 2 }),
  isNotOut: boolean('is_not_out').default(true).notNull(),
  dismissalTypeId: integer('dismissal_type_id').references(() => dismissalTypes.id, { onDelete: 'set null' }),
  dismissedById: uuid('dismissed_by_id').references(() => users.id, { onDelete: 'set null' }),
  fielderId: uuid('fielder_id').references(() => users.id, { onDelete: 'set null' }),
  isRetiredHurt: boolean('is_retired_hurt').default(false).notNull(),
  minutesBatted: integer('minutes_batted'),
  createdAt: timestamp('created_at', { mode: 'date' }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { mode: 'date' }).defaultNow().notNull().$onUpdate(() => new Date()),
}, (table) => [
  index('idx_batting_stats_innings').on(table.inningsId),
  index('idx_batting_stats_player').on(table.playerId),
  unique('uq_batting_stats_innings_player').on(table.inningsId, table.playerId),
]);

export const bowlingStats = pgTable('bowling_stats', {
  id: uuid('id').defaultRandom().primaryKey(),
  inningsId: uuid('innings_id').notNull().references(() => innings.id, { onDelete: 'cascade' }),
  playerId: uuid('player_id').notNull().references(() => users.id, { onDelete: 'restrict' }),
  oversBowled: decimal('overs_bowled', { precision: 4, scale: 1 }).default('0.0').notNull(),
  maidens: integer('maidens').default(0).notNull(),
  runsConceded: integer('runs_conceded').default(0).notNull(),
  wicketsTaken: integer('wickets_taken').default(0).notNull(),
  economyRate: decimal('economy_rate', { precision: 5, scale: 2 }),
  wides: integer('wides').default(0).notNull(),
  noBalls: integer('no_balls').default(0).notNull(),
  dotBalls: integer('dot_balls').default(0).notNull(),
  foursConceded: integer('fours_conceded').default(0).notNull(),
  sixesConceded: integer('sixes_conceded').default(0).notNull(),
  createdAt: timestamp('created_at', { mode: 'date' }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { mode: 'date' }).defaultNow().notNull().$onUpdate(() => new Date()),
}, (table) => [
  index('idx_bowling_stats_innings').on(table.inningsId),
  index('idx_bowling_stats_player').on(table.playerId),
  unique('uq_bowling_stats_innings_player').on(table.inningsId, table.playerId),
]);

export const fieldingStats = pgTable('fielding_stats', {
  id: uuid('id').defaultRandom().primaryKey(),
  inningsId: uuid('innings_id').notNull().references(() => innings.id, { onDelete: 'cascade' }),
  playerId: uuid('player_id').notNull().references(() => users.id, { onDelete: 'restrict' }),
  catches: integer('catches').default(0).notNull(),
  runOuts: integer('run_outs').default(0).notNull(),
  stumpings: integer('stumpings').default(0).notNull(),
  directHits: integer('direct_hits').default(0).notNull(),
  createdAt: timestamp('created_at', { mode: 'date' }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { mode: 'date' }).defaultNow().notNull().$onUpdate(() => new Date()),
}, (table) => [
  index('idx_fielding_stats_innings').on(table.inningsId),
  index('idx_fielding_stats_player').on(table.playerId),
  unique('uq_fielding_stats_innings_player').on(table.inningsId, table.playerId),
]);

export const playerCareerStats = pgTable('player_career_stats', {
  id: uuid('id').defaultRandom().primaryKey(),
  playerId: uuid('player_id').notNull().references(() => users.id, { onDelete: 'restrict' }),
  format: varchar('format', { length: 20 }).notNull(),
  matchesPlayed: integer('matches_played').default(0).notNull(),
  inningsBatted: integer('innings_batted').default(0).notNull(),
  totalRuns: integer('total_runs').default(0).notNull(),
  highestScore: integer('highest_score').default(0).notNull(),
  battingAverage: decimal('batting_average', { precision: 6, scale: 2 }),
  battingStrikeRate: decimal('batting_strike_rate', { precision: 6, scale: 2 }),
  fifties: integer('fifties').default(0).notNull(),
  hundreds: integer('hundreds').default(0).notNull(),
  fours: integer('fours').default(0).notNull(),
  sixes: integer('sixes').default(0).notNull(),
  notOuts: integer('not_outs').default(0).notNull(),
  inningsBowled: integer('innings_bowled').default(0).notNull(),
  oversBowled: decimal('overs_bowled', { precision: 6, scale: 1 }),
  runsConceded: integer('runs_conceded').default(0).notNull(),
  wicketsTaken: integer('wickets_taken').default(0).notNull(),
  bowlingAverage: decimal('bowling_average', { precision: 6, scale: 2 }),
  bowlingEconomy: decimal('bowling_economy', { precision: 5, scale: 2 }),
  bowlingStrikeRate: decimal('bowling_strike_rate', { precision: 6, scale: 2 }),
  bestBowlingWickets: integer('best_bowling_wickets').default(0).notNull(),
  bestBowlingRuns: integer('best_bowling_runs').default(0).notNull(),
  threeWicketHauls: integer('three_wicket_hauls').default(0).notNull(),
  fiveWicketHauls: integer('five_wicket_hauls').default(0).notNull(),
  catches: integer('catches').default(0).notNull(),
  runOuts: integer('run_outs').default(0).notNull(),
  stumpings: integer('stumpings').default(0).notNull(),
  ducks: integer('ducks').default(0).notNull(),
  directHits: integer('direct_hits').default(0).notNull(),
  updatedAt: timestamp('updated_at', { mode: 'date' }).defaultNow().notNull().$onUpdate(() => new Date()),
}, (table) => [
  index('idx_career_stats_player').on(table.playerId, table.format),
  unique('uq_career_stats_player_format').on(table.playerId, table.format),
]);
