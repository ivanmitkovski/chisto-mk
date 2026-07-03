import type { MapConfig } from '../../src/config/map.config';

/** Map config with no Redis — use in unit tests so CI REDIS_URL does not open real clients. */
export const mockMapConfigNoRedis: MapConfig = {
  redisUrl: null,
  cacheTtlMs: 4_000,
  sseHeartbeatIntervalMs: 30_000,
  outboxPollIntervalMs: 5_000,
  outboxBatchSize: 120,
  outboxLeaseTtlMs: 20_000,
  replayLimit: 240,
  replayWindowMinutes: 5,
  mapStrictBounds: false,
  trustedProxyCidrs: [],
  mapHttpRpsLimit: 480,
  mapSseRpsLimit: 120,
};
