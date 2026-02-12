import { Elysia } from 'elysia';
import { initFirebase } from './config/firebase.ts';
import { env } from './config/env.ts';
import { corsMiddleware } from './middleware/cors.ts';
import { errorHandler } from './middleware/error-handler.ts';
import { healthRoutes } from './routes/v1/health.ts';
import { authRoutes } from './routes/v1/auth.ts';

initFirebase();

const app = new Elysia()
  .use(corsMiddleware)
  .use(errorHandler)
  .use(healthRoutes)
  .use(authRoutes)
  .listen(env.PORT);

console.log(
  `CricApp server running at ${app.server?.hostname}:${app.server?.port}`,
);

export type App = typeof app;
