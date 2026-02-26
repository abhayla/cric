import { drizzle } from 'drizzle-orm/postgres-js';
import postgres, { type Sql } from 'postgres';
import { env } from './env.ts';
import * as schema from '../db/schema/index.ts';

function createClient(): Sql {
  return postgres(env.DATABASE_URL, {
    max: 10,
    idle_timeout: 20,
    connect_timeout: 10,
    max_lifetime: 60 * 30,
    onnotice: () => {},
  });
}

let client = createClient();

export function recreatePool(): void {
  console.log('[database] Recreating connection pool...');
  client.end({ timeout: 2 }).catch(() => {});
  client = createClient();
  db = drizzle(client, { schema });
  console.log('[database] Connection pool recreated');
}

export let db = drizzle(client, { schema });
