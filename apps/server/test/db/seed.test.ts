import { describe, expect, test, beforeAll } from 'bun:test';
import postgres from 'postgres';
import { drizzle } from 'drizzle-orm/postgres-js';
import { count, eq } from 'drizzle-orm';
import * as schema from '../../src/db/schema/index.ts';

const TEST_DB_URL = process.env['DATABASE_URL'] ?? 'postgresql://cricapp_user:CricApp2024Secure@localhost:5432/cricapp_dev';

const client = postgres(TEST_DB_URL);
const db = drizzle(client, { schema });

describe('Seed Data', () => {
  test('ball_types has 4 records', async () => {
    const result = await db.select({ count: count() }).from(schema.ballTypes);
    expect(result[0]!.count).toBe(4);
  });

  test('ball_types contains expected types', async () => {
    const rows = await db.select({ name: schema.ballTypes.name }).from(schema.ballTypes);
    const names = rows.map((r) => r.name);
    expect(names).toContain('leather');
    expect(names).toContain('tennis');
    expect(names).toContain('tape');
    expect(names).toContain('other');
  });

  test('dismissal_types has 11 records', async () => {
    const result = await db.select({ count: count() }).from(schema.dismissalTypes);
    expect(result[0]!.count).toBe(11);
  });

  test('dismissal_types have correct flags', async () => {
    // caught requires fielder and bowler credit
    const caught = await db
      .select()
      .from(schema.dismissalTypes)
      .where(eq(schema.dismissalTypes.name, 'caught'));
    expect(caught).toHaveLength(1);
    expect(caught[0]!.requiresFielder).toBe(true);
    expect(caught[0]!.requiresBowlerCredit).toBe(true);

    // run_out requires fielder but NOT bowler credit
    const runOut = await db
      .select()
      .from(schema.dismissalTypes)
      .where(eq(schema.dismissalTypes.name, 'run_out'));
    expect(runOut).toHaveLength(1);
    expect(runOut[0]!.requiresFielder).toBe(true);
    expect(runOut[0]!.requiresBowlerCredit).toBe(false);

    // bowled does NOT require fielder but DOES require bowler credit
    const bowled = await db
      .select()
      .from(schema.dismissalTypes)
      .where(eq(schema.dismissalTypes.name, 'bowled'));
    expect(bowled).toHaveLength(1);
    expect(bowled[0]!.requiresFielder).toBe(false);
    expect(bowled[0]!.requiresBowlerCredit).toBe(true);

    // retired_hurt requires neither
    const retiredHurt = await db
      .select()
      .from(schema.dismissalTypes)
      .where(eq(schema.dismissalTypes.name, 'retired_hurt'));
    expect(retiredHurt).toHaveLength(1);
    expect(retiredHurt[0]!.requiresFielder).toBe(false);
    expect(retiredHurt[0]!.requiresBowlerCredit).toBe(false);
  });

  test('fielding_positions has 16 records', async () => {
    const result = await db.select({ count: count() }).from(schema.fieldingPositions);
    expect(result[0]!.count).toBe(16);
  });

  test('fielding_positions have codes', async () => {
    const wk = await db
      .select()
      .from(schema.fieldingPositions)
      .where(eq(schema.fieldingPositions.name, 'wicket_keeper'));
    expect(wk).toHaveLength(1);
    expect(wk[0]!.code).toBe('wk');
  });

  test('wagon_wheel_zones has 12 records', async () => {
    const result = await db.select({ count: count() }).from(schema.wagonWheelZones);
    expect(result[0]!.count).toBe(12);
  });

  test('wagon_wheel_zones have correct angles', async () => {
    const of1 = await db
      .select()
      .from(schema.wagonWheelZones)
      .where(eq(schema.wagonWheelZones.zoneCode, 'OF1'));
    expect(of1).toHaveLength(1);
    expect(of1[0]!.startAngle).toBe(0);
    expect(of1[0]!.endAngle).toBe(30);
    expect(of1[0]!.side).toBe('offside');
    expect(of1[0]!.label).toBe('Third Man');

    const on6 = await db
      .select()
      .from(schema.wagonWheelZones)
      .where(eq(schema.wagonWheelZones.zoneCode, 'ON6'));
    expect(on6).toHaveLength(1);
    expect(on6[0]!.startAngle).toBe(330);
    expect(on6[0]!.endAngle).toBe(360);
    expect(on6[0]!.side).toBe('onside');
  });

  test('total seed records: 43 (4+11+16+12)', async () => {
    const [bt, dt, fp, ww] = await Promise.all([
      db.select({ count: count() }).from(schema.ballTypes),
      db.select({ count: count() }).from(schema.dismissalTypes),
      db.select({ count: count() }).from(schema.fieldingPositions),
      db.select({ count: count() }).from(schema.wagonWheelZones),
    ]);
    const total = bt[0]!.count + dt[0]!.count + fp[0]!.count + ww[0]!.count;
    expect(total).toBe(43);
  });
});
