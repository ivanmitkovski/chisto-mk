import { Injectable } from '@nestjs/common';
import { ReportsUploadService } from '../reports/reports-upload.service';
import { ListSiteMediaQueryDto } from './dto/list-site-media-query.dto';
import { SiteEngagementService } from './site-engagement.service';
import { SiteMediaRepository } from './repositories/site-media.repository';

@Injectable()
export class SitesMediaService {
  private static readonly MAX_MEDIA_ITEMS_SCANNED = 10_000;

  constructor(
    private readonly siteMediaRepository: SiteMediaRepository,
    private readonly reportsUploadService: ReportsUploadService,
    private readonly siteEngagement: SiteEngagementService,
  ) {}

  async findSiteMedia(siteId: string, query: ListSiteMediaQueryDto) {
    await this.siteEngagement.ensureSiteExists(siteId);
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
