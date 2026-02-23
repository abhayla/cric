import { Elysia } from 'elysia';
import { initFirebase } from './config/firebase.ts';
import { env } from './config/env.ts';
import { corsMiddleware } from './middleware/cors.ts';
import { rateLimiter } from './middleware/rate-limiter.ts';
import { errorHandler } from './middleware/error-handler.ts';
import { healthRoutes } from './routes/v1/health.ts';
import { authRoutes } from './routes/v1/auth.ts';
import { teamRoutes } from './routes/v1/teams.ts';
import { playerRoutes } from './routes/v1/players.ts';
import { matchRoutes } from './routes/v1/matches.ts';
import { tournamentRoutes } from './routes/v1/tournaments.ts';
import { scoringRoutes } from './routes/v1/scoring.ts';
import { uploadRoutes } from './routes/v1/uploads.ts';
import { activityFeedRoutes } from './routes/v1/activity-feed.ts';
import { websocketHandler } from './websocket/handler.ts';
import { initBroadcaster } from './websocket/broadcaster.ts';

initFirebase();

// Production safety: ENABLE_TEST_AUTH must never be set in production
if (env.NODE_ENV === 'production' && process.env.ENABLE_TEST_AUTH === 'true') {
  console.error('FATAL: ENABLE_TEST_AUTH is forbidden in production');
  process.exit(1);
}

const app = new Elysia()
  .use(corsMiddleware)
  .use(rateLimiter)
  .use(errorHandler)
  .use(websocketHandler)
  .use(healthRoutes)
  .use(authRoutes)
  .use(teamRoutes)
  .use(playerRoutes)
  .use(matchRoutes)
  .use(tournamentRoutes)
  .use(scoringRoutes)
  .use(uploadRoutes)
  .use(activityFeedRoutes);

// Only register test verification routes in test environment
if (process.env.NODE_ENV === 'test') {
  const { testVerifyRoutes } = await import('./routes/v1/test-verify.routes.ts');
  app.use(testVerifyRoutes);
}

app.listen(env.PORT);

initBroadcaster(app.server!);

console.log(
  `CricApp server running at ${app.server?.hostname}:${app.server?.port}`,
);

export type App = typeof app;
