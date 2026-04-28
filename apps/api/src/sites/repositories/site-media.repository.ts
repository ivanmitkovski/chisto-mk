import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class SiteMediaRepository {
  private static readonly MAX_REPORTS_SCANNED = 500;

  constructor(private readonly prisma: PrismaService) {}

  findReportsForSite(siteId: string) {
    return this.prisma.report.findMany({
      where: { siteId },
      orderBy: { createdAt: 'desc' },
      take: SiteMediaRepository.MAX_REPORTS_SCANNED,
      select: { id: true, mediaUrls: true, createdAt: true },
    });
  }
}
