import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import { ballTypes, dismissalTypes, fieldingPositions, wagonWheelZones } from '../schema/master-data.ts';

const DATABASE_URL = process.env['DATABASE_URL'] ?? 'postgresql://cricapp_user:CricApp2024Secure@localhost:5432/cricapp_dev';
const client = postgres(DATABASE_URL);
const db = drizzle(client);

async function seed() {
  console.log('Seeding master data...');

  // Ball types (4)
  await db.insert(ballTypes).values([
    { name: 'leather' },
    { name: 'tennis' },
    { name: 'tape' },
    { name: 'other' },
  ]).onConflictDoNothing();
  console.log('  ball_types: 4 records');

  // Dismissal types (11)
  await db.insert(dismissalTypes).values([
    { name: 'bowled', code: 'b', requiresFielder: false, requiresBowlerCredit: true },
    { name: 'caught', code: 'c', requiresFielder: true, requiresBowlerCredit: true },
    { name: 'lbw', code: 'lbw', requiresFielder: false, requiresBowlerCredit: true },
    { name: 'run_out', code: 'ro', requiresFielder: true, requiresBowlerCredit: false },
    { name: 'stumped', code: 'st', requiresFielder: true, requiresBowlerCredit: true },
    { name: 'hit_wicket', code: 'hw', requiresFielder: false, requiresBowlerCredit: true },
    { name: 'caught_and_bowled', code: 'c&b', requiresFielder: false, requiresBowlerCredit: true },
    { name: 'retired_hurt', code: 'rh', requiresFielder: false, requiresBowlerCredit: false },
    { name: 'retired_out', code: 'rt', requiresFielder: false, requiresBowlerCredit: false },
    { name: 'timed_out', code: 'to', requiresFielder: false, requiresBowlerCredit: false },
    { name: 'obstructing_field', code: 'of', requiresFielder: false, requiresBowlerCredit: false },
  ]).onConflictDoNothing();
  console.log('  dismissal_types: 11 records');

  // Fielding positions (16)
  await db.insert(fieldingPositions).values([
    { name: 'wicket_keeper', code: 'wk' },
    { name: 'first_slip', code: '1sl' },
    { name: 'second_slip', code: '2sl' },
    { name: 'third_slip', code: '3sl' },
    { name: 'gully', code: 'gu' },
    { name: 'point', code: 'pt' },
    { name: 'cover', code: 'cv' },
    { name: 'mid_off', code: 'mo' },
    { name: 'mid_on', code: 'mn' },
    { name: 'mid_wicket', code: 'mw' },
    { name: 'square_leg', code: 'sl' },
    { name: 'fine_leg', code: 'fl' },
    { name: 'third_man', code: 'tm' },
    { name: 'long_off', code: 'lo' },
    { name: 'long_on', code: 'ln' },
    { name: 'deep_mid_wicket', code: 'dmw' },
  ]).onConflictDoNothing();
  console.log('  fielding_positions: 16 records');

  // Wagon wheel zones (12)
  await db.insert(wagonWheelZones).values([
    { zoneCode: 'OF1', label: 'Third Man', startAngle: 0, endAngle: 30, side: 'offside' },
    { zoneCode: 'OF2', label: 'Point/Backward Point', startAngle: 30, endAngle: 60, side: 'offside' },
    { zoneCode: 'OF3', label: 'Cover', startAngle: 60, endAngle: 90, side: 'offside' },
    { zoneCode: 'OF4', label: 'Extra Cover', startAngle: 90, endAngle: 120, side: 'offside' },
    { zoneCode: 'OF5', label: 'Mid Off', startAngle: 120, endAngle: 150, side: 'offside' },
    { zoneCode: 'OF6', label: 'Straight (Off)', startAngle: 150, endAngle: 180, side: 'offside' },
    { zoneCode: 'ON1', label: 'Straight (On)', startAngle: 180, endAngle: 210, side: 'onside' },
    { zoneCode: 'ON2', label: 'Mid On', startAngle: 210, endAngle: 240, side: 'onside' },
    { zoneCode: 'ON3', label: 'Mid Wicket', startAngle: 240, endAngle: 270, side: 'onside' },
    { zoneCode: 'ON4', label: 'Square Leg', startAngle: 270, endAngle: 300, side: 'onside' },
    { zoneCode: 'ON5', label: 'Fine Leg', startAngle: 300, endAngle: 330, side: 'onside' },
    { zoneCode: 'ON6', label: 'Behind (Leg)', startAngle: 330, endAngle: 360, side: 'onside' },
  ]).onConflictDoNothing();
  console.log('  wagon_wheel_zones: 12 records');

  console.log('Seed complete! (43 total records)');
  await client.end();
}

seed().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
