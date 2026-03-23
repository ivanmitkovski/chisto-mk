import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma, ReportStatus, Site, SiteStatus } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { distanceInMeters } from '../common/utils/distance';
import { ReportsUploadService } from '../reports/reports-upload.service';
import { CreateSiteDto } from './dto/create-site.dto';
import { ListSitesQueryDto } from './dto/list-sites-query.dto';
import { UpdateSiteStatusDto } from './dto/update-site-status.dto';

type SiteWithReportsAndEvents = Prisma.SiteGetPayload<{
  include: { reports: true; events: true };
}>;

const ALLOWED_SITE_STATUS_TRANSITIONS: Record<SiteStatus, SiteStatus[]> = {
  REPORTED: ['VERIFIED', 'DISPUTED'],
  VERIFIED: ['CLEANUP_SCHEDULED', 'DISPUTED'],
  CLEANUP_SCHEDULED: ['IN_PROGRESS', 'DISPUTED'],
  IN_PROGRESS: ['CLEANED', 'DISPUTED'],
  CLEANED: ['DISPUTED'],
  DISPUTED: ['REPORTED', 'VERIFIED'],
};

@Injectable()
export class SitesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reportsUploadService: ReportsUploadService,
  ) {}

  async create(dto: CreateSiteDto): Promise<Site> {
    return this.prisma.site.create({
      data: {
        latitude: dto.latitude,
        longitude: dto.longitude,
        description: dto.description ?? null,
      },
    });
  }

  async findAll(query: ListSitesQueryDto): Promise<{
    data: Array<
      Site & {
        reportCount: number;
        latestReportDescription: string | null;
        distanceKm?: number;
      }
    >;
    meta: { page: number; limit: number; total: number };
  }> {
    const where: Prisma.SiteWhereInput = query.status
      ? { status: query.status }
      : {};

    const hasGeo = query.lat != null && query.lng != null;
    if (hasGeo) {
      const radiusMeters = (query.radiusKm ?? 10) * 1000;
      const metersPerDegreeLat = 111_320;
      const deltaLat = radiusMeters / metersPerDegreeLat;
      const metersPerDegreeLng =
        Math.cos((query.lat! * Math.PI) / 180) * metersPerDegreeLat ||
        metersPerDegreeLat;
      const deltaLng = radiusMeters / metersPerDegreeLng;

      where.latitude = {
        gte: query.lat! - deltaLat,
        lte: query.lat! + deltaLat,
      };
      where.longitude = {
        gte: query.lng! - deltaLng,
        lte: query.lng! + deltaLng,
      };
    }

    const sites = await this.prisma.site.findMany({
      where,
      include: {
        reports: {
          orderBy: { createdAt: 'desc' },
          take: 1,
          select: { description: true, mediaUrls: true },
        },
        _count: { select: { reports: true } },
      },
    });

    type SiteEnriched = Site & {
      reportCount: number;
      latestReportDescription: string | null;
      latestReportMediaUrls?: string[];
      distanceKm?: number;
    };

    const enrichedPromises = sites.map(async (site) => {
      const { reports, _count, ...siteBase } = site;
      const firstReport = reports[0];
      const mediaUrls = firstReport?.mediaUrls?.length
        ? await this.reportsUploadService.signUrls(firstReport.mediaUrls)
        : undefined;
      return {
        ...siteBase,
        reportCount: _count.reports,
        latestReportDescription: firstReport?.description ?? null,
        latestReportMediaUrls: mediaUrls,
        distanceKm:
          hasGeo && query.lat != null && query.lng != null
            ? distanceInMeters(
                query.lat,
                query.lng,
                site.latitude,
                site.longitude,
              ) / 1000
            : undefined,
      } as SiteEnriched;
    });

    let enriched = await Promise.all(enrichedPromises);

    if (hasGeo && query.lat != null && query.lng != null) {
      const radiusMeters = (query.radiusKm ?? 10) * 1000;
      enriched = enriched
        .filter((s) => (s.distanceKm ?? 0) * 1000 <= radiusMeters)
        .sort((a, b) => (a.distanceKm ?? 0) - (b.distanceKm ?? 0));
    } else {
      enriched = enriched.sort(
        (a, b) =>
          new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
      );
    }

    const total = enriched.length;
    const skip = (query.page - 1) * query.limit;
    const data = enriched.slice(skip, skip + query.limit);

    return {
      data,
      meta: {
        page: query.page,
        limit: query.limit,
        total,
      },
    };
  }

  async findOne(siteId: string): Promise<SiteWithReportsAndEvents> {
    const site = await this.prisma.site.findUnique({
      where: { id: siteId },
      include: {
        reports: {
          orderBy: { createdAt: 'desc' },
        },
        events: {
          orderBy: { scheduledAt: 'asc' },
        },
      },
    });

    if (!site) {
      throw new NotFoundException({
        code: 'SITE_NOT_FOUND',
        message: `Site with id '${siteId}' was not found`,
      });
    }

    const reportsWithSignedUrls = await Promise.all(
      site.reports.map(async (r) => ({
        ...r,
        mediaUrls: await this.reportsUploadService.signUrls(r.mediaUrls),
      })),
    );

    return { ...site, reports: reportsWithSignedUrls };
  }

  async updateStatus(siteId: string, dto: UpdateSiteStatusDto): Promise<Site> {
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

    return this.prisma.site.update({
      where: { id: siteId },
      data: { status: dto.status },
    });
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
