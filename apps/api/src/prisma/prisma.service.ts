import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '../prisma-client';
import { resolveDatabaseUrl } from './resolve-database-url';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  private readonly slowQueryLogger = new Logger(PrismaService.name);

  constructor() {
    const connectionString = resolveDatabaseUrl(process.env.DATABASE_URL!);
    const adapter = new PrismaPg({ connectionString });
    super({ adapter });
  }

  async onModuleInit() {
    const nodeEnv = (process.env.NODE_ENV ?? 'development').trim().toLowerCase();
    const slowMsRaw = process.env.PRISMA_SLOW_QUERY_MS?.trim();
    const slowMsParsed = slowMsRaw != null && slowMsRaw.length > 0 ? Number(slowMsRaw) : NaN;
    const slowMs = Number.isFinite(slowMsParsed) && slowMsParsed > 0 ? slowMsParsed : 500;
    const logSlowInProd = process.env.PRISMA_LOG_SLOW_QUERIES === 'true' || process.env.PRISMA_LOG_SLOW_QUERIES === '1';
    const attachSlowListener = nodeEnv !== 'production' || logSlowInProd;
    if (attachSlowListener) {
      type QueryEvent = { duration: number; query: string };
      const client = this as unknown as { $on(event: 'query', cb: (e: QueryEvent) => void): void };
      client.$on('query', (e: QueryEvent) => {
        if (e.duration > slowMs) {
          const sql = e.query.length > 240 ? `${e.query.slice(0, 240)}…` : e.query;
          this.slowQueryLogger.warn(`Slow query ${e.duration}ms (threshold ${slowMs}ms): ${sql}`);
        }
      });
    }
    await this.$connect();
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
