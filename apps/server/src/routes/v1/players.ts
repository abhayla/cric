import { Elysia, t } from 'elysia';
import { authMiddleware } from '../../middleware/auth.ts';
import { validateUuid } from '../../middleware/error-handler.ts';
import {
  searchPlayersByName,
  searchPlayerByPhone,
  createPlayer,
  getPlayerProfile,
  getPlayerStats,
  getPlayerMatches,
} from '../../services/player.service.ts';

const BATTING_STYLES = ['right_hand', 'left_hand'] as const;
const BOWLING_STYLES = [
  'right_arm_fast',
  'right_arm_medium',
  'right_arm_off_spin',
  'right_arm_leg_spin',
  'left_arm_fast',
  'left_arm_medium',
  'left_arm_orthodox',
  'left_arm_chinaman',
  'none',
] as const;
const PLAYER_ROLES = ['batter', 'bowler', 'all_rounder', 'wk_batter'] as const;

export const playerRoutes = new Elysia({ prefix: '/api/v1/players' })
  .use(authMiddleware)
  .get(
    '/search',
    async (ctx) => {
      const query = ctx.query.q || '';
      const limit = Math.min(Number(ctx.query.limit) || 10, 50);

      const players = await searchPlayersByName(query, limit);
      return { players };
    },
    {
      query: t.Object({
        q: t.Optional(t.String()),
        limit: t.Optional(t.String()),
      }),
    },
  )
  .get(
    '/search-by-phone',
    async (ctx) => {
      const phone = ctx.query.phone || '';
      const player = await searchPlayerByPhone(phone);
      return { player };
    },
    {
      query: t.Object({
        phone: t.String(),
      }),
    },
  )
  .post(
    '/',
    async (ctx) => {
      const player = await createPlayer({
        displayName: ctx.body.displayName,
        phone: ctx.body.phone,
        playerRole: ctx.body.playerRole,
        battingStyle: ctx.body.battingStyle,
        bowlingStyle: ctx.body.bowlingStyle,
      });

      ctx.set.status = 201;
      return { player };
    },
    {
      body: t.Object({
        displayName: t.String({ minLength: 2, maxLength: 50 }),
        phone: t.Optional(t.String()),
        playerRole: t.Optional(t.Union(PLAYER_ROLES.map((r) => t.Literal(r)))),
        battingStyle: t.Optional(t.Union(BATTING_STYLES.map((s) => t.Literal(s)))),
        bowlingStyle: t.Optional(t.Union(BOWLING_STYLES.map((s) => t.Literal(s)))),
      }),
    },
  )
  .get(
    '/:id',
    async (ctx) => {
      validateUuid(ctx.params.id, 'player id');
      const profile = await getPlayerProfile(ctx.params.id);
      return { player: profile };
    },
    {
      params: t.Object({ id: t.String() }),
    },
  )
  .get(
    '/:id/stats',
    async (ctx) => {
      validateUuid(ctx.params.id, 'player id');
      const format = ctx.query.format || 'all';
      const stats = await getPlayerStats(ctx.params.id, format);
      return { stats };
    },
    {
      params: t.Object({ id: t.String() }),
      query: t.Object({
        format: t.Optional(t.String()),
      }),
    },
  )
  .get(
    '/:id/matches',
    async (ctx) => {
      validateUuid(ctx.params.id, 'player id');
      const result = await getPlayerMatches(ctx.params.id, {
        page: ctx.query.page ? Number(ctx.query.page) : undefined,
        limit: ctx.query.limit ? Number(ctx.query.limit) : undefined,
        format: ctx.query.format || undefined,
        result: ctx.query.result as 'won' | 'lost' | 'tied' | 'no_result' | undefined,
      });
      return result;
    },
    {
      params: t.Object({ id: t.String() }),
      query: t.Object({
        page: t.Optional(t.String()),
        limit: t.Optional(t.String()),
        format: t.Optional(t.String()),
        result: t.Optional(t.String()),
      }),
    },
  );
