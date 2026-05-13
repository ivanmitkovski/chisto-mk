export interface MapConfig {
  redisUrl: string | null;
  cacheTtlMs: number;
  sseHeartbeatIntervalMs: number;
  outboxPollIntervalMs: number;
  outboxBatchSize: number;
  outboxLeaseTtlMs: number;
  replayLimit: number;
  replayWindowMinutes: number;
  mapStrictBounds: boolean;
  trustedProxyCidrs: string[];
  /** Max HTTP map requests per IP (+ optional device id) per rolling minute. */
  mapHttpRpsLimit: number;
  /** Max SSE map stream attaches per same key per rolling minute. */
  mapSseRpsLimit: number;
}

export function loadMapConfig(): MapConfig {
  const redisUrl = process.env.REDIS_URL?.trim() || null;
  return {
    redisUrl,
    cacheTtlMs: parseIntEnv('MAP_CACHE_TTL_MS', 4_000),
    sseHeartbeatIntervalMs: parseIntEnv('SSE_HEARTBEAT_INTERVAL_MS', 30_000),
    outboxPollIntervalMs: parseIntEnv('OUTBOX_POLL_INTERVAL_MS', 5_000),
    outboxBatchSize: parseIntEnv('OUTBOX_BATCH_SIZE', 120),
    outboxLeaseTtlMs: parseIntEnv('OUTBOX_LEASE_TTL_MS', 20_000),
    replayLimit: parseIntEnv('SSE_REPLAY_LIMIT', 240),
    replayWindowMinutes: parseIntEnv('SSE_REPLAY_WINDOW_MINUTES', 5),
    mapStrictBounds: process.env.MAP_STRICT_BOUNDS === 'true',
    trustedProxyCidrs: (process.env.TRUSTED_PROXY_CIDRS ?? '')
      .split(',')
      .map((v) => v.trim())
      .filter((v) => v.length > 0),
    mapHttpRpsLimit: parseIntEnv('MAP_HTTP_RPS_LIMIT', 480),
    mapSseRpsLimit: parseIntEnv('MAP_SSE_RPS_LIMIT', 120),
  };
}

function parseIntEnv(key: string, defaultValue: number): number {
  const raw = process.env[key]?.trim();
  if (!raw) return defaultValue;
  const parsed = Number.parseInt(raw, 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : defaultValue;
}
