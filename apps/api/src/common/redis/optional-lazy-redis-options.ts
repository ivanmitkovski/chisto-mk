import type { RedisOptions } from 'ioredis';

/** Bounded ioredis options for optional Redis clients (CI-safe: no infinite reconnect timers). */
export const optionalLazyRedisOptions: RedisOptions = {
  lazyConnect: true,
  maxRetriesPerRequest: 1,
  enableReadyCheck: false,
  connectTimeout: 3_000,
  retryStrategy: () => null,
};
