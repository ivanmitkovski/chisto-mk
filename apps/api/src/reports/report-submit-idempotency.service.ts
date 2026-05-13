import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { REASON_REPORT_APPROVED, REASON_REPORT_SUBMITTED } from '../gamification/gamification.constants';
import { ReportSubmitResponseDto } from './dto/report-submit-response.dto';
import { getReportNumber } from './report-copy.helpers';

@Injectable()
export class ReportSubmitIdempotencyService {
  private static readonly IDEMPOTENCY_KEY_PATTERN = /^[A-Za-z0-9_-]{16,128}$/;

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Returns a validated key, or `null` when the header is absent / whitespace-only.
   * Throws when a non-empty header does not match the allowed shape.
   */
  parseIdempotencyKeyHeader(header: string | string[] | undefined): string | null {
    if (header === undefined) {
      return null;
    }
    const raw = Array.isArray(header) ? header[0] : header;
    const t = raw.trim();
    if (!t) {
      return null;
    }
    if (!ReportSubmitIdempotencyService.IDEMPOTENCY_KEY_PATTERN.test(t)) {
      throw new BadRequestException({
        code: 'INVALID_IDEMPOTENCY_KEY',
        message: 'Idempotency-Key must be 16–128 characters and match [A-Za-z0-9_-].',
      });
    }
    return t;
  }

  async tryReplayFromIdempotencyKey(
    userId: string,
    key: string,
  ): Promise<ReportSubmitResponseDto | null> {
    const row = await this.prisma.reportSubmitIdempotency.findUnique({
      where: { userId_key: { userId, key } },
      select: { reportId: true },
    });
    if (!row) {
      return null;
    }
    const report = await this.prisma.report.findUnique({
      where: { id: row.reportId },
      select: {
        id: true,
        siteId: true,
        reportNumber: true,
        createdAt: true,
        reporterId: true,
      },
    });
    if (!report || report.reporterId !== userId) {
      return null;
    }
    const ledger = await this.pointsFromLedgerForReport(userId, report.id);
    return {
      reportId: report.id,
      reportNumber: getReportNumber(report),
      siteId: report.siteId,
      isNewSite: false,
      pointsAwarded: ledger.pointsAwarded,
      ...(ledger.pointsBreakdown != null ? { pointsBreakdown: ledger.pointsBreakdown } : {}),
    };
  }

  async pointsFromLedgerForReport(
    userId: string,
    reportId: string,
  ): Promise<{
    pointsAwarded: number;
    pointsBreakdown?: Array<{ code: string; points: number }>;
  }> {
    const txns = await this.prisma.pointTransaction.findMany({
      where: { userId, referenceType: 'Report', referenceId: reportId },
      select: { delta: true, metadata: true, reasonCode: true },
      orderBy: { createdAt: 'asc' },
    });
    const net = txns.reduce((sum, row) => sum + row.delta, 0);
    const approved = txns.find((t) => t.reasonCode === REASON_REPORT_APPROVED);
    const legacySubmit = txns.find((t) => t.reasonCode === REASON_REPORT_SUBMITTED);
    const metaSource = approved ?? legacySubmit;
    const meta = metaSource?.metadata as { breakdown?: Array<{ code: string; points: number }> } | null;
    const breakdown = Array.isArray(meta?.breakdown) ? meta!.breakdown : undefined;
    return {
      pointsAwarded: Math.max(0, net),
      ...(breakdown != null ? { pointsBreakdown: breakdown } : {}),
    };
  }
}
