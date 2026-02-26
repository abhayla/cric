import { Elysia } from 'elysia';
import { db } from '../../db/index.ts';
import { recreatePool } from '../../config/database.ts';
import { sql } from 'drizzle-orm';

const startTime = Date.now();
let consecutiveDbFailures = 0;

export const healthRoutes = new Elysia({ prefix: '/api/v1' }).get(
  '/health',
  async () => {
    let dbStatus = 'disconnected';
    const dbStart = Date.now();
    try {
      const timeoutPromise = new Promise((_, reject) =>
        setTimeout(() => reject(new Error('DB health check timeout')), 5000),
      );
      await Promise.race([db.execute(sql`SELECT 1`), timeoutPromise]);
      dbStatus = 'connected';
      consecutiveDbFailures = 0;
    } catch {
      consecutiveDbFailures++;
      if (consecutiveDbFailures >= 3) {
        console.log(
          `[health] ${consecutiveDbFailures} consecutive DB failures, recreating pool...`,
        );
        recreatePool();
        consecutiveDbFailures = 0;
      }
    }
    const dbLatency = Date.now() - dbStart;

    return {
      status: 'ok',
      version: '0.1.0',
      uptime: Math.floor((Date.now() - startTime) / 1000),
      database: dbStatus,
      dbLatencyMs: dbLatency,
    };
  },
);
