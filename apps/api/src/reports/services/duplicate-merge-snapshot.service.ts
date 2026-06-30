import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { MergeDuplicateReportsResponseDto } from '../dto/admin-duplicate-report.dto';
import { resolveActorIdentity } from '../../common/projections/public-identity.projection';

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
                status: true,
              },
            },
          },
          orderBy: { reportedAt: 'asc' },
        },
      },
    });

    const coReporters = primaryAfter.coReporters
      .filter((row): row is typeof row & { userId: string } => row.userId != null)
      .map((row) => {
      const identity = resolveActorIdentity(row.user, { actorUserId: row.userId });
      return {
        userId: row.userId,
        name: identity.displayName ?? '',
        reportedAt: row.reportedAt.toISOString(),
      };
    });

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
