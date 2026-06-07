import type { NextRequest } from 'next/server';

const MUTATION_RATE_LIMIT = 120;
const MUTATION_RATE_WINDOW_SEC = 60;
const MAX_EVICT_PER_SWEEP = 256;

type MemoryBucket = { count: number; resetAt: number };
const memoryBuckets = new Map<string, MemoryBucket>();

function evictExpiredBuckets(now: number): void {
  if (memoryBuckets.size <= MUTATION_RATE_LIMIT * 4) return;
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
    memoryBuckets.set(key, { count: 1, resetAt: now + MUTATION_RATE_WINDOW_SEC * 1000 });
    return true;
  }
  bucket.count += 1;
  return bucket.count <= MUTATION_RATE_LIMIT;
}

async function redisRateLimit(key: string): Promise<boolean | null> {
  const baseUrl = process.env.UPSTASH_REDIS_REST_URL ?? process.env.REDIS_REST_URL;
  const token = process.env.UPSTASH_REDIS_REST_TOKEN ?? process.env.REDIS_REST_TOKEN;
  if (!baseUrl || !token) return null;

  const safeKey = encodeURIComponent(`admin:mutation:${key}`);
  try {
    const incrRes = await fetch(`${baseUrl}/incr/${safeKey}`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
      cache: 'no-store',
    });
    if (!incrRes.ok) return null;
    const incrBody = (await incrRes.json()) as { result?: number };
    const count = incrBody.result ?? 0;
    if (count === 1) {
      await fetch(`${baseUrl}/expire/${safeKey}/${MUTATION_RATE_WINDOW_SEC}`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` },
        cache: 'no-store',
      }).catch(() => undefined);
    }
    return count <= MUTATION_RATE_LIMIT;
  } catch {
    return null;
  }
}

export function buildMutationRateLimitKey(request: NextRequest, accessToken: string | null): string {
  const forwarded = request.headers.get('x-forwarded-for')?.split(',')[0]?.trim();
  return `${forwarded || 'local'}:${accessToken ?? 'anon'}`;
}

export async function checkMutationRateLimit(
  request: NextRequest,
  accessToken: string | null,
): Promise<boolean> {
  const method = request.method.toUpperCase();
  if (method === 'GET' || method === 'HEAD' || method === 'OPTIONS') return true;

  const key = buildMutationRateLimitKey(request, accessToken);
  const redisResult = await redisRateLimit(key);
  if (redisResult !== null) return redisResult;
  return memoryRateLimit(key);
}
