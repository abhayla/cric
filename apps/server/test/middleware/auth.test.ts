import { describe, expect, it } from 'bun:test';
import { Elysia } from 'elysia';
import { errorHandler, AppError } from '../../src/middleware/error-handler.ts';

describe('Error Handler Middleware', () => {
  const app = new Elysia()
    .use(errorHandler)
    .get('/app-error', () => {
      throw new AppError('VALIDATION_ERROR', 'Test validation error', 400, {
        field: 'name',
      });
    })
    .get('/app-error-401', () => {
      throw new AppError('UNAUTHORIZED', 'Not authorized', 401);
    })
    .get('/unknown-error', () => {
      throw new Error('Something broke');
    });

  it('handles AppError with correct status and body', async () => {
    const res = await app.handle(new Request('http://localhost/app-error'));
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error.code).toBe('VALIDATION_ERROR');
    expect(body.error.message).toBe('Test validation error');
    expect(body.error.details).toEqual({ field: 'name' });
  });

  it('handles AppError with 401 status', async () => {
    const res = await app.handle(new Request('http://localhost/app-error-401'));
    expect(res.status).toBe(401);
    const body = await res.json();
    expect(body.error.code).toBe('UNAUTHORIZED');
  });

  it('handles unknown errors as 500 INTERNAL_ERROR', async () => {
    const res = await app.handle(new Request('http://localhost/unknown-error'));
    expect(res.status).toBe(500);
    const body = await res.json();
    expect(body.error.code).toBe('INTERNAL_ERROR');
    expect(body.error.message).toBe('An unexpected error occurred');
  });

  it('handles 404 for unmatched routes', async () => {
    const res = await app.handle(
      new Request('http://localhost/does-not-exist'),
    );
    expect(res.status).toBe(404);
  });
});

describe('AppError class', () => {
  it('creates with correct properties', () => {
    const err = new AppError('TEST_CODE', 'Test message', 422, {
      key: 'value',
    });
    expect(err.code).toBe('TEST_CODE');
    expect(err.message).toBe('Test message');
    expect(err.statusCode).toBe(422);
    expect(err.details).toEqual({ key: 'value' });
    expect(err.name).toBe('AppError');
  });

  it('defaults statusCode to 400', () => {
    const err = new AppError('CODE', 'msg');
    expect(err.statusCode).toBe(400);
  });
});
