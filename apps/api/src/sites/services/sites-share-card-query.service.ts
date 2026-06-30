import { Injectable, NotFoundException } from '@nestjs/common';
import { ReportStatus, SiteStatus } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class SitesShareCardQueryService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Minimal fields for HTTPS share landing (`GET /sites/:id/share-card`).
   * Public map visibility only (non-REPORTED, not admin-archived; no reporter PII).
   */
  async findPublicShareCard(id: string) {
    const row = await this.prisma.site.findFirst({
      where: {
        id,
        status: { not: SiteStatus.REPORTED },
        isArchivedByAdmin: false,
      },
      select: {
        id: true,
        address: true,
        description: true,
        status: true,
        heroReport: { select: { title: true } },
        reports: {
          where: { status: ReportStatus.APPROVED },
          orderBy: { createdAt: 'asc' },
          take: 1,
          select: { title: true },
        },
      },
    });
    if (row == null) {
      throw new NotFoundException({
        code: 'SITE_NOT_FOUND',
        message: 'Site not found',
      });
    }
    return {
      id: row.id,
      title: this.publicShareTitle(row),
      siteLabel: this.publicShareSiteLabel(row),
      status: row.status,
    };
  }

  private publicShareTitle(row: {
    heroReport: { title: string } | null;
    reports: { title: string }[];
    description: string | null;
  }): string {
    const heroTitle = row.heroReport?.title?.trim();
    if (heroTitle != null && heroTitle.length > 0) {
      return heroTitle;
    }
    const reportTitle = row.reports[0]?.title?.trim();
    if (reportTitle != null && reportTitle.length > 0) {
      return reportTitle;
    }
    const description = row.description?.trim();
    if (description != null && description.length > 0) {
      return description.length > 120 ? `${description.slice(0, 117)}…` : description;
    }
    return 'Pollution site';
  }

  private publicShareSiteLabel(site: {
    address: string | null;
    description: string | null;
  }): string {
    const address = site.address?.trim();
    if (address != null && address.length > 0) {
      return address;
    }
    const description = site.description?.trim();
    if (description != null && description.length > 0) {
      return description.length > 120 ? `${description.slice(0, 117)}…` : description;
    }
    return 'Site';
  }
}
