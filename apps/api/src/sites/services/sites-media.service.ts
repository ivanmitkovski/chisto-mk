import { Injectable, NotFoundException } from '@nestjs/common';
import { SiteStatus } from '../../prisma-client';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { ReportsUploadService } from '../../reports/services/reports-upload.service';
import { ListSiteMediaQueryDto } from '../dto/list-site-media-query.dto';
import { SiteDetailRepository } from '../repositories/site-detail.repository';
import { SiteMediaRepository } from '../repositories/site-media.repository';

@Injectable()
export class SitesMediaService {
  private static readonly MAX_MEDIA_ITEMS_SCANNED = 10_000;

  constructor(
    private readonly siteMediaRepository: SiteMediaRepository,
    private readonly siteDetailRepository: SiteDetailRepository,
    private readonly reportsUploadService: ReportsUploadService,
  ) {}

  async findSiteMedia(
    siteId: string,
    query: ListSiteMediaQueryDto,
    user?: AuthenticatedUser,
  ) {
    const site = await this.siteDetailRepository.findSiteStatusById(siteId);
    if (!site) {
      throw new NotFoundException({
        code: 'SITE_NOT_FOUND',
        message: `Site with id '${siteId}' was not found`,
      });
    }

    if (site.status === SiteStatus.REPORTED) {
      const viewerUserId = user?.userId ?? null;
      if (!viewerUserId) {
        throw new NotFoundException({
          code: 'SITE_NOT_FOUND',
          message: `Site with id '${siteId}' was not found`,
        });
      }
      const canView = await this.siteDetailRepository.viewerCanAccessReportedSite(
        siteId,
        viewerUserId,
      );
      if (!canView) {
        throw new NotFoundException({
          code: 'SITE_NOT_FOUND',
          message: `Site with id '${siteId}' was not found`,
        });
      }
    }

    const reports = await this.siteMediaRepository.findReportsForSite(siteId);
    const allItems = reports.flatMap((report) =>
      report.mediaUrls.map((url, index) => ({
        id: `${report.id}:${index}`,
        reportId: report.id,
        createdAt: report.createdAt.toISOString(),
        originalUrl: url,
      })),
    );
    const boundedItems = allItems.slice(0, SitesMediaService.MAX_MEDIA_ITEMS_SCANNED);

    const total = boundedItems.length;
    const skip = (query.page - 1) * query.limit;
    const pageItems = boundedItems.slice(skip, skip + query.limit);
    const signedUrls = await this.reportsUploadService.signUrls(
      pageItems.map((item) => item.originalUrl),
    );
    const data = pageItems.map((item, index) => ({
      id: item.id,
      reportId: item.reportId,
      createdAt: item.createdAt,
      url: signedUrls[index] ?? item.originalUrl,
    }));
    return {
      data,
      meta: {
        page: query.page,
        limit: query.limit,
        total,
        truncated: allItems.length > boundedItems.length,
      },
    };
  }
}
