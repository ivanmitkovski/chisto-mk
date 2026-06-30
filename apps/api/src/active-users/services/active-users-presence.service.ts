import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import { DevicePlatform } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { ReportsUploadService } from '../../reports/services/reports-upload.service';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { PRESENCE_CONFIG, presenceMemberKey } from '../config/presence.config';
import type { ActiveUserRow, PresenceAppState, PresenceMeta, PresenceStatus } from '../types/presence.types';
import { ActiveUsersRealtimeService } from './active-users-realtime.service';
import { PresenceStoreService } from './presence-store.service';
import { UserActivityService } from './user-activity.service';

export type HeartbeatInput = {
  screen: string;
  appState: PresenceAppState;
  platform: DevicePlatform;
  appVersion?: string | null;
  deviceModel?: string | null;
  osVersion?: string | null;
  deviceId: string;
};

@Injectable()
export class ActiveUsersPresenceService implements OnModuleDestroy {
  private readonly logger = new Logger(ActiveUsersPresenceService.name);
  private readonly lastDbWriteByUser = new Map<string, number>();
  private readonly lastScreenByMember = new Map<string, string>();
  private publishTimer: ReturnType<typeof setTimeout> | null = null;

  constructor(
    private readonly prisma: PrismaService,
    private readonly realtime: ActiveUsersRealtimeService,
    private readonly activity: UserActivityService,
    private readonly store: PresenceStoreService,
    private readonly reportsUploadService: ReportsUploadService,
  ) {}

  onModuleDestroy(): void {
    if (this.publishTimer) clearTimeout(this.publishTimer);
  }

  async heartbeat(user: AuthenticatedUser, input: HeartbeatInput): Promise<void> {
    const now = Date.now();
    const member = presenceMemberKey(user.userId, input.deviceId);
    const existing = await this.store.getMeta(member);
    const sessionStart = existing?.sessionStart ?? new Date(now).toISOString();
    const meta: PresenceMeta = {
      userId: user.userId,
      deviceId: input.deviceId,
      sessionId: user.sessionId ?? null,
      screen: input.screen.trim() || 'Unknown',
      platform: input.platform,
      appVersion: input.appVersion?.trim() || null,
      deviceModel: input.deviceModel?.trim() || null,
      osVersion: input.osVersion?.trim() || null,
      sessionStart,
      appState: input.appState,
      country: existing?.country ?? null,
      city: existing?.city ?? null,
      lastActivityAt: new Date(now).toISOString(),
    };

    await this.store.upsert(member, meta, now);

    const prevScreen = this.lastScreenByMember.get(member);
    if (prevScreen !== meta.screen && input.appState === 'foreground') {
      this.lastScreenByMember.set(member, meta.screen);
      void this.activity.recordClientEvent(user, {
        type: 'SCREEN_VIEW',
        screen: meta.screen,
        deviceId: input.deviceId,
        platform: input.platform,
        appVersion: meta.appVersion,
      });
    }

    void this.debouncedDbTouch(user.userId, user.sessionId ?? null, meta);
    this.schedulePublish();
  }

  async offline(user: AuthenticatedUser, deviceId: string): Promise<void> {
    const member = presenceMemberKey(user.userId, deviceId);
    const existing = await this.store.getMeta(member);
    await this.store.remove(member);
    this.lastScreenByMember.delete(member);
    const knownPlatform = Object.values(DevicePlatform).find((p) => p === existing?.platform);
    void this.activity.recordClientEvent(user, {
      type: 'LOGOUT',
      deviceId,
      platform: knownPlatform ?? DevicePlatform.ANDROID,
    });
    this.schedulePublish();
  }

  async countDistinctActive(): Promise<number> {
    const entries = await this.store.listActiveMeta();
    const userIds = new Set(entries.map((e) => e.userId));
    return userIds.size;
  }

  async countByStatus(): Promise<{ online: number; away: number; total: number }> {
    const entries = await this.store.listActiveMeta();
    const byUser = new Map<string, PresenceStatus>();
    const now = Date.now();
    for (const meta of entries) {
      const status = this.resolveStatus(meta, now);
      const prev = byUser.get(meta.userId);
      if (!prev || status === 'online' || (prev === 'away' && status === 'away')) {
        byUser.set(meta.userId, status === 'online' ? 'online' : prev === 'online' ? 'online' : status);
      }
      if (status === 'online') byUser.set(meta.userId, 'online');
    }
    let online = 0;
    let away = 0;
    for (const s of byUser.values()) {
      if (s === 'online') online += 1;
      else if (s === 'away') away += 1;
    }
    return { online, away, total: byUser.size };
  }

  async listActiveRows(opts?: {
    status?: PresenceStatus;
    platform?: DevicePlatform;
    search?: string;
    skip?: number;
    take?: number;
  }): Promise<{ rows: ActiveUserRow[]; total: number }> {
    const metas = await this.store.listActiveMeta();
    const now = Date.now();
    const userIds = [...new Set(metas.map((m) => m.userId))];
    const users =
      userIds.length > 0
        ? await this.prisma.user.findMany({
            where: { id: { in: userIds } },
            select: {
              id: true,
              firstName: true,
              lastName: true,
              email: true,
              role: true,
              avatarObjectKey: true,
            },
          })
        : [];
    const userById = new Map(users.map((u) => [u.id, u]));
    const avatarUrlByUserId = new Map<string, string | null>();
    await Promise.all(
      users.map(async (u) => {
        const url = await this.reportsUploadService.signPrivateObjectKey(u.avatarObjectKey);
        avatarUrlByUserId.set(u.id, url);
      }),
    );

    let rows: ActiveUserRow[] = metas.map((meta) => {
      const u = userById.get(meta.userId);
      const sessionStart = new Date(meta.sessionStart).getTime();
      return {
        id: presenceMemberKey(meta.userId, meta.deviceId),
        userId: meta.userId,
        deviceId: meta.deviceId,
        firstName: u?.firstName ?? '',
        lastName: u?.lastName ?? '',
        email: u?.email ?? '',
        avatarUrl: avatarUrlByUserId.get(meta.userId) ?? null,
        status: this.resolveStatus(meta, now),
        currentScreen: meta.screen,
        platform: String(meta.platform),
        appVersion: meta.appVersion,
        lastActivity: meta.lastActivityAt,
        sessionDurationSeconds: Math.max(0, Math.floor((now - sessionStart) / 1000)),
        deviceModel: meta.deviceModel,
        country: meta.country,
        city: meta.city,
        role: u?.role ?? 'USER',
      };
    });

    if (opts?.status) rows = rows.filter((r) => r.status === opts.status);
    if (opts?.platform) rows = rows.filter((r) => r.platform === opts.platform);
    if (opts?.search?.trim()) {
      const q = opts.search.trim().toLowerCase();
      rows = rows.filter(
        (r) =>
          r.email.toLowerCase().includes(q) ||
          `${r.firstName} ${r.lastName}`.toLowerCase().includes(q),
      );
    }
    rows.sort((a, b) => b.lastActivity.localeCompare(a.lastActivity));
    const total = rows.length;
    const skip = opts?.skip ?? 0;
    const take = opts?.take ?? 50;
    return { rows: rows.slice(skip, skip + take), total };
  }

  async getGeoClusters(): Promise<Array<{ country: string | null; city: string | null; count: number }>> {
    const metas = await this.store.listActiveMeta();
    const clusters = new Map<string, { country: string | null; city: string | null; count: number }>();
    const seenUsers = new Set<string>();
    for (const meta of metas) {
      if (seenUsers.has(meta.userId)) continue;
      seenUsers.add(meta.userId);
      const key = `${meta.country ?? ''}|${meta.city ?? ''}`;
      const prev = clusters.get(key);
      if (prev) prev.count += 1;
      else clusters.set(key, { country: meta.country, city: meta.city, count: 1 });
    }
    return [...clusters.values()].sort((a, b) => b.count - a.count);
  }

  resolveStatus(meta: PresenceMeta, nowMs: number): PresenceStatus {
    const lastAt = new Date(meta.lastActivityAt).getTime();
    if (nowMs - lastAt > PRESENCE_CONFIG.ttlMs) return 'offline';
    if (meta.appState === 'background') return 'away';
    if (nowMs - lastAt <= PRESENCE_CONFIG.onlineWindowMs) return 'online';
    return 'away';
  }

  private async debouncedDbTouch(userId: string, sessionId: string | null, meta: PresenceMeta): Promise<void> {
    const now = Date.now();
    const last = this.lastDbWriteByUser.get(userId) ?? 0;
    if (now - last < PRESENCE_CONFIG.dbWriteDebounceMs) return;
    this.lastDbWriteByUser.set(userId, now);
    try {
      await this.prisma.user.update({
        where: { id: userId },
        data: { lastActiveAt: new Date() },
      });
      if (sessionId) {
        await this.prisma.userSession.updateMany({
          where: { id: sessionId, userId },
          data: {
            lastSeenAt: new Date(),
            platform: meta.platform as DevicePlatform,
            appVersion: meta.appVersion,
            deviceModel: meta.deviceModel,
            osVersion: meta.osVersion,
          },
        });
      }
    } catch (error) {
      this.logger.warn(`debouncedDbTouch failed userId=${userId}: ${String(error)}`);
    }
  }

  private schedulePublish(): void {
    if (this.publishTimer) clearTimeout(this.publishTimer);
    this.publishTimer = setTimeout(() => {
      this.publishTimer = null;
      void this.publishSummary();
    }, PRESENCE_CONFIG.sseDebounceMs);
  }

  private async publishSummary(): Promise<void> {
    const counts = await this.countByStatus();
    const peakToday = await this.realtime.getPeakToday();
    this.realtime.publishActiveUsersUpdated({
      type: 'active_users_updated',
      summary: {
        currentActive: counts.total,
        online: counts.online,
        away: counts.away,
        peakToday,
      },
    });
  }

  async applySessionGeo(sessionId: string, country: string | null, city: string | null): Promise<void> {
    if (!country && !city) return;
    await this.prisma.userSession.updateMany({
      where: { id: sessionId },
      data: { country, city },
    });
  }

  async enrichMetaFromSession(userId: string, deviceId: string, sessionId: string): Promise<void> {
    const session = await this.prisma.userSession.findFirst({
      where: { id: sessionId, userId },
      select: { country: true, city: true },
    });
    if (!session) return;
    const member = presenceMemberKey(userId, deviceId);
    const meta = await this.store.getMeta(member);
    if (!meta) return;
    meta.country = session.country;
    meta.city = session.city;
    await this.store.setMeta(member, meta);
  }
}
