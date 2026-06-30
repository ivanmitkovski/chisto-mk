import { Injectable, Logger } from '@nestjs/common';
import { DevicePlatform, UserActivityEventType } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { ActiveUsersRealtimeService } from './active-users-realtime.service';
import type { ActivityFeedItem } from '../types/presence.types';
import { resolveActorIdentity } from '../../common/projections/public-identity.projection';

const FEED_MESSAGES: Partial<Record<UserActivityEventType, string>> = {
  LOGIN: 'logged in',
  LOGOUT: 'went offline',
  APP_OPENED: 'opened the app',
  SCREEN_VIEW: 'viewed',
  REPORT_CREATED: 'started a report',
  REPORT_SUBMITTED: 'submitted a report',
  EVENT_JOINED: 'joined a cleanup event',
  CHECK_IN: 'checked in to an event',
};

@Injectable()
export class UserActivityService {
  private readonly logger = new Logger(UserActivityService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly realtime: ActiveUsersRealtimeService,
  ) {}

  async recordClientEvent(
    user: AuthenticatedUser,
    opts: {
      type: UserActivityEventType;
      screen?: string | null;
      deviceId?: string;
      platform?: DevicePlatform;
      appVersion?: string | null;
      metadata?: Record<string, unknown>;
    },
  ): Promise<void> {
    await this.persistAndPublish(user.userId, {
      sessionId: user.sessionId ?? null,
      deviceId: opts.deviceId ?? null,
      type: opts.type,
      screen: opts.screen ?? null,
      platform: opts.platform ?? null,
      appVersion: opts.appVersion ?? null,
      metadata: opts.metadata ?? null,
    });
    if (opts.type === 'APP_OPENED' || opts.type === 'LOGIN') {
      void this.realtime.recordDau(user.userId);
    }
  }

  async recordSystemEvent(opts: {
    userId: string;
    type: UserActivityEventType;
    metadata?: Record<string, unknown>;
    screen?: string | null;
  }): Promise<void> {
    await this.persistAndPublish(opts.userId, {
      sessionId: null,
      deviceId: null,
      type: opts.type,
      screen: opts.screen ?? null,
      platform: null,
      appVersion: null,
      metadata: opts.metadata ?? null,
    });
    void this.realtime.recordDau(opts.userId);
  }

  async getTimeline(userId: string, limit = 50): Promise<ActivityFeedItem[]> {
    const events = await this.prisma.userActivityEvent.findMany({
      where: { userId },
      orderBy: { occurredAt: 'desc' },
      take: limit,
      include: {
        user: { select: { firstName: true, lastName: true, status: true } },
      },
    });
    return events.map((e) => this.toFeedItem(e));
  }

  async getActivityFeed(opts: {
    page: number;
    limit: number;
    type?: UserActivityEventType;
    search?: string;
  }): Promise<{ items: ActivityFeedItem[]; total: number }> {
    const where: Record<string, unknown> = {};
    if (opts.type) where.type = opts.type;
    if (opts.search?.trim()) {
      where.user = {
        OR: [
          { firstName: { contains: opts.search.trim(), mode: 'insensitive' } },
          { lastName: { contains: opts.search.trim(), mode: 'insensitive' } },
          { email: { contains: opts.search.trim(), mode: 'insensitive' } },
        ],
      };
    }
    const skip = (opts.page - 1) * opts.limit;
    const [total, events] = await Promise.all([
      this.prisma.userActivityEvent.count({ where: where as never }),
      this.prisma.userActivityEvent.findMany({
        where: where as never,
        orderBy: { occurredAt: 'desc' },
        skip,
        take: opts.limit,
        include: { user: { select: { firstName: true, lastName: true, status: true } } },
      }),
    ]);
    return { items: events.map((e) => this.toFeedItem(e)), total };
  }

  async countSessionsToday(userId: string): Promise<number> {
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    return this.prisma.userActivityEvent.count({
      where: {
        userId,
        type: { in: ['LOGIN', 'APP_OPENED'] },
        occurredAt: { gte: start },
      },
    });
  }

  async purgeOldEvents(retentionDays: number): Promise<number> {
    const cutoff = new Date(Date.now() - retentionDays * 86400000);
    const result = await this.prisma.userActivityEvent.deleteMany({
      where: { occurredAt: { lt: cutoff } },
    });
    return result.count;
  }

  private async persistAndPublish(
    userId: string,
    data: {
      sessionId: string | null;
      deviceId: string | null;
      type: UserActivityEventType;
      screen: string | null;
      platform: DevicePlatform | null;
      appVersion: string | null;
      metadata: Record<string, unknown> | null;
    },
  ): Promise<void> {
    try {
      const event = await this.prisma.userActivityEvent.create({
        data: {
          userId,
          sessionId: data.sessionId,
          deviceId: data.deviceId,
          type: data.type,
          screen: data.screen,
          ...(data.platform ? { platform: data.platform } : {}),
          appVersion: data.appVersion,
          ...(data.metadata ? { metadata: data.metadata as never } : {}),
        },
        include: { user: { select: { firstName: true, lastName: true, status: true } } },
      });
      const feedItem = this.toFeedItem(event);
      this.realtime.publishActivityEvent({ type: 'activity_event', event: feedItem });
    } catch (error) {
      this.logger.warn(`Failed to persist activity event: ${String(error)}`);
    }
  }

  private toFeedItem(event: {
    id: string;
    userId: string;
    type: UserActivityEventType;
    screen: string | null;
    occurredAt: Date;
    user: { firstName: string; lastName: string; status?: import('../../prisma-client').UserStatus };
  }): ActivityFeedItem {
    const identity = resolveActorIdentity(event.user, { actorUserId: event.userId });
    const name = identity.displayName ?? 'User';
    const verb = FEED_MESSAGES[event.type] ?? event.type.toLowerCase();
    const message =
      event.type === 'SCREEN_VIEW' && event.screen
        ? `${name} ${verb} ${event.screen}`
        : `${name} ${verb}`;
    return {
      id: event.id,
      userId: event.userId,
      displayName: name,
      type: event.type,
      screen: event.screen,
      message,
      occurredAt: event.occurredAt.toISOString(),
    };
  }
}
