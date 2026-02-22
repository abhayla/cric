import { describe, expect, test } from 'bun:test';
import * as schema from '../../src/db/schema/index.ts';

const EXPECTED_TABLES = [
  // Master data (4)
  'ball_types',
  'dismissal_types',
  'fielding_positions',
  'wagon_wheel_zones',
  // Users (1)
  'users',
  // Teams (2)
  'teams',
  'team_rosters',
  // Matches (4)
  'matches',
  'match_players',
  'match_result',
  'match_analytics',
  // Innings (2)
  'innings',
  'overs',
  // Deliveries (3)
  'deliveries',
  'wickets_by_delivery',
  'fall_of_wickets',
  // Stats (4)
  'batting_stats',
  'bowling_stats',
  'fielding_stats',
  'player_career_stats',
  // Tournaments (6)
  'tournaments',
  'tournament_teams',
  'tournament_groups',
  'tournament_fixtures',
  'tournament_standings',
  'tournament_requests',
  // Activity Feed (1)
  'activity_feed',
] as const;

describe('Schema Validation', () => {
  test('exports all 27 table definitions', () => {
    // Each table export is a Drizzle table object with a symbol key for table name
    const exportedTables = Object.values(schema).filter(
      (value) => typeof value === 'object' && value !== null && Symbol.for('drizzle:Name') in value,
    );
    expect(exportedTables.length).toBe(27);
  });

  test.each(EXPECTED_TABLES)('exports table: %s', (tableName) => {
    const exportedTables = Object.values(schema).filter(
      (value): value is Record<symbol, string> =>
        typeof value === 'object' && value !== null && Symbol.for('drizzle:Name') in value,
    );
    const tableNames = exportedTables.map(
      (t) => (t as Record<string | symbol, unknown>)[Symbol.for('drizzle:Name')] as string,
    );
    expect(tableNames).toContain(tableName);
  });

  test('deliveries table has critical columns', () => {
    const cols = Object.keys(schema.deliveries);
    const criticalColumns = [
      'id', 'inningsId', 'overNumber', 'ballNumber', 'sequenceNumber',
      'strikerId', 'nonStrikerId', 'bowlerId', 'runsFromBat',
      'isWide', 'isNoBall', 'isBye', 'isLegBye', 'totalRuns',
      'isWicket', 'isLegal', 'isBoundaryFour', 'isBoundarySix',
      'isFreeHit', 'isPenalty', 'synced',
    ];
    for (const col of criticalColumns) {
      expect(cols).toContain(col);
    }
  });

  test('innings table has super over fields', () => {
    const cols = Object.keys(schema.innings);
    expect(cols).toContain('isSuperOver');
    expect(cols).toContain('superOverNumber');
  });

  test('matches table has rule fields', () => {
    const cols = Object.keys(schema.matches);
    const ruleFields = ['playersPerSide', 'maxOversPerBowler', 'wideRuns', 'noBallRuns', 'powerplayOvers'];
    for (const field of ruleFields) {
      expect(cols).toContain(field);
    }
  });

  test('tournaments table has template rule fields', () => {
    const cols = Object.keys(schema.tournaments);
    const ruleFields = ['playersPerSide', 'maxOversPerBowler', 'wideRuns', 'noBallRuns', 'powerplayOvers'];
    for (const field of ruleFields) {
      expect(cols).toContain(field);
    }
  });
});
