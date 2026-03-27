import { ForbiddenException, Injectable } from '@nestjs/common';
import { Prisma } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { AuditService } from '../audit/audit.service';
import { Role } from '../prisma-client';
import { PatchFeatureFlagDto } from './dto/patch-feature-flag.dto';

const DEFAULT_FLAGS: Array<{ key: string; enabled: boolean }> = [
  { key: 'cleanup_events_mobile', enabled: false },
  { key: 'reports_map_heatmap', enabled: true },
  { key: 'notifications_inbox_enabled', enabled: true },
  { key: 'push_fcm_enabled', enabled: false },
];

@Injectable()
export class FeatureFlagsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

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
    await this.ensureDefaults();
    const rows = await this.prisma.featureFlag.findMany({
      select: { key: true, enabled: true },
    });
    return Object.fromEntries(rows.map((r) => [r.key, r.enabled]));
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

    return updated;
  }
}
