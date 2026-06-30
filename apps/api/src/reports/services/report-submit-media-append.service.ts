import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ReportsOwnerEventsService } from './reports-owner-events.service';
import { ReportsUploadService } from './reports-upload.service';
import { SiteHeroImageService } from '../../sites/services/site-hero-image.service';

@Injectable()
export class ReportSubmitMediaAppendService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reportsUpload: ReportsUploadService,
    private readonly reportsOwnerEventsService: ReportsOwnerEventsService,
    private readonly siteHeroImage: SiteHeroImageService,
  ) {}

  /**
   * Verifies the user may append media before uploading to object storage.
   */
  async assertCanAppendMedia(reportId: string, userId: string): Promise<void> {
    const report = await this.prisma.report.findUnique({
      where: { id: reportId },
      select: {
        id: true,
        reporterId: true,
        coReporters: { select: { userId: true } },
      },
    });

    if (!report) {
      throw new NotFoundException({
        code: 'REPORT_NOT_FOUND',
        message: `Report with id '${reportId}' was not found`,
      });
    }

    const isReporter = report.reporterId === userId;
    const isCoReporter = report.coReporters.some((c) => c.userId === userId);
    if (!isReporter && !isCoReporter) {
      throw new ForbiddenException({
        code: 'FORBIDDEN',
        message: 'Only the report creator or co-reporters may add media',
      });
    }
  }

  /**
   * Appends media URLs to an existing report. Only the report's reporter or co-reporters may add media.
   */
  async appendMedia(reportId: string, userId: string, urls: string[]): Promise<void> {
    if (!urls || urls.length === 0) {
      return;
    }
    this.reportsUpload.assertReportMediaUrlsFromOurBucket(urls);

    await this.assertCanAppendMedia(reportId, userId);

    const report = await this.prisma.report.findUnique({
      where: { id: reportId },
      select: {
        id: true,
        siteId: true,
        status: true,
        mediaUrls: true,
        reporterId: true,
        coReporters: { select: { userId: true } },
      },
    });
    if (!report) {
      throw new NotFoundException({
        code: 'REPORT_NOT_FOUND',
        message: `Report with id '${reportId}' was not found`,
      });
    }

    const existingUrls = report.mediaUrls ?? [];
    const newUrls = [...existingUrls, ...urls];
    if (newUrls.length > 10) {
      throw new BadRequestException({
        code: 'TOO_MANY_MEDIA',
        message: 'Maximum 10 media files per report',
      });
    }

    const heroResult = await this.prisma.$transaction(async (tx) => {
      await tx.report.update({
        where: { id: reportId },
        data: { mediaUrls: newUrls },
      });
      if (report.status === 'APPROVED') {
        return this.siteHeroImage.recomputeSiteHero(tx, report.siteId);
      }
      return { changed: false, heroReportId: null };
    });

    if (heroResult.changed) {
      this.siteHeroImage.emitIfChanged(report.siteId, heroResult);
    }

    const coReporterUserIds = report.coReporters
      .map((c) => c.userId)
      .filter((id): id is string => id != null);
    this.reportsOwnerEventsService.emitToReportInterestedParties(
      reportId,
      report.reporterId,
      coReporterUserIds,
      'report_updated',
      { kind: 'media_appended' },
    );
  }
}
