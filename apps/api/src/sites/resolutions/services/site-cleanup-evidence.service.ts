import { Injectable, NotFoundException } from '@nestjs/common';
import { EventEvidenceKind, SiteResolutionStatus, SiteStatus } from '../../../prisma-client';
import { PrismaService } from '../../../prisma/prisma.service';
import { resolveActorIdentity } from '../../../common/projections/public-identity.projection';
import { ReportsUploadService } from '../../../reports/services/reports-upload.service';
import { PaginationQueryDto20 } from '../../../common/dto/pagination-query.dto';
import type { CleanupEvidenceItemDto, CleanupEvidenceListResponseDto } from '../dto/cleanup-evidence.dto';
import { SiteDetailRepository } from '../../repositories/site-detail.repository';

type EvidenceRow = {
  id: string;
  url: string;
  source: CleanupEvidenceItemDto['source'];
  createdAt: Date;
  caption: string | null;
  submitterUser: { firstName: string; lastName: string; status: import('../../../prisma-client').UserStatus } | null;
  submitterUserId: string | null;
  resolutionId: string | null;
  cleanupEventId: string | null;
};

@Injectable()
export class SiteCleanupEvidenceService {
  private static readonly MAX_ITEMS_SCANNED = 10_000;

  constructor(
    private readonly prisma: PrismaService,
    private readonly reportsUpload: ReportsUploadService,
    private readonly siteDetailRepository: SiteDetailRepository,
  ) {}

  async listForSite(
    siteId: string,
    query: PaginationQueryDto20,
  ): Promise<CleanupEvidenceListResponseDto> {
    const site = await this.siteDetailRepository.findSiteStatusById(siteId);
    if (!site) {
      throw new NotFoundException({
        code: 'SITE_NOT_FOUND',
        message: `Site with id '${siteId}' was not found`,
      });
    }

    if (site.status === SiteStatus.REPORTED) {
      throw new NotFoundException({
        code: 'SITE_NOT_FOUND',
        message: `Site with id '${siteId}' was not found`,
      });
    }

    const items: EvidenceRow[] = [];

    const resolutions = await this.prisma.siteResolution.findMany({
      where: { siteId, status: SiteResolutionStatus.APPROVED },
      orderBy: { createdAt: 'asc' },
      include: {
        submittedBy: { select: { firstName: true, lastName: true, status: true } },
      },
    });

    for (const resolution of resolutions) {
      resolution.mediaUrls.forEach((url, index) => {
        items.push({
          id: `${resolution.id}:${index}`,
          url,
          source: 'RESOLUTION',
          createdAt: resolution.createdAt,
          caption: resolution.note,
          submitterUser: resolution.submittedBy,
          submitterUserId: resolution.submittedById,
          resolutionId: resolution.id,
          cleanupEventId: null,
        });
      });
    }

    const events = await this.prisma.cleanupEvent.findMany({
      where: { siteId },
      select: {
        id: true,
        createdAt: true,
        afterImageKeys: true,
        evidencePhotos: {
          where: { kind: EventEvidenceKind.AFTER },
          select: {
            id: true,
            objectKey: true,
            caption: true,
            createdAt: true,
            uploadedBy: { select: { firstName: true, lastName: true, status: true } },
            uploadedById: true,
          },
        },
      },
    });

    for (const event of events) {
      for (const key of event.afterImageKeys) {
        const publicUrl = this.reportsUpload.getPublicUrlsForKeys([key])[0] ?? key;
        items.push({
          id: `event-after:${event.id}:${key}`,
          url: publicUrl,
          source: 'CLEANUP_EVENT_AFTER',
          createdAt: event.createdAt,
          caption: null,
          submitterUser: null,
          submitterUserId: null,
          resolutionId: null,
          cleanupEventId: event.id,
        });
      }
      for (const photo of event.evidencePhotos) {
        const publicUrl =
          this.reportsUpload.getPublicUrlsForKeys([photo.objectKey])[0] ?? photo.objectKey;
        items.push({
          id: photo.id,
          url: publicUrl,
          source: 'CLEANUP_EVENT_EVIDENCE',
          createdAt: photo.createdAt,
          caption: photo.caption,
          submitterUser: photo.uploadedBy,
          submitterUserId: photo.uploadedById,
          resolutionId: null,
          cleanupEventId: event.id,
        });
      }
    }

    items.sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime());
    const bounded = items.slice(0, SiteCleanupEvidenceService.MAX_ITEMS_SCANNED);
    const total = bounded.length;
    const skip = (query.page - 1) * query.limit;
    const pageItems = bounded.slice(skip, skip + query.limit);

    const signedUrls = await this.reportsUpload.signUrls(pageItems.map((i) => i.url));

    const data: CleanupEvidenceItemDto[] = pageItems.map((item, index) => {
      const identity = resolveActorIdentity(item.submitterUser, {
        actorUserId: item.submitterUserId,
      });
      return {
        id: item.id,
        url: signedUrls[index] ?? item.url,
        source: item.source,
        createdAt: item.createdAt.toISOString(),
        caption: item.caption,
        submitter:
          item.submitterUserId == null && item.submitterUser == null
            ? null
            : {
                displayLabel: identity.displayName,
                isDeleted: identity.isDeleted,
                isAnonymous: identity.isAnonymous,
              },
        resolutionId: item.resolutionId,
        cleanupEventId: item.cleanupEventId,
      };
    });

    return {
      data,
      meta: { page: query.page, limit: query.limit, total },
    };
  }
}
