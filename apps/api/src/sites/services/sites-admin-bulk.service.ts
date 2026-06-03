import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../../audit/services/audit.service';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { BulkSitesDto } from '../dto/bulk-sites.dto';
import { SitesMapQueryService } from './sites-map-query.service';
import { SitesFeedService } from './sites-feed.service';

@Injectable()
export class SitesAdminBulkService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly sitesMapQuery: SitesMapQueryService,
    private readonly sitesFeed: SitesFeedService,
  ) {}

  async bulkSites(
    dto: BulkSitesDto,
    admin: AuthenticatedUser,
  ): Promise<{ updated: number; siteIds: string[] }> {
    const siteIds = [...new Set(dto.siteIds)];

    if (dto.idempotencyKey) {
      const existing = await this.audit.findByActionAndIdempotencyKey(
        'SITES_BULK_UPDATE',
        dto.idempotencyKey,
      );
      if (existing) {
        const prevUpdated =
          typeof existing.metadata.updated === 'number' ? existing.metadata.updated : 0;
        const prevSiteIds = Array.isArray(existing.metadata.siteIds)
          ? (existing.metadata.siteIds as string[])
          : siteIds;
        return { updated: prevUpdated, siteIds: prevSiteIds };
      }
    }

    if (dto.action === 'set_status' && dto.status == null) {
      throw new BadRequestException({
        code: 'BULK_STATUS_REQUIRED',
        message: 'Field status is required when action is set_status.',
      });
    }
    if (dto.action === 'set_archived' && dto.archived == null) {
      throw new BadRequestException({
        code: 'BULK_ARCHIVED_REQUIRED',
        message: 'Field archived is required when action is set_archived.',
      });
    }

    let result: { count: number };
    if (dto.action === 'set_status') {
      result = await this.prisma.site.updateMany({
        where: { id: { in: siteIds } },
        data: { status: dto.status! },
      });
    } else {
      const archiveData = dto.archived
        ? {
            isArchivedByAdmin: true,
            archivedAt: new Date(),
            archivedById: admin.userId,
            archiveReason: 'bulk_archive',
          }
        : {
            isArchivedByAdmin: false,
            archivedAt: null,
            archivedById: null,
            archiveReason: null,
          };
      result = await this.prisma.site.updateMany({
        where: { id: { in: siteIds } },
        data: archiveData as unknown as Parameters<typeof this.prisma.site.updateMany>[0]['data'],
      });
    }

    const updated = result.count;
    await this.audit.log({
      actorId: admin.userId,
      action: 'SITES_BULK_UPDATE',
      resourceType: 'Site',
      resourceId: siteIds[0] ?? 'bulk',
      metadata: {
        action: dto.action,
        idempotencyKey: dto.idempotencyKey ?? null,
        updated,
        siteIds,
      },
    });
    this.sitesFeed.invalidateFeedCache('sites_bulk');
    this.sitesMapQuery.invalidateMapCache('sites_bulk');
    return { updated, siteIds };
  }
}
