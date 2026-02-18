import { Elysia, t } from 'elysia';
import { authMiddleware } from '../../middleware/auth.ts';
import { AppError } from '../../middleware/error-handler.ts';
import { getUserByFirebaseUid } from '../../services/auth.service.ts';
import {
  createTournament,
  getTournaments,
  getTournament,
  updateTournament,
  transitionStatus,
  addTeam,
  registerTeam,
  getRequests,
  resolveRequest,
  removeTeam,
  generateFixtures,
  getFixtures,
  editFixture,
  getStandings,
  getLeaderboard,
} from '../../services/tournament.service.ts';

const FORMATS = ['round_robin', 'knockout', 'group_knockout'] as const;
const STATUSES = ['draft', 'registration', 'live', 'completed'] as const;
const REQUEST_ACTIONS = ['approved', 'rejected'] as const;
export const tournamentRoutes = new Elysia({ prefix: '/api/v1/tournaments' })
  .use(authMiddleware)
  // POST / — Create tournament
  .post(
    '/',
    async (ctx) => {
      const { firebaseUser } = ctx as typeof ctx & {
        firebaseUser: { uid: string; phone: string | null; email: string | null };
      };
      const user = await getUserByFirebaseUid(firebaseUser.uid);
      if (!user) throw new AppError('UNAUTHORIZED', 'User not found', 401);

      const tournament = await createTournament({
        ...ctx.body,
        createdBy: user.id,
      });

      ctx.set.status = 201;
      return { tournament };
    },
    {
      body: t.Object({
        name: t.String({ minLength: 2, maxLength: 100 }),
        format: t.Union(FORMATS.map((f) => t.Literal(f))),
        oversPerMatch: t.Number({ minimum: 1, maximum: 50 }),
        ballTypeId: t.Number({ minimum: 1 }),
        pointsWin: t.Optional(t.Number({ minimum: 0, maximum: 10 })),
        pointsTie: t.Optional(t.Number({ minimum: 0, maximum: 10 })),
        pointsNoResult: t.Optional(t.Number({ minimum: 0, maximum: 10 })),
        pointsLoss: t.Optional(t.Number({ minimum: 0, maximum: 10 })),
        numGroups: t.Optional(t.Number({ minimum: 1, maximum: 8 })),
        qualifyPerGroup: t.Optional(t.Number({ minimum: 1, maximum: 4 })),
        hasThirdPlaceMatch: t.Optional(t.Boolean()),
        playersPerSide: t.Optional(t.Number({ minimum: 2, maximum: 11 })),
        maxOversPerBowler: t.Optional(t.Nullable(t.Number({ minimum: 1, maximum: 50 }))),
        wideRuns: t.Optional(t.Number({ minimum: 1, maximum: 5 })),
        noBallRuns: t.Optional(t.Number({ minimum: 1, maximum: 5 })),
        powerplayOvers: t.Optional(t.Nullable(t.Number({ minimum: 1 }))),
        magicOverNumbers: t.Optional(t.Nullable(t.Array(t.Number({ minimum: 1 })))),
        magicOverRunMultiplier: t.Optional(t.Number({ minimum: 1, maximum: 5 })),
        magicOverWicketPenalty: t.Optional(t.Number({ minimum: -20, maximum: 0 })),
        startDate: t.Optional(t.Nullable(t.String())),
        endDate: t.Optional(t.Nullable(t.String())),
      }),
    },
  )
  // GET / — List tournaments
  .get(
    '/',
    async (ctx) => {
      const { firebaseUser } = ctx as typeof ctx & {
        firebaseUser: { uid: string; phone: string | null; email: string | null };
      };
      const user = await getUserByFirebaseUid(firebaseUser.uid);
      if (!user) throw new AppError('UNAUTHORIZED', 'User not found', 401);

      const page = Number(ctx.query.page) || 1;
      const limit = Math.min(Number(ctx.query.limit) || 20, 100);

      return await getTournaments(user.id, page, limit, ctx.query.status);
    },
    {
      query: t.Object({
        page: t.Optional(t.String()),
        limit: t.Optional(t.String()),
        status: t.Optional(t.String()),
      }),
    },
  )
  // GET /:id — Tournament detail
  .get(
    '/:id',
    async (ctx) => {
      const tournament = await getTournament(ctx.params.id);
      if (!tournament) throw new AppError('NOT_FOUND', 'Tournament not found', 404);
      return { tournament };
    },
    {
      params: t.Object({ id: t.String() }),
    },
  )
  // PUT /:id — Update tournament
  .put(
    '/:id',
    async (ctx) => {
      const { firebaseUser } = ctx as typeof ctx & {
        firebaseUser: { uid: string; phone: string | null; email: string | null };
      };
      const user = await getUserByFirebaseUid(firebaseUser.uid);
      if (!user) throw new AppError('UNAUTHORIZED', 'User not found', 401);

      const updated = await updateTournament(ctx.params.id, user.id, ctx.body);
      return { tournament: updated };
    },
    {
      params: t.Object({ id: t.String() }),
      body: t.Object({
        name: t.Optional(t.String({ minLength: 2, maxLength: 100 })),
        oversPerMatch: t.Optional(t.Number({ minimum: 1, maximum: 50 })),
        ballTypeId: t.Optional(t.Number({ minimum: 1 })),
        pointsWin: t.Optional(t.Number({ minimum: 0, maximum: 10 })),
        pointsTie: t.Optional(t.Number({ minimum: 0, maximum: 10 })),
        pointsNoResult: t.Optional(t.Number({ minimum: 0, maximum: 10 })),
        pointsLoss: t.Optional(t.Number({ minimum: 0, maximum: 10 })),
        numGroups: t.Optional(t.Number({ minimum: 1, maximum: 8 })),
        qualifyPerGroup: t.Optional(t.Number({ minimum: 1, maximum: 4 })),
        hasThirdPlaceMatch: t.Optional(t.Boolean()),
        playersPerSide: t.Optional(t.Number({ minimum: 2, maximum: 11 })),
        maxOversPerBowler: t.Optional(t.Nullable(t.Number({ minimum: 1, maximum: 50 }))),
        wideRuns: t.Optional(t.Number({ minimum: 1, maximum: 5 })),
        noBallRuns: t.Optional(t.Number({ minimum: 1, maximum: 5 })),
        powerplayOvers: t.Optional(t.Nullable(t.Number({ minimum: 1 }))),
        magicOverNumbers: t.Optional(t.Nullable(t.Array(t.Number({ minimum: 1 })))),
        magicOverRunMultiplier: t.Optional(t.Number({ minimum: 1, maximum: 5 })),
        magicOverWicketPenalty: t.Optional(t.Number({ minimum: -20, maximum: 0 })),
        startDate: t.Optional(t.Nullable(t.String())),
        endDate: t.Optional(t.Nullable(t.String())),
      }),
    },
  )
  // PUT /:id/status — Transition status
  .put(
    '/:id/status',
    async (ctx) => {
      const { firebaseUser } = ctx as typeof ctx & {
        firebaseUser: { uid: string; phone: string | null; email: string | null };
      };
      const user = await getUserByFirebaseUid(firebaseUser.uid);
      if (!user) throw new AppError('UNAUTHORIZED', 'User not found', 401);

      const updated = await transitionStatus(ctx.params.id, user.id, ctx.body.status);
      return { tournament: updated };
    },
    {
      params: t.Object({ id: t.String() }),
      body: t.Object({
        status: t.Union(STATUSES.map((s) => t.Literal(s))),
      }),
    },
  )
  // POST /:id/teams — Organizer direct-add team
  .post(
    '/:id/teams',
    async (ctx) => {
      const { firebaseUser } = ctx as typeof ctx & {
        firebaseUser: { uid: string; phone: string | null; email: string | null };
      };
      const user = await getUserByFirebaseUid(firebaseUser.uid);
      if (!user) throw new AppError('UNAUTHORIZED', 'User not found', 401);

      const entry = await addTeam(
        ctx.params.id,
        user.id,
        ctx.body.teamId,
        ctx.body.groupName,
        ctx.body.seedNumber,
      );

      ctx.set.status = 201;
      return entry;
    },
    {
      params: t.Object({ id: t.String() }),
      body: t.Object({
        teamId: t.String(),
        groupName: t.Optional(t.Nullable(t.String({ maxLength: 10 }))),
        seedNumber: t.Optional(t.Nullable(t.Number({ minimum: 1 }))),
      }),
    },
  )
  // POST /:id/register — Team registration request
  .post(
    '/:id/register',
    async (ctx) => {
      const { firebaseUser } = ctx as typeof ctx & {
        firebaseUser: { uid: string; phone: string | null; email: string | null };
      };
      const user = await getUserByFirebaseUid(firebaseUser.uid);
      if (!user) throw new AppError('UNAUTHORIZED', 'User not found', 401);

      const request = await registerTeam(ctx.params.id, user.id, ctx.body.teamId);

      ctx.set.status = 201;
      return { request };
    },
    {
      params: t.Object({ id: t.String() }),
      body: t.Object({
        teamId: t.String(),
      }),
    },
  )
  // GET /:id/requests — List registration requests
  .get(
    '/:id/requests',
    async (ctx) => {
      const { firebaseUser } = ctx as typeof ctx & {
        firebaseUser: { uid: string; phone: string | null; email: string | null };
      };
      const user = await getUserByFirebaseUid(firebaseUser.uid);
      if (!user) throw new AppError('UNAUTHORIZED', 'User not found', 401);

      const requests = await getRequests(ctx.params.id, user.id, ctx.query.status);
      return { requests, total: requests.length };
    },
    {
      params: t.Object({ id: t.String() }),
      query: t.Object({
        status: t.Optional(t.String()),
      }),
    },
  )
  // PUT /:id/requests/:requestId — Approve/reject request
  .put(
    '/:id/requests/:requestId',
    async (ctx) => {
      const { firebaseUser } = ctx as typeof ctx & {
        firebaseUser: { uid: string; phone: string | null; email: string | null };
      };
      const user = await getUserByFirebaseUid(firebaseUser.uid);
      if (!user) throw new AppError('UNAUTHORIZED', 'User not found', 401);

      const result = await resolveRequest(
        ctx.params.id,
        user.id,
        ctx.params.requestId,
        ctx.body.status,
        ctx.body.groupName,
        ctx.body.seedNumber,
        ctx.body.rejectionReason,
      );

      return { request: result };
    },
    {
      params: t.Object({ id: t.String(), requestId: t.String() }),
      body: t.Object({
        status: t.Union(REQUEST_ACTIONS.map((a) => t.Literal(a))),
        groupName: t.Optional(t.Nullable(t.String({ maxLength: 10 }))),
        seedNumber: t.Optional(t.Nullable(t.Number({ minimum: 1 }))),
        rejectionReason: t.Optional(t.Nullable(t.String({ maxLength: 500 }))),
      }),
    },
  )
  // DELETE /:id/teams/:teamId — Remove team
  .delete(
    '/:id/teams/:teamId',
    async (ctx) => {
      const { firebaseUser } = ctx as typeof ctx & {
        firebaseUser: { uid: string; phone: string | null; email: string | null };
      };
      const user = await getUserByFirebaseUid(firebaseUser.uid);
      if (!user) throw new AppError('UNAUTHORIZED', 'User not found', 401);

      await removeTeam(ctx.params.id, user.id, ctx.params.teamId);
      return { message: 'Team removed from tournament' };
    },
    {
      params: t.Object({ id: t.String(), teamId: t.String() }),
    },
  )
  // POST /:id/fixtures/generate — Auto-generate fixtures
  .post(
    '/:id/fixtures/generate',
    async (ctx) => {
      const { firebaseUser } = ctx as typeof ctx & {
        firebaseUser: { uid: string; phone: string | null; email: string | null };
      };
      const user = await getUserByFirebaseUid(firebaseUser.uid);
      if (!user) throw new AppError('UNAUTHORIZED', 'User not found', 401);

      const result = await generateFixtures(ctx.params.id, user.id);

      ctx.set.status = 201;
      return result;
    },
    {
      params: t.Object({ id: t.String() }),
    },
  )
  // GET /:id/fixtures — List fixtures
  .get(
    '/:id/fixtures',
    async (ctx) => {
      const fixtures = await getFixtures(
        ctx.params.id,
        ctx.query.roundType,
        ctx.query.groupName,
      );
      return { fixtures, total: fixtures.length };
    },
    {
      params: t.Object({ id: t.String() }),
      query: t.Object({
        roundType: t.Optional(t.String()),
        groupName: t.Optional(t.String()),
      }),
    },
  )
  // PUT /:id/fixtures/:fixtureId — Edit fixture
  .put(
    '/:id/fixtures/:fixtureId',
    async (ctx) => {
      const { firebaseUser } = ctx as typeof ctx & {
        firebaseUser: { uid: string; phone: string | null; email: string | null };
      };
      const user = await getUserByFirebaseUid(firebaseUser.uid);
      if (!user) throw new AppError('UNAUTHORIZED', 'User not found', 401);

      const result = await editFixture(ctx.params.id, user.id, ctx.params.fixtureId, ctx.body);
      return result;
    },
    {
      params: t.Object({ id: t.String(), fixtureId: t.String() }),
      body: t.Object({
        scheduledDate: t.Optional(t.Nullable(t.String())),
        scheduledTime: t.Optional(t.Nullable(t.String())),
        estimatedDurationMinutes: t.Optional(t.Nullable(t.Number({ minimum: 30 }))),
        venue: t.Optional(t.Nullable(t.String({ maxLength: 200 }))),
        homeTeamId: t.Optional(t.String()),
        awayTeamId: t.Optional(t.String()),
      }),
    },
  )
  // GET /:id/standings — Points table
  .get(
    '/:id/standings',
    async (ctx) => {
      return await getStandings(ctx.params.id, ctx.query.groupName);
    },
    {
      params: t.Object({ id: t.String() }),
      query: t.Object({
        groupName: t.Optional(t.String()),
      }),
    },
  )
  // GET /:id/leaderboard — Player leaderboard
  .get(
    '/:id/leaderboard',
    async (ctx) => {
      const limit = Math.min(Number(ctx.query.limit) || 10, 100);
      return await getLeaderboard(ctx.params.id, ctx.query.category ?? 'runs', limit);
    },
    {
      params: t.Object({ id: t.String() }),
      query: t.Object({
        category: t.Optional(t.String()),
        limit: t.Optional(t.String()),
      }),
    },
  );
