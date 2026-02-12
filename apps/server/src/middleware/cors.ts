import { Elysia } from 'elysia';
import { env } from '../config/env.ts';

export const corsMiddleware = new Elysia({ name: 'cors' }).onRequest(
  ({ set, request }) => {
    const origin = env.CORS_ORIGIN;

    set.headers['Access-Control-Allow-Origin'] = origin;
    set.headers['Access-Control-Allow-Methods'] =
      'GET, POST, PUT, DELETE, PATCH, OPTIONS';
    set.headers['Access-Control-Allow-Headers'] =
      'Content-Type, Authorization';
    set.headers['Access-Control-Max-Age'] = '86400';

    if (request.method === 'OPTIONS') {
      set.status = 204;
      return '';
    }
  },
);
