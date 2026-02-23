import { Elysia } from 'elysia';

interface RequestEntry {
  timestamps: number[];
}

const AUTH_LIMIT = 10; // 10 req/min
const SCORING_LIMIT = 60; // 60 req/min
const WINDOW_MS = 60_000; // 1 minute

const authBucket = new Map<string, RequestEntry>();
const scoringBucket = new Map<string, RequestEntry>();

function cleanupBucket(bucket: Map<string, RequestEntry>) {
  const now = Date.now();
  for (const [key, entry] of bucket) {
    entry.timestamps = entry.timestamps.filter((t) => now - t < WINDOW_MS);
    if (entry.timestamps.length === 0) {
      bucket.delete(key);
    }
  }
}

// Periodic cleanup of expired entries
setInterval(() => {
  cleanupBucket(authBucket);
  cleanupBucket(scoringBucket);
}, 60_000);

function isRateLimited(
  bucket: Map<string, RequestEntry>,
  ip: string,
  limit: number,
): boolean {
  const now = Date.now();
  const entry = bucket.get(ip);

  if (!entry) {
    bucket.set(ip, { timestamps: [now] });
    return false;
  }

  // Remove timestamps outside the window
  entry.timestamps = entry.timestamps.filter((t) => now - t < WINDOW_MS);
  entry.timestamps.push(now);

  return entry.timestamps.length > limit;
}

export const rateLimiter = new Elysia({ name: 'rate-limiter' }).onRequest(
  ({ set, request }) => {
    const url = new URL(request.url);
    const pathname = url.pathname;

    // Determine which bucket and limit to use
    let bucket: Map<string, RequestEntry> | null = null;
    let limit = 0;

    if (pathname.startsWith('/api/v1/auth/')) {
      bucket = authBucket;
      limit = AUTH_LIMIT;
    } else if (pathname.startsWith('/api/v1/matches/')) {
      bucket = scoringBucket;
      limit = SCORING_LIMIT;
    }

    if (!bucket) return;

    // Extract IP from request headers or server
    const ip =
      request.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ||
      request.headers.get('x-real-ip') ||
      'unknown';

    if (isRateLimited(bucket, ip, limit)) {
      set.status = 429;
      set.headers['Content-Type'] = 'application/json';
      return JSON.stringify({
        error: 'Rate limit exceeded. Try again later.',
      });
    }
  },
);
