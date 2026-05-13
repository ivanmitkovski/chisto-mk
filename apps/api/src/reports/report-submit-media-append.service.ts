import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ReportsOwnerEventsService } from './reports-owner-events.service';
import { ReportsUploadService } from './reports-upload.service';

@Injectable()
export class ReportSubmitMediaAppendService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reportsUpload: ReportsUploadService,
    private readonly reportsOwnerEventsService: ReportsOwnerEventsService,
  ) {}

  /**
   * Appends media URLs to an existing report. Only the report's reporter or co-reporters may add media.
   */
  async appendMedia(reportId: string, userId: string, urls: string[]): Promise<void> {
    if (!urls || urls.length === 0) {
      return;
    }
    this.reportsUpload.assertReportMediaUrlsFromOurBucket(urls);

    const report = await this.prisma.report.findUnique({
      where: { id: reportId },
      select: {
        id: true,
        reporterId: true,
        mediaUrls: true,
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

    const existingUrls = report.mediaUrls ?? [];
    const newUrls = [...existingUrls, ...urls];
    if (newUrls.length > 10) {
      throw new BadRequestException({
        code: 'TOO_MANY_MEDIA',
        message: 'Maximum 10 media files per report',
      });
    }

    await this.prisma.report.update({
      where: { id: reportId },
      data: { mediaUrls: newUrls },
    });

    const coReporterUserIds = report.coReporters.map((c) => c.userId);
    this.reportsOwnerEventsService.emitToReportInterestedParties(
      reportId,
      report.reporterId,
      coReporterUserIds,
      'report_updated',
      { kind: 'media_appended' },
    );
  }
}
