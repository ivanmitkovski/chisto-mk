import { Injectable, Logger, NotFoundException, OnModuleDestroy } from '@nestjs/common';
import Redis from 'ioredis';
import { ReportPresenceEventsService } from '../../admin-realtime/services/report-presence-events.service';
import { ReportViewerPresenceEntry } from '../../admin-realtime/types/report-presence-events.types';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { PrismaService } from '../../prisma/prisma.service';

type MemoryEntry = ReportViewerPresenceEntry & { expiresAt: number };

const PRESENCE_TTL_MS = 45_000;
const SSE_DEBOUNCE_MS = 300;

@Injectable()
export class ReportViewerPresenceService implements OnModuleDestroy {
  private static zsetKey(reportId: string): string {
    return `admin:report-viewers:${reportId}`;
  }

  private static metaKey(reportId: string): string {
    return `admin:report-viewer-meta:${reportId}`;
  }

  private readonly logger = new Logger(ReportViewerPresenceService.name);
  private readonly redisUrl = process.env.REDIS_URL?.trim() || null;
  private readonly redis: Redis | null;
  private readonly memoryByReport = new Map<string, Map<string, MemoryEntry>>();
  private readonly publishTimers = new Map<string, ReturnType<typeof setTimeout>>();

  constructor(
    private readonly prisma: PrismaService,
    private readonly presenceEvents: ReportPresenceEventsService,
  ) {
    this.redis = this.redisUrl
      ? new Redis(this.redisUrl, { maxRetriesPerRequest: 1, lazyConnect: true })
      : null;
    if (!this.redisUrl) {
      this.logger.log('Report viewer presence using in-memory store (REDIS_URL unset)');
    }
  }

  async heartbeat(
    reportId: string,
    user: AuthenticatedUser,
    dto: { sessionId: string; displayName: string },
  ): Promise<ReportViewerPresenceEntry[]> {
    await this.assertReportExists(reportId);
    const displayName = dto.displayName.trim() || user.email;
    const entry: ReportViewerPresenceEntry = {
      sessionId: dto.sessionId,
      userId: user.userId,
      displayName,
    };

    if (this.redis) {
      await this.upsertRedis(reportId, entry);
    } else {
      this.upsertMemory(reportId, entry);
    }

    const viewers = await this.list(reportId);
    this.schedulePublish(reportId, viewers);
    return viewers;
  }

  async leave(reportId: string, sessionId: string, userId: string): Promise<ReportViewerPresenceEntry[]> {
    if (this.redis) {
      const metaRaw = await this.redis.hget(ReportViewerPresenceService.metaKey(reportId), sessionId);
      if (metaRaw) {
        const meta = JSON.parse(metaRaw) as { userId: string };
        if (meta.userId !== userId) {
          return this.list(reportId);
        }
      }
      await this.redis
        .multi()
        .zrem(ReportViewerPresenceService.zsetKey(reportId), sessionId)
        .hdel(ReportViewerPresenceService.metaKey(reportId), sessionId)
        .exec();
    } else {
      const reportSessions = this.memoryByReport.get(reportId);
      const existing = reportSessions?.get(sessionId);
      if (existing && existing.userId !== userId) {
        return this.list(reportId);
      }
      reportSessions?.delete(sessionId);
      if (reportSessions?.size === 0) {
        this.memoryByReport.delete(reportId);
      }
    }

    const viewers = await this.list(reportId);
    this.schedulePublish(reportId, viewers);
    return viewers;
  }

  async list(reportId: string): Promise<ReportViewerPresenceEntry[]> {
    if (this.redis) {
      return this.listRedis(reportId);
    }
    return this.listMemory(reportId);
  }

  private async assertReportExists(reportId: string): Promise<void> {
    const report = await this.prisma.report.findUnique({
      where: { id: reportId },
      select: { id: true },
    });
    if (!report) {
      throw new NotFoundException({
        code: 'REPORT_NOT_FOUND',
        message: 'Report not found',
      });
    }
  }

  private upsertMemory(reportId: string, entry: ReportViewerPresenceEntry): void {
    let sessions = this.memoryByReport.get(reportId);
    if (!sessions) {
      sessions = new Map();
      this.memoryByReport.set(reportId, sessions);
    }
    sessions.set(entry.sessionId, {
      ...entry,
      expiresAt: Date.now() + PRESENCE_TTL_MS,
    });
  }

  private listMemory(reportId: string): ReportViewerPresenceEntry[] {
    const now = Date.now();
    const sessions = this.memoryByReport.get(reportId);
    if (!sessions) return [];

    const viewers: ReportViewerPresenceEntry[] = [];
    for (const [sessionId, entry] of sessions) {
      if (entry.expiresAt <= now) {
        sessions.delete(sessionId);
        continue;
      }
      viewers.push({
        sessionId: entry.sessionId,
        userId: entry.userId,
        displayName: entry.displayName,
      });
    }

    if (sessions.size === 0) {
      this.memoryByReport.delete(reportId);
    }

    return viewers;
  }

  private async upsertRedis(reportId: string, entry: ReportViewerPresenceEntry): Promise<void> {
    const now = Date.now();
    const expiresAt = now + PRESENCE_TTL_MS;
    const zsetKey = ReportViewerPresenceService.zsetKey(reportId);
    const metaKey = ReportViewerPresenceService.metaKey(reportId);

    await this.redis!
      .multi()
      .zadd(zsetKey, expiresAt, entry.sessionId)
      .hset(metaKey, entry.sessionId, JSON.stringify({ userId: entry.userId, displayName: entry.displayName }))
      .zremrangebyscore(zsetKey, '-inf', now)
      .exec();
  }

  private async listRedis(reportId: string): Promise<ReportViewerPresenceEntry[]> {
    const now = Date.now();
    const zsetKey = ReportViewerPresenceService.zsetKey(reportId);
    const metaKey = ReportViewerPresenceService.metaKey(reportId);

    await this.redis!.zremrangebyscore(zsetKey, '-inf', now);
    const sessionIds = await this.redis!.zrangebyscore(zsetKey, now, '+inf');
    if (sessionIds.length === 0) {
      return [];
    }

    const metaValues = await this.redis!.hmget(metaKey, ...sessionIds);
    const viewers: ReportViewerPresenceEntry[] = [];
    const staleSessionIds: string[] = [];

    for (let i = 0; i < sessionIds.length; i += 1) {
      const sessionId = sessionIds[i];
      const raw = metaValues[i];
      if (!raw) {
        staleSessionIds.push(sessionId);
        continue;
      }
      try {
        const meta = JSON.parse(raw) as { userId: string; displayName: string };
        viewers.push({
          sessionId,
          userId: meta.userId,
          displayName: meta.displayName,
        });
      } catch {
        staleSessionIds.push(sessionId);
      }
    }

    if (staleSessionIds.length > 0) {
      await this.redis!
        .multi()
        .zrem(zsetKey, ...staleSessionIds)
        .hdel(metaKey, ...staleSessionIds)
        .exec();
    }

    return viewers;
  }

  private schedulePublish(reportId: string, viewers: ReportViewerPresenceEntry[]): void {
    const existing = this.publishTimers.get(reportId);
    if (existing) {
      clearTimeout(existing);
    }

    const timer = setTimeout(() => {
      this.publishTimers.delete(reportId);
      this.presenceEvents.publish({
        type: 'report_viewers_updated',
        reportId,
        viewers,
      });
    }, SSE_DEBOUNCE_MS);

    this.publishTimers.set(reportId, timer);
  }

  async onModuleDestroy(): Promise<void> {
    await this.redis?.quit().catch(() => undefined);
  }
}
