/**
 * Optional testcontainers bootstrap for e2e when E2E_USE_TESTCONTAINERS=1 and Docker is available.
 * CI uses service containers (Postgres/Redis) via DATABASE_URL / REDIS_URL instead.
 */
import { PostgreSqlContainer, type StartedPostgreSqlContainer } from '@testcontainers/postgresql';
import { RedisContainer, type StartedRedisContainer } from '@testcontainers/redis';
import { execSync } from 'node:child_process';
import path from 'node:path';

export type TestcontainersEnv = {
  databaseUrl: string;
  redisUrl: string;
};

let pg: StartedPostgreSqlContainer | null = null;
let redis: StartedRedisContainer | null = null;

export async function startTestcontainers(): Promise<TestcontainersEnv> {
  pg = await new PostgreSqlContainer('postgres:16-alpine').start();
  redis = await new RedisContainer('redis:7-alpine').start();
  const databaseUrl = pg.getConnectionUri();
  const redisUrl = `redis://${redis.getHost()}:${redis.getFirstMappedPort()}`;

  process.env.DATABASE_URL = databaseUrl;
  process.env.REDIS_URL = redisUrl;
  process.env.NODE_ENV = 'test';
  process.env.JWT_SECRET = process.env.JWT_SECRET ?? 'test_jwt_secret_must_be_at_least_32_chars_long';
  process.env.SKIP_MIGRATE_STATUS_CHECK = '1';

  const apiRoot = path.resolve(__dirname, '../..');
  execSync('pnpm exec prisma migrate deploy', {
    cwd: apiRoot,
    env: { ...process.env, DATABASE_URL: databaseUrl },
    stdio: 'inherit',
  });

  return { databaseUrl, redisUrl };
}

export async function stopTestcontainers(): Promise<void> {
  await Promise.all([pg?.stop(), redis?.stop()]);
  pg = null;
  redis = null;
}
