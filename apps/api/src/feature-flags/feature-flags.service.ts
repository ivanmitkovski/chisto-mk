import { ForbiddenException, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { Prisma } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { AuditService } from '../audit/audit.service';
import { Role } from '../prisma-client';
import { PatchFeatureFlagDto } from './dto/patch-feature-flag.dto';

const PUBLIC_FLAGS_CACHE_TTL_MS = 60_000;

const DEFAULT_FLAGS: Array<{ key: string; enabled: boolean }> = [
  { key: 'cleanup_events_mobile', enabled: false },
  { key: 'reports_map_heatmap', enabled: true },
  { key: 'notifications_inbox_enabled', enabled: true },
  { key: 'push_fcm_enabled', enabled: false },
];

@Injectable()
export class FeatureFlagsService {
  private publicMapCache: { value: Record<string, boolean>; expiresAt: number } | null = null;
  private notificationsInboxCache: { value: boolean; expiresAt: number } | null = null;

  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly config: ConfigService,
    private readonly events: EventEmitter2,
  ) {}

  private invalidatePublicCaches(): void {
    this.publicMapCache = null;
    this.notificationsInboxCache = null;
  }

  /** Clears in-process caches when another API replica publishes a flag change (Redis). */
  applyRemoteFeatureFlagInvalidation(): void {
    this.invalidatePublicCaches();
  }

  async ensureDefaults(): Promise<void> {
    for (const row of DEFAULT_FLAGS) {
      await this.prisma.featureFlag.upsert({
        where: { key: row.key },
        create: { key: row.key, enabled: row.enabled },
        update: {},
      });
    }
  }

  async listForAdmin(): Promise<
    Array<{
      key: string;
      enabled: boolean;
      metadata: unknown;
      updatedAt: string;
    }>
  > {
    await this.ensureDefaults();
    const rows = await this.prisma.featureFlag.findMany({
      orderBy: { key: 'asc' },
    });
    return rows.map((r) => ({
      key: r.key,
      enabled: r.enabled,
      metadata: r.metadata,
      updatedAt: r.updatedAt.toISOString(),
    }));
  }

  async getPublicMap(): Promise<Record<string, boolean>> {
    const now = Date.now();
    if (this.publicMapCache != null && now < this.publicMapCache.expiresAt) {
      return this.publicMapCache.value;
    }
    await this.ensureDefaults();
    const rows = await this.prisma.featureFlag.findMany({
      select: { key: true, enabled: true },
    });
    const map = Object.fromEntries(rows.map((r) => [r.key, r.enabled]));
    this.publicMapCache = {
      value: map,
      expiresAt: now + PUBLIC_FLAGS_CACHE_TTL_MS,
    };
    return map;
  }

  /**
   * Env gate + DB flag, cached briefly to avoid per-request Prisma hits on inbox paths.
   */
  async isNotificationsInboxEnabled(): Promise<boolean> {
    const now = Date.now();
    if (this.notificationsInboxCache != null && now < this.notificationsInboxCache.expiresAt) {
      return this.notificationsInboxCache.value;
    }
    const fromEnv = this.config.get<string>('NOTIFICATIONS_INBOX_ENABLED', 'true') === 'true';
    await this.ensureDefaults();
    const row = await this.prisma.featureFlag.findUnique({
      where: { key: 'notifications_inbox_enabled' },
      select: { enabled: true },
    });
    const value = row?.enabled ?? fromEnv;
    this.notificationsInboxCache = {
      value,
      expiresAt: now + PUBLIC_FLAGS_CACHE_TTL_MS,
    };
    return value;
  }

  async patch(
    key: string,
    dto: PatchFeatureFlagDto,
    actor: AuthenticatedUser,
  ): Promise<{ key: string; enabled: boolean }> {
    if (actor.role !== Role.SUPER_ADMIN && actor.role !== Role.ADMIN) {
      throw new ForbiddenException({
        code: 'FORBIDDEN',
        message: 'Insufficient permissions',
      });
    }

    await this.ensureDefaults();
    const updated = await this.prisma.featureFlag.update({
      where: { key },
      data: {
        enabled: dto.enabled,
        ...(dto.metadata !== undefined ? { metadata: dto.metadata as Prisma.InputJsonValue } : {}),
      },
      select: { key: true, enabled: true },
    });

    await this.audit.log({
      actorId: actor.userId,
      action: 'FEATURE_FLAG_UPDATED',
      resourceType: 'FeatureFlag',
      resourceId: key,
      metadata: { enabled: dto.enabled },
    });

    this.invalidatePublicCaches();
    this.events.emit('feature_flags.patch');

    return updated;
  }
}
