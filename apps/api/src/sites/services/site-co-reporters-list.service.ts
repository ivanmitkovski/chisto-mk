import { createHash } from 'crypto';
import { Injectable, NotFoundException } from '@nestjs/common';
import { SiteStatus } from '../../prisma-client';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { ReportsUploadService } from '../../reports/services/reports-upload.service';
import { ListSiteCoReportersQueryDto } from '../dto/list-site-co-reporters-query.dto';
import { SiteDetailRepository } from '../repositories/site-detail.repository';
import { SiteEngagementService } from './site-engagement.service';
import { PrismaService } from '../../prisma/prisma.service';
import { resolveActorIdentity } from '../../common/projections/public-identity.projection';

@Injectable()
export class SiteCoReportersListService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly siteEngagement: SiteEngagementService,
    private readonly reportsUploadService: ReportsUploadService,
    private readonly siteDetailRepository: SiteDetailRepository,
  ) {}

  /** REPORTED sites are reporter-only — hide their reporter identities from everyone else. */
  private async assertViewerCanSeeReportedSite(
    siteId: string,
    user: AuthenticatedUser | undefined,
  ): Promise<void> {
    const site = await this.siteDetailRepository.findSiteStatusById(siteId);
    if (site == null || site.status !== SiteStatus.REPORTED) {
      return;
    }
    const viewerUserId = user?.userId ?? null;
    const canView =
      viewerUserId != null &&
      (await this.siteDetailRepository.viewerCanAccessReportedSite(siteId, viewerUserId));
    if (!canView) {
      throw new NotFoundException({
        code: 'SITE_NOT_FOUND',
        message: `Site with id '${siteId}' was not found`,
      });
    }
  }

  private opaqueId(siteId: string, userId: string): string {
    return createHash('sha256').update(`${siteId}:${userId}`).digest('hex').slice(0, 24);
  }

  private displayName(
    userId: string,
    firstName: string,
    lastName: string,
    status?: import('../../prisma-client').UserStatus,
  ): { displayName: string; isDeleted: boolean } {
    const identity = resolveActorIdentity(
      { firstName, lastName, ...(status != null ? { status } : {}) },
      { actorUserId: userId },
    );
    return {
      displayName: identity.displayName ?? 'Anonymous',
      isDeleted: identity.isDeleted,
    };
  }

  async findSiteCoReporters(
    siteId: string,
    query: ListSiteCoReportersQueryDto,
    user?: AuthenticatedUser,
  ): Promise<{
    data: Array<{
      id: string;
      firstName: string;
      lastName: string;
      displayName: string;
      isDeleted: boolean;
      avatarUrl: string | null;
      reportedAt: string;
      isOriginalReporter: boolean;
    }>;
    meta: { page: number; limit: number; total: number; hasMore: boolean };
  }> {
    await this.siteEngagement.ensureSiteExists(siteId);
    await this.assertViewerCanSeeReportedSite(siteId, user);

    const originalReport = await this.prisma.report.findFirst({
      where: { siteId, status: { not: 'DELETED' } },
      orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
      select: {
        reporterId: true,
        createdAt: true,
        reporter: {
          select: { firstName: true, lastName: true, avatarObjectKey: true, status: true },
        },
      },
    });

    const originalReporterId = originalReport?.reporterId ?? null;
    const coReporterGroupsRaw = await this.prisma.reportCoReporter.groupBy({
      by: ['userId'],
      where: {
        report: { siteId },
        ...(originalReporterId ? { userId: { not: originalReporterId } } : {}),
      },
      _min: { reportedAt: true },
    });
    const coReporterGroups = coReporterGroupsRaw.filter(
      (group): group is typeof group & { userId: string } => group.userId != null,
    );

    coReporterGroups.sort((a, b) => {
      const aAt = a._min.reportedAt?.getTime() ?? 0;
      const bAt = b._min.reportedAt?.getTime() ?? 0;
      if (aAt !== bAt) return aAt - bAt;
      return (a.userId ?? '').localeCompare(b.userId ?? '');
    });

    const total = (originalReporterId ? 1 : 0) + coReporterGroups.length;
    const page = query.page;
    const limit = query.limit;
    const globalSkip = (page - 1) * limit;

    const rows: Array<{ userId: string; reportedAt: Date; isOriginalReporter: boolean }> = [];

    if (originalReporterId && globalSkip === 0) {
      rows.push({
        userId: originalReporterId,
        reportedAt: originalReport!.createdAt,
        isOriginalReporter: true,
      });
    }

    const coSkip =
      originalReporterId && globalSkip > 0 ? Math.max(0, globalSkip - 1) : globalSkip;
    const coTake = Math.max(0, limit - rows.length);
    const coSlice = coReporterGroups.slice(coSkip, coSkip + coTake);
    for (const group of coSlice) {
      rows.push({
        userId: group.userId,
        reportedAt: group._min.reportedAt ?? new Date(0),
        isOriginalReporter: false,
      });
    }

    const userIds = [...new Set(rows.map((row) => row.userId))];
    const users =
      userIds.length > 0
        ? await this.prisma.user.findMany({
            where: { id: { in: userIds } },
            select: { id: true, firstName: true, lastName: true, avatarObjectKey: true, status: true },
          })
        : [];
    const userById = new Map(users.map((user) => [user.id, user]));

    const data = await Promise.all(
      rows.map(async (row) => {
        const user = userById.get(row.userId);
        const firstName = user?.firstName ?? '';
        const lastName = user?.lastName ?? '';
        const identity = this.displayName(row.userId, firstName, lastName, user?.status);
        const avatarUrl = await this.reportsUploadService.resolveUserAvatarUrl(
          user?.avatarObjectKey ?? null,
        );
        return {
          id: this.opaqueId(siteId, row.userId),
          firstName,
          lastName,
          displayName: identity.displayName,
          isDeleted: identity.isDeleted,
          avatarUrl,
          reportedAt: row.reportedAt.toISOString(),
          isOriginalReporter: row.isOriginalReporter,
        };
      }),
    );

    const loadedThrough = globalSkip + data.length;
    return {
      data,
      meta: {
        page,
        limit,
        total,
        hasMore: loadedThrough < total,
      },
    };
  }
}
