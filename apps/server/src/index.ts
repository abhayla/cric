import { Elysia } from 'elysia';
import { healthRoutes } from './routes/v1/health.ts';

const app = new Elysia()
  .use(healthRoutes)
  .listen(Number(process.env['PORT']) || 3000);

console.log(
  `CricApp server running at ${app.server?.hostname}:${app.server?.port}`,
);

export type App = typeof app;
