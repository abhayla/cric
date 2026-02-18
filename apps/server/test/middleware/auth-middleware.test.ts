import { describe, expect, it } from 'bun:test';
import { Elysia } from 'elysia';
import { authMiddleware } from '../../src/middleware/auth.ts';

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
