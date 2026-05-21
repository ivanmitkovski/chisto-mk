import { Injectable } from '@nestjs/common';
import { SiteStatus } from '../prisma-client';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { distanceInMeters } from '../common/utils/distance';
import { ReportsUploadService } from '../reports/reports-upload.service';
import { PrismaService } from '../prisma/prisma.service';
import { PaginationQueryDto20 } from '../common/dto/pagination-query.dto';
import { mapWithConcurrency } from './sites-feed-query-async.util';
import type { FeedSiteRow } from './sites-feed-candidate.types';
import type { SitesFeedListResult } from './sites-feed.types';

@Injectable()
export class SitesSavedListService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reportsUploadService: ReportsUploadService,
  ) {}

  private siteInclude(userId: string) {
    return {
      reports: {
        orderBy: { createdAt: 'desc' as const },
        take: 1,
        select: {
          title: true,
          description: true,
          mediaUrls: true,
          category: true,
          createdAt: true,
          reportNumber: true,
          reporter: {
            select: { id: true, firstName: true, lastName: true, avatarObjectKey: true },
          },
        },
      },
      votes: { where: { userId }, select: { id: true }, take: 1 },
      saves: { where: { userId }, select: { id: true }, take: 1 },
      _count: { select: { reports: true } },
    };
  }

  async listSavedForUser(
    user: AuthenticatedUser,
    query: PaginationQueryDto20,
    opts?: { lat?: number; lng?: number },
  ): Promise<SitesFeedListResult> {
    const userId = user.userId;
    const skip = (query.page - 1) * query.limit;
    const hasGeo = opts?.lat != null && opts?.lng != null;

    const [total, saves] = await Promise.all([
      this.prisma.siteSave.count({ where: { userId } }),
      this.prisma.siteSave.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        skip,
        take: query.limit,
        select: {
          site: {
            include: this.siteInclude(userId),
          },
        },
      }),
    ]);

    const sites = saves
      .map((row) => row.site)
      .filter((site): site is FeedSiteRow => site != null);

    const enriched = await mapWithConcurrency(sites, 8, async (site) => {
      const { reports, votes, saves: saveRows, _count, ...siteBase } = site;
      const firstReport = reports[0];
      const mediaUrls = firstReport?.mediaUrls?.length
        ? await this.reportsUploadService.signUrls(firstReport.mediaUrls)
        : undefined;
      let latestReportReporterName: string | null = null;
      let latestReportReporterAvatarUrl: string | null = null;
      let latestReportReporterId: string | null = null;
      const feedRep = firstReport?.reporter;
      if (feedRep) {
        latestReportReporterId = feedRep.id;
        const nm = `${feedRep.firstName ?? ''} ${feedRep.lastName ?? ''}`.trim();
        latestReportReporterName = nm.length > 0 ? nm : null;
        latestReportReporterAvatarUrl = await this.reportsUploadService.signPrivateObjectKey(
          feedRep.avatarObjectKey,
        );
      }
      const latestReportDate = firstReport?.createdAt ?? siteBase.createdAt;
      const distanceKm =
        hasGeo && opts!.lat != null && opts!.lng != null
          ? distanceInMeters(opts!.lat, opts!.lng, site.latitude, site.longitude) / 1000
          : undefined;

      return {
        id: siteBase.id,
        latitude: siteBase.latitude,
        longitude: siteBase.longitude,
        description: siteBase.description,
        status: siteBase.status as SiteStatus,
        reportCount: _count.reports,
        latestReportTitle: firstReport?.title ?? null,
        latestReportDescription: firstReport?.description ?? null,
        latestReportCategory: firstReport?.category ?? null,
        latestReportCreatedAt: latestReportDate.toISOString(),
        latestReportNumber: firstReport?.reportNumber ?? null,
        latestReportMediaUrls: mediaUrls,
        latestReportReporterName,
        latestReportReporterAvatarUrl,
        latestReportReporterId,
        upvotesCount: siteBase.upvotesCount,
        commentsCount: siteBase.commentsCount,
        sharesCount: siteBase.sharesCount,
        isUpvotedByMe: Array.isArray(votes) && votes.length > 0,
        isSavedByMe: true,
        rankingScore: latestReportDate.getTime(),
        rankingReasons: ['saved_by_you'],
        distanceKm,
      };
    });

    const nextCursor =
      skip + enriched.length < total ? String(query.page + 1) : null;

    return {
      data: enriched as SitesFeedListResult['data'],
      meta: {
        page: query.page,
        limit: query.limit,
        total,
        nextCursor,
      },
      feedVariant: 'v1',
    };
  }
}
