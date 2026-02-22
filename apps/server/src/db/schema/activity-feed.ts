import { pgTable, uuid, varchar, text, boolean, timestamp, index } from 'drizzle-orm/pg-core';
import { users } from './users.ts';

export const activityFeed = pgTable('activity_feed', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  eventType: varchar('event_type', { length: 30 }).notNull(),
  title: varchar('title', { length: 100 }).notNull(),
  description: text('description'),
  referenceType: varchar('reference_type', { length: 20 }),
  referenceId: uuid('reference_id'),
  isRead: boolean('is_read').default(false).notNull(),
  createdAt: timestamp('created_at', { mode: 'date' }).defaultNow().notNull(),
}, (table) => [
  index('idx_activity_feed_user_created').on(table.userId, table.createdAt),
]);
