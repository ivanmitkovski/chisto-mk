import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { ReportStatus, Site, SiteStatus } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { SiteEventsService } from '../admin-realtime/site-events.service';
import { AuditService } from '../audit/audit.service';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { CreateSiteDto } from './dto/create-site.dto';
import { UpdateSiteArchiveDto } from './dto/update-site-archive.dto';
import { UpdateSiteStatusDto } from './dto/update-site-status.dto';
import { BulkSitesDto } from './dto/bulk-sites.dto';
import { SitesMapQueryService } from './sites-map-query.service';
import { SitesFeedService } from './sites-feed.service';

const ALLOWED_SITE_STATUS_TRANSITIONS: Record<SiteStatus, SiteStatus[]> = {
  REPORTED: ['VERIFIED', 'DISPUTED'],
  VERIFIED: ['CLEANUP_SCHEDULED', 'DISPUTED'],
  CLEANUP_SCHEDULED: ['IN_PROGRESS', 'DISPUTED'],
  IN_PROGRESS: ['CLEANED', 'DISPUTED'],
  CLEANED: ['DISPUTED'],
  DISPUTED: ['REPORTED', 'VERIFIED'],
};

@Injectable()
export class SitesAdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly siteEventsService: SiteEventsService,
    private readonly sitesMapQuery: SitesMapQueryService,
    private readonly sitesFeed: SitesFeedService,
  ) {}

  async create(dto: CreateSiteDto): Promise<Site> {
    const site = await this.prisma.site.create({
      data: {
        latitude: dto.latitude,
        longitude: dto.longitude,
        description: dto.description ?? null,
      },
    });
    this.sitesFeed.invalidateFeedCache('site_created');
    this.sitesMapQuery.invalidateMapCache('site_created');
    this.siteEventsService.emitSiteCreated(site.id, {
      status: site.status,
      latitude: site.latitude,
      longitude: site.longitude,
      updatedAt: site.updatedAt,
    });
    return site;
  }

  async updateStatus(
    siteId: string,
    dto: UpdateSiteStatusDto,
    admin: AuthenticatedUser,
  ): Promise<Site> {
    const site = await this.prisma.site.findUnique({
      where: { id: siteId },
      select: { id: true, status: true },
    });

    if (!site) {
      throw new NotFoundException({
        code: 'SITE_NOT_FOUND',
        message: `Site with id '${siteId}' was not found`,
      });
    }

    if (site.status === dto.status) {
      return this.prisma.site.findUniqueOrThrow({
        where: { id: siteId },
      });
    }

    const allowedStatuses = ALLOWED_SITE_STATUS_TRANSITIONS[site.status];
    if (!allowedStatuses.includes(dto.status)) {
      throw new BadRequestException({
        code: 'INVALID_SITE_STATUS_TRANSITION',
        message: `Cannot transition site status from '${site.status}' to '${dto.status}'`,
        details: {
          from: site.status,
          to: dto.status,
          allowedTo: allowedStatuses,
        },
      });
    }

    const updated = await this.prisma.site.update({
      where: { id: siteId },
      data: { status: dto.status },
    });

    this.siteEventsService.emitSiteUpdated(siteId, {
      kind: 'status_changed',
      status: updated.status,
      latitude: updated.latitude,
      longitude: updated.longitude,
      updatedAt: updated.updatedAt,
    });

    await this.audit.log({
      actorId: admin.userId,
      action: 'SITE_STATUS_UPDATED',
      resourceType: 'Site',
      resourceId: siteId,
      metadata: { from: site.status, to: dto.status },
    });

    this.sitesFeed.invalidateFeedCache('site_status_updated');
    this.sitesMapQuery.invalidateMapCache('site_status_updated', updated.id);
    return updated;
  }

  async updateArchiveStatus(
    siteId: string,
    dto: UpdateSiteArchiveDto,
    admin: AuthenticatedUser,
  ): Promise<Site> {
    const site = await this.prisma.site.findUnique({
      where: { id: siteId },
      select: {
        id: true,
        isArchivedByAdmin: true,
        archivedAt: true,
        archivedById: true,
        archiveReason: true,
      },
    });

    if (!site) {
      throw new NotFoundException({
        code: 'SITE_NOT_FOUND',
        message: `Site with id '${siteId}' was not found`,
      });
    }

    const normalizedReason = dto.reason?.trim() || null;
    if (dto.archived && !normalizedReason) {
      throw new BadRequestException({
        code: 'ARCHIVE_REASON_REQUIRED',
        message: 'Reason is required when archiving a site.',
      });
    }

    if (site.isArchivedByAdmin === dto.archived) {
      return this.prisma.site.findUniqueOrThrow({
        where: { id: siteId },
      });
    }

    const now = new Date();
    const updated = await this.prisma.site.update({
      where: { id: siteId },
      data: dto.archived
        ? {
            isArchivedByAdmin: true,
            archivedAt: now,
            archivedById: admin.userId,
            archiveReason: normalizedReason,
          }
        : {
            isArchivedByAdmin: false,
            archivedAt: null,
            archivedById: null,
            archiveReason: null,
          },
    });

    this.siteEventsService.emitSiteUpdated(siteId, {
      kind: 'updated',
      status: updated.status,
      latitude: updated.latitude,
      longitude: updated.longitude,
      updatedAt: updated.updatedAt,
    });

    await this.audit.log({
      actorId: admin.userId,
      action: dto.archived ? 'SITE_ARCHIVED' : 'SITE_UNARCHIVED',
      resourceType: 'Site',
      resourceId: siteId,
      metadata: {
        fromArchived: site.isArchivedByAdmin,
        toArchived: dto.archived,
        previousReason: site.archiveReason,
        reason: normalizedReason,
      },
    });

    this.sitesFeed.invalidateFeedCache(dto.archived ? 'site_archived' : 'site_unarchived');
    this.sitesMapQuery.invalidateMapCache(dto.archived ? 'site_archived' : 'site_unarchived', siteId);
    return updated;
  }

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

  async assertSiteEligibleForEcoAction(siteId: string): Promise<void> {
    const approvedCount = await this.prisma.report.count({
      where: {
        siteId,
        status: ReportStatus.APPROVED,
      },
    });
    if (approvedCount === 0) {
      throw new BadRequestException({
        code: 'SITE_NOT_APPROVED_FOR_ECO_ACTIONS',
        message: 'Site must have at least one approved report to create eco actions.',
      });
    }
  }
}
