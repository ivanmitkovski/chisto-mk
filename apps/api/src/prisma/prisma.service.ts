import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '../prisma-client';

function connectionStringWithNoVerify(url: string): string {
  const noVerify = 'sslmode=no-verify';
  if (url.includes('sslmode=')) {
    return url.replace(/sslmode=[^&]*/i, noVerify);
  }
  const sep = url.includes('?') ? '&' : '?';
  return `${url}${sep}${noVerify}`;
}

function withConnectionTimeout(url: string, seconds = 30): string {
  if (url.includes('connect_timeout=')) {
    return url;
  }
  const sep = url.includes('?') ? '&' : '?';
  return `${url}${sep}connect_timeout=${seconds}`;
}

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  constructor() {
    let connectionString = connectionStringWithNoVerify(process.env.DATABASE_URL!);
    connectionString = withConnectionTimeout(connectionString);
    const adapter = new PrismaPg({ connectionString });
    super({ adapter });
  }

  async onModuleInit() {
    await this.$connect();
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
