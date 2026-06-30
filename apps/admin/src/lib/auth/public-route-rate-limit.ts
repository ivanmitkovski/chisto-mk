import type { NextRequest } from 'next/server';

const PUBLIC_RATE_LIMIT = 60;
const PUBLIC_RATE_WINDOW_MS = 60_000;
const MAX_EVICT_PER_SWEEP = 256;

type MemoryBucket = { count: number; resetAt: number };
const memoryBuckets = new Map<string, MemoryBucket>();

function getClientIp(request: NextRequest): string {
  const forwarded = request.headers.get('x-forwarded-for')?.split(',')[0]?.trim();
  const realIp = request.headers.get('x-real-ip')?.trim();
  return forwarded || realIp || 'local';
}

function evictExpiredBuckets(now: number): void {
  if (memoryBuckets.size <= PUBLIC_RATE_LIMIT * 4) return;
  let evicted = 0;
  for (const [key, bucket] of memoryBuckets) {
    if (bucket.resetAt <= now) {
      memoryBuckets.delete(key);
      evicted += 1;
      if (evicted >= MAX_EVICT_PER_SWEEP) break;
    }
  }
}

function memoryRateLimit(key: string): boolean {
  const now = Date.now();
  evictExpiredBuckets(now);
  const bucket = memoryBuckets.get(key);
  if (!bucket || bucket.resetAt <= now) {
    memoryBuckets.set(key, { count: 1, resetAt: now + PUBLIC_RATE_WINDOW_MS });
    return true;
  }
  bucket.count += 1;
  return bucket.count <= PUBLIC_RATE_LIMIT;
}

export function buildPublicRouteRateLimitKey(request: NextRequest, route: string): string {
  return `${route}:${getClientIp(request)}`;
}

export function checkPublicRouteRateLimit(request: NextRequest, route: string): boolean {
  const key = buildPublicRouteRateLimitKey(request, route);
  return memoryRateLimit(key);
}

export async function readRequestBodyWithCap(
  request: NextRequest,
  maxBytes: number,
): Promise<{ ok: true; text: string } | { ok: false; response: Response }> {
  const contentLength = Number.parseInt(request.headers.get('content-length') ?? '', 10);
  if (Number.isFinite(contentLength) && contentLength > maxBytes) {
    return {
      ok: false,
      response: Response.json(
        { code: 'PAYLOAD_TOO_LARGE', message: 'Request body is too large.' },
        { status: 413 },
      ),
    };
  }

  const text = await request.text();
  if (text.length > maxBytes) {
    return {
      ok: false,
      response: Response.json(
        { code: 'PAYLOAD_TOO_LARGE', message: 'Request body is too large.' },
        { status: 413 },
      ),
    };
  }

  return { ok: true, text };
}
