import { pgTable, serial, varchar, boolean, integer, timestamp } from 'drizzle-orm/pg-core';

// 1.1 ball_types
export const ballTypes = pgTable('ball_types', {
  id: serial('id').primaryKey(),
  name: varchar('name', { length: 50 }).notNull().unique(),
  createdAt: timestamp('created_at', { mode: 'date' }).defaultNow().notNull(),
});

// 1.2 dismissal_types
export const dismissalTypes = pgTable('dismissal_types', {
  id: serial('id').primaryKey(),
  name: varchar('name', { length: 50 }).notNull().unique(),
  code: varchar('code', { length: 10 }).notNull(),
  requiresFielder: boolean('requires_fielder').default(false).notNull(),
  requiresBowlerCredit: boolean('requires_bowler_credit').default(false).notNull(),
  createdAt: timestamp('created_at', { mode: 'date' }).defaultNow().notNull(),
});

// 1.3 fielding_positions
export const fieldingPositions = pgTable('fielding_positions', {
  id: serial('id').primaryKey(),
  name: varchar('name', { length: 50 }).notNull().unique(),
  code: varchar('code', { length: 10 }).notNull(),
  createdAt: timestamp('created_at', { mode: 'date' }).defaultNow().notNull(),
});

// 1.4 wagon_wheel_zones
export const wagonWheelZones = pgTable('wagon_wheel_zones', {
  id: serial('id').primaryKey(),
  zoneCode: varchar('zone_code', { length: 10 }).notNull().unique(),
  label: varchar('label', { length: 50 }).notNull(),
  startAngle: integer('start_angle').notNull(),
  endAngle: integer('end_angle').notNull(),
  side: varchar('side', { length: 10 }).notNull(),
  createdAt: timestamp('created_at', { mode: 'date' }).defaultNow().notNull(),
});
