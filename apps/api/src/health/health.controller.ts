import { HeadBucketCommand } from '@aws-sdk/client-s3';
import { Controller, Get, ServiceUnavailableException } from '@nestjs/common';
import Redis from 'ioredis';
import { PrismaService } from '../prisma/prisma.service';
import { S3StorageClient } from '../storage/s3-storage.client';

@Controller('health')
export class HealthController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly s3: S3StorageClient,
  ) {}

  @Get()
  liveness(): { status: string } {
    return { status: 'ok' };
  }

  @Get('live')
  live(): { status: string } {
    return { status: 'ok' };
  }

  @Get('ready')
  async readiness(): Promise<{ status: string; redis?: string; s3?: string }> {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
    } catch {
      throw new ServiceUnavailableException('Database unavailable');
    }

    let redis: string | undefined;
    const redisUrl = process.env.REDIS_URL?.trim();
    if (redisUrl) {
      const client = new Redis(redisUrl, { maxRetriesPerRequest: 1, enableReadyCheck: true });
      try {
        await client.ping();
        redis = 'ok';
      } catch {
        throw new ServiceUnavailableException('Redis unavailable');
      } finally {
        await client.quit();
      }
    } else {
      redis = 'skipped';
    }

    let s3: string | undefined;
    const client = this.s3.getClientOrNull();
    if (!this.s3.enabled || !this.s3.bucket || !client) {
      s3 = 'skipped';
    } else {
      try {
        await client.send(new HeadBucketCommand({ Bucket: this.s3.bucket }));
        s3 = 'ok';
      } catch {
        throw new ServiceUnavailableException('S3 unavailable');
      }
    }

    return { status: 'ok', redis, s3 };
  }
}
