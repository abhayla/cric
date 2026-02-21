import { describe, expect, it, beforeAll, afterAll } from 'bun:test';
import { Elysia } from 'elysia';
import { rmdir } from 'fs/promises';
import sharp from 'sharp';
import { uploadRoutes } from '../../src/routes/v1/uploads.ts';
import { errorHandler } from '../../src/middleware/error-handler.ts';
import { env } from '../../src/config/env.ts';

const app = new Elysia().use(errorHandler).use(uploadRoutes);

const BASE = 'http://localhost/api/v1';

// Generate valid test images using sharp
let jpegBuffer: Buffer;
let pngBuffer: Buffer;

beforeAll(async () => {
  jpegBuffer = await sharp({
    create: { width: 10, height: 10, channels: 3, background: { r: 255, g: 0, b: 0 } },
  }).jpeg().toBuffer();

  pngBuffer = await sharp({
    create: { width: 10, height: 10, channels: 3, background: { r: 0, g: 255, b: 0 } },
  }).png().toBuffer();
});

function makeJpegBlob(): Blob {
  return new Blob([jpegBuffer], { type: 'image/jpeg' });
}

function makePngBlob(): Blob {
  return new Blob([pngBuffer], { type: 'image/png' });
}

// Clean up uploads dir after tests
afterAll(async () => {
  try {
    await rmdir(`${env.UPLOADS_DIR}`, { recursive: true });
  } catch {
    // Ignore
  }
});

describe('POST /api/v1/uploads/image', () => {
  it('returns 200 and URL for valid JPEG upload', async () => {
    const form = new FormData();
    form.append('image', makeJpegBlob(), 'test.jpg');

    const res = await app.handle(
      new Request(`${BASE}/uploads/image`, { method: 'POST', body: form }),
    );

    expect(res.status).toBe(200);
    const data = await res.json();
    expect(data.url).toMatch(/^\/uploads\/[a-f0-9-]+\.jpg$/);
  });

  it('returns 200 for valid PNG upload', async () => {
    const form = new FormData();
    form.append('image', makePngBlob(), 'test.png');

    const res = await app.handle(
      new Request(`${BASE}/uploads/image`, { method: 'POST', body: form }),
    );

    expect(res.status).toBe(200);
    const data = await res.json();
    expect(data.url).toMatch(/^\/uploads\/[a-f0-9-]+\.jpg$/);
  });

  it('returns 400 for invalid file type', async () => {
    const form = new FormData();
    form.append('image', new Blob(['not an image'], { type: 'text/plain' }), 'test.txt');

    const res = await app.handle(
      new Request(`${BASE}/uploads/image`, { method: 'POST', body: form }),
    );

    expect(res.status).toBe(400);
    const data = await res.json();
    expect(data.error.message).toContain('Invalid image type');
  });

  it('returns 400 for oversize image', async () => {
    // Create a blob larger than MAX_UPLOAD_SIZE_MB
    const oversizeData = new Uint8Array((env.MAX_UPLOAD_SIZE_MB + 1) * 1024 * 1024);
    const form = new FormData();
    form.append(
      'image',
      new Blob([oversizeData], { type: 'image/jpeg' }),
      'big.jpg',
    );

    const res = await app.handle(
      new Request(`${BASE}/uploads/image`, { method: 'POST', body: form }),
    );

    expect(res.status).toBe(400);
    const data = await res.json();
    expect(data.error.message).toContain('too large');
  });
});

describe('GET /api/v1/uploads/:filename', () => {
  it('serves an uploaded file', async () => {
    // First upload
    const form = new FormData();
    form.append('image', makeJpegBlob(), 'serve-test.jpg');

    const uploadRes = await app.handle(
      new Request(`${BASE}/uploads/image`, { method: 'POST', body: form }),
    );
    const { url } = await uploadRes.json();
    const filename = url.split('/').pop();

    // Then fetch
    const res = await app.handle(
      new Request(`${BASE}/uploads/${filename}`),
    );

    expect(res.status).toBe(200);
    expect(res.headers.get('content-type')).toBe('image/jpeg');
  });

  it('returns 404 for missing file', async () => {
    const res = await app.handle(
      new Request(`${BASE}/uploads/nonexistent.jpg`),
    );

    expect(res.status).toBe(404);
  });

  it('rejects path traversal', async () => {
    const res = await app.handle(
      new Request(`${BASE}/uploads/..%2Fpackage.json`),
    );

    expect(res.status).toBe(400);
  });
});
