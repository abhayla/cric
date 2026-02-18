import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import { env } from './env.ts';
import * as schema from '../db/schema/index.ts';

const client = postgres(env.DATABASE_URL, {
  max: process.env.NODE_ENV === 'test' ? 30 : 10,
  idle_timeout: 20,
  connect_timeout: 30,
});

export const db = drizzle(client, { schema });
