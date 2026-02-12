import { pgTable, uuid, varchar, text, timestamp } from 'drizzle-orm/pg-core';

export const users = pgTable('users', {
  id: uuid('id').defaultRandom().primaryKey(),
  firebaseUid: varchar('firebase_uid', { length: 128 }).notNull().unique(),
  phone: varchar('phone', { length: 15 }),
  email: varchar('email', { length: 255 }),
  displayName: varchar('display_name', { length: 60 }).notNull(),
  avatarUrl: text('avatar_url'),
  battingStyle: varchar('batting_style', { length: 20 }),
  bowlingStyle: varchar('bowling_style', { length: 30 }),
  playerRole: varchar('player_role', { length: 20 }),
  location: varchar('location', { length: 100 }),
  createdAt: timestamp('created_at', { mode: 'date' }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { mode: 'date' }).defaultNow().notNull().$onUpdate(() => new Date()),
});
