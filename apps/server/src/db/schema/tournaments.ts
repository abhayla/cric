import { pgTable, uuid, varchar, integer, boolean, decimal, timestamp, date, time, unique, index, jsonb } from 'drizzle-orm/pg-core';
import { users } from './users.ts';
import { teams } from './teams.ts';
import { matches } from './matches.ts';
import { ballTypes } from './master-data.ts';

export const tournaments = pgTable('tournaments', {
  id: uuid('id').defaultRandom().primaryKey(),
  name: varchar('name', { length: 100 }).notNull(),
  format: varchar('format', { length: 20 }).notNull(),
  oversPerMatch: integer('overs_per_match').notNull(),
  ballTypeId: integer('ball_type_id').notNull().references(() => ballTypes.id, { onDelete: 'restrict' }),
  status: varchar('status', { length: 20 }).default('draft').notNull(),
  pointsWin: integer('points_win').default(2).notNull(),
  pointsTie: integer('points_tie').default(1).notNull(),
  pointsNoResult: integer('points_no_result').default(1).notNull(),
  pointsLoss: integer('points_loss').default(0).notNull(),
  numGroups: integer('num_groups').default(1).notNull(),
  qualifyPerGroup: integer('qualify_per_group').default(2).notNull(),
  hasThirdPlaceMatch: boolean('has_third_place_match').default(false).notNull(),
  playersPerSide: integer('players_per_side').default(11).notNull(),
  maxOversPerBowler: integer('max_overs_per_bowler'),
  wideRuns: integer('wide_runs').default(1).notNull(),
  noBallRuns: integer('no_ball_runs').default(1).notNull(),
  powerplayOvers: integer('powerplay_overs'),
  magicOverNumbers: jsonb('magic_over_numbers').$type<number[] | null>(),
  magicOverRunMultiplier: integer('magic_over_run_multiplier').default(2).notNull(),
  magicOverWicketPenalty: integer('magic_over_wicket_penalty').default(-5).notNull(),
  createdBy: uuid('created_by').notNull().references(() => users.id, { onDelete: 'restrict' }),
  startDate: date('start_date', { mode: 'string' }),
  endDate: date('end_date', { mode: 'string' }),
  createdAt: timestamp('created_at', { mode: 'date' }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { mode: 'date' }).defaultNow().notNull().$onUpdate(() => new Date()),
}, (table) => [
  index('idx_tournaments_status').on(table.status),
  index('idx_tournaments_creator').on(table.createdBy),
]);

export const tournamentTeams = pgTable('tournament_teams', {
  id: uuid('id').defaultRandom().primaryKey(),
  tournamentId: uuid('tournament_id').notNull().references(() => tournaments.id, { onDelete: 'cascade' }),
  teamId: uuid('team_id').notNull().references(() => teams.id, { onDelete: 'restrict' }),
  groupName: varchar('group_name', { length: 10 }),
  seedNumber: integer('seed_number'),
  joinedAt: timestamp('joined_at', { mode: 'date' }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { mode: 'date' }).defaultNow().notNull().$onUpdate(() => new Date()),
}, (table) => [
  unique('uq_tournament_teams_tournament_team').on(table.tournamentId, table.teamId),
  index('idx_tournament_teams_tournament').on(table.tournamentId),
  index('idx_tournament_teams_team').on(table.teamId),
]);

export const tournamentGroups = pgTable('tournament_groups', {
  id: uuid('id').defaultRandom().primaryKey(),
  tournamentId: uuid('tournament_id').notNull().references(() => tournaments.id, { onDelete: 'cascade' }),
  name: varchar('name', { length: 10 }).notNull(),
  createdAt: timestamp('created_at', { mode: 'date' }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { mode: 'date' }).defaultNow().notNull().$onUpdate(() => new Date()),
}, (table) => [
  unique('uq_tournament_groups_tournament_name').on(table.tournamentId, table.name),
]);

export const tournamentFixtures = pgTable('tournament_fixtures', {
  id: uuid('id').defaultRandom().primaryKey(),
  tournamentId: uuid('tournament_id').notNull().references(() => tournaments.id, { onDelete: 'cascade' }),
  matchId: uuid('match_id').references(() => matches.id, { onDelete: 'set null' }),
  roundNumber: integer('round_number').notNull(),
  roundType: varchar('round_type', { length: 20 }).notNull(),
  fixtureOrder: integer('fixture_order').notNull(),
  groupName: varchar('group_name', { length: 10 }),
  homeTeamId: uuid('home_team_id').notNull().references(() => teams.id, { onDelete: 'restrict' }),
  awayTeamId: uuid('away_team_id').notNull().references(() => teams.id, { onDelete: 'restrict' }),
  scheduledDate: date('scheduled_date', { mode: 'string' }),
  scheduledTime: time('scheduled_time'),
  estimatedDurationMinutes: integer('estimated_duration_minutes'),
  venue: varchar('venue', { length: 200 }),
  createdAt: timestamp('created_at', { mode: 'date' }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { mode: 'date' }).defaultNow().notNull().$onUpdate(() => new Date()),
}, (table) => [
  index('idx_tournament_fixtures_tournament').on(table.tournamentId),
  index('idx_tournament_fixtures_match').on(table.matchId),
]);

export const tournamentStandings = pgTable('tournament_standings', {
  id: uuid('id').defaultRandom().primaryKey(),
  tournamentId: uuid('tournament_id').notNull().references(() => tournaments.id, { onDelete: 'cascade' }),
  teamId: uuid('team_id').notNull().references(() => teams.id, { onDelete: 'restrict' }),
  groupName: varchar('group_name', { length: 10 }),
  played: integer('played').default(0).notNull(),
  won: integer('won').default(0).notNull(),
  lost: integer('lost').default(0).notNull(),
  tied: integer('tied').default(0).notNull(),
  noResult: integer('no_result').default(0).notNull(),
  points: integer('points').default(0).notNull(),
  nrr: decimal('nrr', { precision: 6, scale: 3 }).default('0.000').notNull(),
  totalRunsScored: integer('total_runs_scored').default(0).notNull(),
  totalOversFaced: decimal('total_overs_faced', { precision: 6, scale: 1 }).default('0.0').notNull(),
  totalRunsConceded: integer('total_runs_conceded').default(0).notNull(),
  totalOversBowled: decimal('total_overs_bowled', { precision: 6, scale: 1 }).default('0.0').notNull(),
  position: integer('position'),
  updatedAt: timestamp('updated_at', { mode: 'date' }).defaultNow().notNull().$onUpdate(() => new Date()),
}, (table) => [
  unique('uq_tournament_standings_tournament_team').on(table.tournamentId, table.teamId),
  index('idx_tournament_standings_tournament').on(table.tournamentId),
  index('idx_tournament_standings_group').on(table.tournamentId, table.groupName),
]);

export const tournamentRequests = pgTable('tournament_requests', {
  id: uuid('id').defaultRandom().primaryKey(),
  tournamentId: uuid('tournament_id').notNull().references(() => tournaments.id, { onDelete: 'cascade' }),
  teamId: uuid('team_id').notNull().references(() => teams.id, { onDelete: 'restrict' }),
  requestedBy: uuid('requested_by').notNull().references(() => users.id, { onDelete: 'restrict' }),
  status: varchar('status', { length: 20 }).default('pending').notNull(),
  rejectionReason: varchar('rejection_reason', { length: 500 }),
  requestedAt: timestamp('requested_at', { mode: 'date' }).defaultNow().notNull(),
  resolvedAt: timestamp('resolved_at', { mode: 'date' }),
  updatedAt: timestamp('updated_at', { mode: 'date' }).defaultNow().notNull().$onUpdate(() => new Date()),
}, (table) => [
  unique('uq_tournament_requests_tournament_team').on(table.tournamentId, table.teamId),
  index('idx_tournament_requests_tournament').on(table.tournamentId),
  index('idx_tournament_requests_status').on(table.tournamentId, table.status),
]);
