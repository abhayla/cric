import { pgTable, uuid, varchar, text, boolean, integer, timestamp, unique, index } from 'drizzle-orm/pg-core';
import { users } from './users.ts';

export const teams = pgTable('teams', {
  id: uuid('id').defaultRandom().primaryKey(),
  name: varchar('name', { length: 100 }).notNull(),
  logoUrl: text('logo_url'),
  location: varchar('location', { length: 100 }),
  createdBy: uuid('created_by').notNull().references(() => users.id, { onDelete: 'restrict' }),
  isActive: boolean('is_active').default(true).notNull(),
  createdAt: timestamp('created_at', { mode: 'date' }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { mode: 'date' }).defaultNow().notNull().$onUpdate(() => new Date()),
});

export const teamRosters = pgTable('team_rosters', {
  id: uuid('id').defaultRandom().primaryKey(),
  teamId: uuid('team_id').notNull().references(() => teams.id, { onDelete: 'cascade' }),
  playerId: uuid('player_id').notNull().references(() => users.id, { onDelete: 'restrict' }),
  jerseyNumber: integer('jersey_number'),
  role: varchar('role', { length: 20 }).notNull(),
  isActive: boolean('is_active').default(true).notNull(),
  joinedAt: timestamp('joined_at', { mode: 'date' }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { mode: 'date' }).defaultNow().notNull().$onUpdate(() => new Date()),
}, (table) => [
  unique('uq_team_rosters_team_player').on(table.teamId, table.playerId),
  index('idx_rosters_team').on(table.teamId),
  index('idx_rosters_player').on(table.playerId),
]);
