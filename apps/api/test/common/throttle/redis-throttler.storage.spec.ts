import { RedisThrottlerStorage } from '../../../src/common/throttle/redis-throttler.storage';

describe('RedisThrottlerStorage', () => {
  const originalEnv = process.env;

  beforeEach(() => {
    jest.resetModules();
    process.env = { ...originalEnv, NODE_ENV: 'test', REDIS_URL: 'redis://127.0.0.1:6379' };
  });

  afterEach(() => {
    process.env = originalEnv;
  });

  it('increment does not throw after onModuleDestroy in test env', async () => {
    const storage = new RedisThrottlerStorage();
    await storage.onModuleDestroy();

    await expect(
      storage.increment('ip-1', 60_000, 5, 0, 'default'),
    ).resolves.toEqual({
      totalHits: 1,
      timeToExpire: 60_000,
      isBlocked: false,
      timeToBlockExpire: 0,
    });
  });

  it('falls back to in-memory behavior when REDIS_URL is unset in test env', async () => {
    delete process.env.REDIS_URL;
    const storage = new RedisThrottlerStorage();

    await expect(
      storage.increment('ip-2', 60_000, 5, 0, 'default'),
    ).resolves.toEqual({
      totalHits: 1,
      timeToExpire: 60_000,
      isBlocked: false,
      timeToBlockExpire: 0,
    });
  });
});
