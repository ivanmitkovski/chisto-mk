import { Injectable, Logger } from '@nestjs/common';
import { HeadBucketCommand } from '@aws-sdk/client-s3';
import Redis from 'ioredis';
import { ObservabilityStore } from '../../observability/observability.store';
import { WorkerHeartbeatRegistry } from '../../observability/worker-heartbeat.registry';
import { FcmPushService } from '../../notifications/services/fcm-push.service';
import { PrismaService } from '../../prisma/prisma.service';
import { S3StorageClient } from '../../storage/util/s3-storage.client';
import { OperationsMetricsSnapshotDto } from '../dto/operations-metrics-snapshot.dto';
import { OperationsReadinessDto } from '../dto/operations-readiness.dto';
import { SystemInfoDto } from '../dto/system-info.dto';
import { WorkerStatusListDto } from '../dto/worker-status.dto';

const PROCESS_STARTED_AT = new Date().toISOString();

@Injectable()
export class OperationsStatusService {
  private readonly logger = new Logger(OperationsStatusService.name);
  private healthRedis: Redis | null = null;

  constructor(
    private readonly fcmPush: FcmPushService,
    private readonly prisma: PrismaService,
    private readonly s3: S3StorageClient,
  ) {}

  getSystemInfo(): SystemInfoDto {
    const gitSha =
      process.env.GIT_SHA?.trim() ||
      process.env.SENTRY_RELEASE?.trim() ||
      null;
    return {
      version: process.env.APP_VERSION?.trim() || process.env.npm_package_version || '0.0.0',
      gitSha,
      nodeEnv: (process.env.NODE_ENV ?? 'development').trim(),
      region: process.env.AWS_REGION?.trim() || null,
      startedAt: PROCESS_STARTED_AT,
      uptimeSeconds: Math.floor(process.uptime()),
      fcmEnabled: this.fcmPush.isEnabled(),
    };
  }

  getMetricsSnapshot(): OperationsMetricsSnapshotDto {
    const snap = ObservabilityStore.snapshot();
    const memory = process.memoryUsage();
    return {
      requestsTotal: snap.requestsTotal,
      requestsFailed: snap.requestsFailed,
      p50Ms: snap.p50Ms,
      p95Ms: snap.p95Ms,
      p99Ms: snap.p99Ms,
      pushSendsTotal: snap.pushSendsTotal,
      pushSendsSuccess: snap.pushSendsSuccess,
      pushSendsFailure: snap.pushSendsFailure,
      pushSendsRevoked: snap.pushSendsRevoked,
      pushQueueDepth: snap.pushQueueDepth,
      pushActiveLeases: snap.pushActiveLeases,
      pushDeadLetterCount: snap.pushDeadLetterCount,
      mapRequestsTotal: snap.mapRequestsTotal,
      mapCacheHitRate: snap.mapCacheHitRate,
      mapOutboxPending: snap.mapOutboxPending,
      mapOutboxFailed: snap.mapOutboxFailed,
      feedRequestsTotal: snap.feedRequestsTotal,
      feedCacheHitRate: snap.feedCacheHitRate,
      reportSideEffectFailedTotal: snap.reportSideEffectFailedTotal,
      emailQueueDepth: snap.emailQueueDepth,
      emailDeadLetterCount: snap.emailDeadLetterCount,
      processMemory: {
        rssMb: Math.round(memory.rss / 1024 / 1024),
        heapUsedMb: Math.round(memory.heapUsed / 1024 / 1024),
        heapTotalMb: Math.round(memory.heapTotal / 1024 / 1024),
      },
      capturedAt: new Date().toISOString(),
    };
  }

  getWorkers(): WorkerStatusListDto {
    return {
      workers: WorkerHeartbeatRegistry.snapshot(),
      perReplica: true,
    };
  }

  async getReadiness(): Promise<OperationsReadinessDto> {
    let database: 'ok' | 'fail' = 'ok';
    try {
      await this.prisma.$queryRaw`SELECT 1`;
    } catch (err) {
      this.logger.warn({ err }, 'operations readiness: database check failed');
      database = 'fail';
    }

    let redis = 'skipped';
    const redisClient = this.getHealthRedis();
    if (redisClient) {
      try {
        if (redisClient.status !== 'ready') {
          await redisClient.connect().catch(() => undefined);
        }
        await redisClient.ping();
        redis = 'ok';
      } catch {
        redis = 'fail';
      }
    }

    let s3Status = 'skipped';
    const client = this.s3.getClientOrNull();
    if (this.s3.enabled && this.s3.bucket && client) {
      try {
        await client.send(new HeadBucketCommand({ Bucket: this.s3.bucket }));
        s3Status = 'ok';
      } catch {
        s3Status = 'fail';
      }
    }

    const degraded =
      database === 'fail' ||
      redis === 'fail' ||
      s3Status === 'fail';

    return {
      status: degraded ? 'degraded' : 'ok',
      database,
      redis,
      s3: s3Status,
    };
  }

  private getHealthRedis(): Redis | null {
    const redisUrl = process.env.REDIS_URL?.trim();
    if (!redisUrl) return null;
    if (!this.healthRedis || this.healthRedis.status === 'end') {
      this.healthRedis = new Redis(redisUrl, {
        maxRetriesPerRequest: 1,
        enableReadyCheck: false,
        lazyConnect: true,
        connectTimeout: 3_000,
      });
    }
    return this.healthRedis;
  }
}
