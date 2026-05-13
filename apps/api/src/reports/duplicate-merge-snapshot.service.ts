import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { MergeDuplicateReportsResponseDto } from './dto/admin-duplicate-report.dto';

@Injectable()
export class DuplicateMergeSnapshotService {
  constructor(private readonly prisma: PrismaService) {}

  async buildMergeCompletedSnapshot(
    primaryReportId: string,
    metrics: {
      mergedChildCount: number;
      mergedMediaCount: number;
      mergedCoReporterCount: number;
    },
  ): Promise<MergeDuplicateReportsResponseDto> {
    const primaryAfter = await this.prisma.report.findUniqueOrThrow({
      where: { id: primaryReportId },
      select: {
        status: true,
        reporterId: true,
        coReporters: {
          select: {
            userId: true,
            reportedAt: true,
            user: {
              select: {
                firstName: true,
                lastName: true,
              },
            },
          },
          orderBy: { reportedAt: 'asc' },
        },
      },
    });

    const coReporters = primaryAfter.coReporters.map((row) => ({
      userId: row.userId,
      name: `${row.user.firstName} ${row.user.lastName}`.trim(),
      reportedAt: row.reportedAt.toISOString(),
    }));

    const reporterCount = (primaryAfter.reporterId ? 1 : 0) + primaryAfter.coReporters.length;

    return {
      primaryReportId,
      mergedChildCount: metrics.mergedChildCount,
      mergedMediaCount: metrics.mergedMediaCount,
      mergedCoReporterCount: metrics.mergedCoReporterCount,
      primaryStatus: primaryAfter.status,
      coReporters,
      reporterCount,
    };
  }
}
