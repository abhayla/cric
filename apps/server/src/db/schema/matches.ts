import { pgTable, uuid, varchar, text, integer, boolean, timestamp, date, jsonb, unique, index } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { users } from './users.ts';
import { teams } from './teams.ts';
import { ballTypes } from './master-data.ts';

export const matches = pgTable('matches', {
  id: uuid('id').defaultRandom().primaryKey(),
  homeTeamId: uuid('home_team_id').notNull().references(() => teams.id, { onDelete: 'restrict' }),
  awayTeamId: uuid('away_team_id').notNull().references(() => teams.id, { onDelete: 'restrict' }),
  tournamentId: uuid('tournament_id'),
  format: varchar('format', { length: 20 }).notNull(),
  totalOvers: integer('total_overs').notNull(),
  ballTypeId: integer('ball_type_id').notNull().references(() => ballTypes.id, { onDelete: 'restrict' }),
  venue: varchar('venue', { length: 200 }),
  tossWinnerId: uuid('toss_winner_id').references(() => teams.id, { onDelete: 'restrict' }),
  tossDecision: varchar('toss_decision', { length: 10 }),
  status: varchar('status', { length: 20 }).default('setup').notNull(),
  scorerId: uuid('scorer_id').references(() => users.id, { onDelete: 'restrict' }),
  playersPerSide: integer('players_per_side').default(11).notNull(),
  maxOversPerBowler: integer('max_overs_per_bowler'),
  wideRuns: integer('wide_runs').default(1).notNull(),
  noBallRuns: integer('no_ball_runs').default(1).notNull(),
  powerplayOvers: integer('powerplay_overs'),
  magicOverNumbers: jsonb('magic_over_numbers').$type<number[] | null>(),
  magicOverRunMultiplier: integer('magic_over_run_multiplier').default(2).notNull(),
  magicOverWicketPenalty: integer('magic_over_wicket_penalty').default(-5).notNull(),
  createdBy: uuid('created_by').notNull().references(() => users.id, { onDelete: 'restrict' }),
  matchDate: date('match_date', { mode: 'string' }).notNull(),
  createdAt: timestamp('created_at', { mode: 'date' }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { mode: 'date' }).defaultNow().notNull().$onUpdate(() => new Date()),
}, (table) => [
  index('idx_matches_status').on(table.status),
  index('idx_matches_teams').on(table.homeTeamId, table.awayTeamId),
  index('idx_matches_tournament').on(table.tournamentId).where(sql`tournament_id IS NOT NULL`),
]);

export const matchPlayers = pgTable('match_players', {
  id: uuid('id').defaultRandom().primaryKey(),
  matchId: uuid('match_id').notNull().references(() => matches.id, { onDelete: 'cascade' }),
  teamId: uuid('team_id').notNull().references(() => teams.id, { onDelete: 'restrict' }),
  playerId: uuid('player_id').notNull().references(() => users.id, { onDelete: 'restrict' }),
  battingOrder: integer('batting_order'),
  isPlaying: boolean('is_playing').default(true).notNull(),
  isCaptain: boolean('is_captain').default(false).notNull(),
  isKeeper: boolean('is_keeper').default(false).notNull(),
  createdAt: timestamp('created_at', { mode: 'date' }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { mode: 'date' }).defaultNow().notNull().$onUpdate(() => new Date()),
}, (table) => [
  unique('uq_match_players_match_team_player').on(table.matchId, table.teamId, table.playerId),
  index('idx_match_players_match').on(table.matchId),
  index('idx_match_players_team').on(table.matchId, table.teamId),
  index('idx_match_players_player').on(table.playerId),
]);

export const matchResult = pgTable('match_result', {
  id: uuid('id').defaultRandom().primaryKey(),
  matchId: uuid('match_id').notNull().references(() => matches.id, { onDelete: 'cascade' }).unique(),
  winnerTeamId: uuid('winner_team_id').references(() => teams.id, { onDelete: 'restrict' }),
  resultType: varchar('result_type', { length: 20 }).notNull(),
  margin: integer('margin'),
  manOfMatchId: uuid('man_of_match_id').references(() => users.id, { onDelete: 'set null' }),
  summary: text('summary'),
  createdAt: timestamp('created_at', { mode: 'date' }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { mode: 'date' }).defaultNow().notNull().$onUpdate(() => new Date()),
});

export const matchAnalytics = pgTable('match_analytics', {
  id: uuid('id').defaultRandom().primaryKey(),
  matchId: uuid('match_id').notNull().references(() => matches.id, { onDelete: 'cascade' }),
  manhattanData: jsonb('manhattan_data'),
  wormData: jsonb('worm_data'),
  mvpScores: jsonb('mvp_scores'),
  createdAt: timestamp('created_at', { mode: 'date' }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { mode: 'date' }).defaultNow().notNull().$onUpdate(() => new Date()),
}, (table) => [
  index('idx_match_analytics_match').on(table.matchId),
]);
