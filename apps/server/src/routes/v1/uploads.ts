import { Elysia, t } from 'elysia';
import { randomUUID } from 'crypto';
import { mkdir } from 'fs/promises';
import sharp from 'sharp';
import { authMiddleware } from '../../middleware/auth.ts';
import { env } from '../../config/env.ts';

const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const MAX_SIZE = env.MAX_UPLOAD_SIZE_MB * 1024 * 1024;

export const uploadRoutes = new Elysia({ prefix: '/api/v1' })
  .use(authMiddleware)
  .post(
    '/uploads/image',
    async (ctx) => {
      const { image } = ctx.body;

      // Validate type
      if (!ALLOWED_TYPES.includes(image.type)) {
        ctx.set.status = 400;
        return { error: { message: 'Invalid image type. Allowed: JPEG, PNG, WebP' } };
      }

      // Validate size
      if (image.size > MAX_SIZE) {
        ctx.set.status = 400;
        return { error: { message: `Image too large. Max ${env.MAX_UPLOAD_SIZE_MB}MB` } };
      }

      // Ensure uploads directory exists
      await mkdir(env.UPLOADS_DIR, { recursive: true });

      // Process image: resize to 200x200 cover, JPEG quality 80
      const buffer = await image.arrayBuffer();
      const processed = await sharp(Buffer.from(buffer))
        .resize(200, 200, { fit: 'cover' })
        .jpeg({ quality: 80 })
        .toBuffer();

      const filename = `${randomUUID()}.jpg`;
      const filepath = `${env.UPLOADS_DIR}/${filename}`;
      await Bun.write(filepath, processed);

      return { url: `/uploads/${filename}` };
    },
    {
      body: t.Object({
        image: t.File(),
      }),
    },
  )
  // Static file serving for uploads
  .get('/uploads/:filename', async (ctx) => {
    const { filename } = ctx.params;

    // Prevent path traversal
    if (filename.includes('..') || filename.includes('/') || filename.includes('\\')) {
      ctx.set.status = 400;
      return { error: { message: 'Invalid filename' } };
    }

    const filepath = `${env.UPLOADS_DIR}/${filename}`;
    const file = Bun.file(filepath);

    if (!(await file.exists())) {
      ctx.set.status = 404;
      return { error: { message: 'File not found' } };
    }

    ctx.set.headers['content-type'] = 'image/jpeg';
    ctx.set.headers['cache-control'] = 'public, max-age=31536000';
    return file;
  });
