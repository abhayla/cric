import { describe, expect, it } from 'bun:test';
import { Elysia } from 'elysia';
import { authMiddleware } from '../../src/middleware/auth.ts';
import { AppError, errorHandler } from '../../src/middleware/error-handler.ts';

/**
 * Auth middleware tests.
 *
 * Note: In test mode (NODE_ENV=test), the middleware bypasses Firebase and
 * returns a hardcoded test user. This test file verifies:
 * 1. The test bypass returns the expected test user
 * 2. The middleware integrates correctly with Elysia routes
 * 3. The firebaseUser is available in route handlers
 *
 * The real Firebase token verification path cannot be tested without valid
 * Firebase credentials and tokens. That path is covered by manual QA and
 * the E2E test suite (which uses real Firebase Auth).
 */

describe('Auth Middleware', () => {
  it('provides firebaseUser in test mode', async () => {
    const app = new Elysia()
      .use(authMiddleware)
      .get('/test', ({ firebaseUser }) => ({ user: firebaseUser }));

    const response = await app.handle(new Request('http://localhost/test'));
    expect(response.status).toBe(200);

    const body = await response.json();
    expect(body.user).toEqual({
      uid: 'test-user-e2e-001',
      phone: '+919999900001',
      email: null,
    });
  });

  it('test user has correct shape (uid, phone, email)', async () => {
    const app = new Elysia()
      .use(authMiddleware)
      .get('/shape', ({ firebaseUser }) => ({
        hasUid: typeof firebaseUser.uid === 'string',
        hasPhone: typeof firebaseUser.phone === 'string',
        hasEmail: firebaseUser.email === null,
      }));

    const response = await app.handle(new Request('http://localhost/shape'));
    const body = await response.json();
    expect(body.hasUid).toBe(true);
    expect(body.hasPhone).toBe(true);
    expect(body.hasEmail).toBe(true);
  });

  it('firebaseUser is available on POST routes', async () => {
    const app = new Elysia()
      .use(authMiddleware)
      .post('/protected', ({ firebaseUser }) => ({ uid: firebaseUser.uid }));

    const response = await app.handle(
      new Request('http://localhost/protected', { method: 'POST' }),
    );
    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body.uid).toBe('test-user-e2e-001');
  });

  it('middleware is scoped (does not affect sibling routes without it)', async () => {
    const app = new Elysia()
      .get('/public', () => ({ message: 'ok' }))
      .use(authMiddleware)
      .get('/private', ({ firebaseUser }) => ({ uid: firebaseUser.uid }));

    // Public route works
    const publicRes = await app.handle(new Request('http://localhost/public'));
    expect(publicRes.status).toBe(200);

    // Private route has auth
    const privateRes = await app.handle(new Request('http://localhost/private'));
    expect(privateRes.status).toBe(200);
    const body = await privateRes.json();
    expect(body.uid).toBe('test-user-e2e-001');
  });
});

describe('Auth Header Guard (non-test mode)', () => {
  // Create a minimal Elysia with inline resolve that mirrors the production guard
  const guardApp = new Elysia()
    .use(errorHandler)
    .resolve(async ({ request }) => {
      const authorization = request.headers.get('authorization');
      if (!authorization?.startsWith('Bearer ')) {
        throw new AppError('UNAUTHORIZED', 'Missing or invalid authorization header', 401);
      }
      return { firebaseUser: { uid: 'unused', phone: null, email: null } };
    })
    .get('/guarded', ({ firebaseUser }) => ({ uid: firebaseUser.uid }));

  it('returns 401 when Authorization header is missing', async () => {
    const response = await guardApp.handle(new Request('http://localhost/guarded'));
    expect(response.status).toBe(401);
    const body = await response.json();
    expect(body.error.code).toBe('UNAUTHORIZED');
  });

  it('returns 401 when Authorization header does not start with Bearer', async () => {
    const response = await guardApp.handle(
      new Request('http://localhost/guarded', {
        headers: { Authorization: 'Basic abc123' },
      }),
    );
    expect(response.status).toBe(401);
    const body = await response.json();
    expect(body.error.code).toBe('UNAUTHORIZED');
  });
});
