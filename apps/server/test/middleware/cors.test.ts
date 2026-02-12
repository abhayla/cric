import { describe, expect, it } from 'bun:test';
import { Elysia } from 'elysia';
import { corsMiddleware } from '../../src/middleware/cors.ts';

describe('CORS Middleware', () => {
  const app = new Elysia()
    .use(corsMiddleware)
    .get('/test', () => ({ ok: true }));

  it('sets CORS headers on GET requests', async () => {
    const res = await app.handle(new Request('http://localhost/test'));
    expect(res.headers.get('Access-Control-Allow-Origin')).toBe('*');
    expect(res.headers.get('Access-Control-Allow-Methods')).toContain('GET');
    expect(res.headers.get('Access-Control-Allow-Headers')).toContain(
      'Authorization',
    );
  });

  it('handles OPTIONS preflight with 204', async () => {
    const res = await app.handle(
      new Request('http://localhost/test', { method: 'OPTIONS' }),
    );
    expect(res.status).toBe(204);
    expect(res.headers.get('Access-Control-Allow-Origin')).toBe('*');
    expect(res.headers.get('Access-Control-Max-Age')).toBe('86400');
  });
});
