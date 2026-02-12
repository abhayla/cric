import { Elysia } from 'elysia';
import { db } from '../../db/index.ts';
import { sql } from 'drizzle-orm';

const startTime = Date.now();

export const healthRoutes = new Elysia({ prefix: '/api/v1' }).get(
  '/health',
  async () => {
    let dbStatus = 'disconnected';
    try {
      await db.execute(sql`SELECT 1`);
      dbStatus = 'connected';
    } catch {
      dbStatus = 'disconnected';
    }

    return {
      status: 'ok',
      version: '0.1.0',
      uptime: Math.floor((Date.now() - startTime) / 1000),
      database: dbStatus,
    };
  },
);
