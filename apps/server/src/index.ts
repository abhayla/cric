import { Elysia } from 'elysia';
import { initFirebase } from './config/firebase.ts';
import { env } from './config/env.ts';
import { corsMiddleware } from './middleware/cors.ts';
import { errorHandler } from './middleware/error-handler.ts';
import { healthRoutes } from './routes/v1/health.ts';
import { authRoutes } from './routes/v1/auth.ts';
import { teamRoutes } from './routes/v1/teams.ts';
import { playerRoutes } from './routes/v1/players.ts';
import { matchRoutes } from './routes/v1/matches.ts';
import { tournamentRoutes } from './routes/v1/tournaments.ts';
import { scoringRoutes } from './routes/v1/scoring.ts';
import { websocketHandler } from './websocket/handler.ts';
import { initBroadcaster } from './websocket/broadcaster.ts';

initFirebase();

const app = new Elysia()
  .use(corsMiddleware)
  .use(errorHandler)
  .use(websocketHandler)
  .use(healthRoutes)
  .use(authRoutes)
  .use(teamRoutes)
  .use(playerRoutes)
  .use(matchRoutes)
  .use(tournamentRoutes)
  .use(scoringRoutes)
  .listen(env.PORT);

initBroadcaster(app.server!);

console.log(
  `CricApp server running at ${app.server?.hostname}:${app.server?.port}`,
);

export type App = typeof app;
