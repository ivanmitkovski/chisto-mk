import { Injectable } from '@nestjs/common';
import { Prisma, SiteHistoryEntryKind } from '../../prisma-client';
import { SiteHistoryWriterService } from './site-history-writer.service';
import { compactSiteHistoryInput, type SiteHistoryActor } from './site-history-write.util';

@Injectable()
export class SiteHistoryReportRecorderService {
  constructor(private readonly writer: SiteHistoryWriterService) {}

  recordReportSubmitted(
    params: {
      siteId: string;
      reportId: string;
      occurredAt?: Date;
      actor?: SiteHistoryActor | null;
    },
    tx?: Prisma.TransactionClient,
  ) {
    return this.writer.write(
      compactSiteHistoryInput({
        siteId: params.siteId,
        kind: SiteHistoryEntryKind.REPORT_SUBMITTED,
        reportId: params.reportId,
        occurredAt: params.occurredAt,
        actor: params.actor,
      }),
      { ...(tx != null ? { tx } : {}), emitSse: false },
    );
  }

  recordReportApproved(
    params: {
      siteId: string;
      reportId: string;
      occurredAt?: Date;
      actor?: SiteHistoryActor | null;
    },
    tx?: Prisma.TransactionClient,
  ) {
    return this.writer.write(
      compactSiteHistoryInput({
        siteId: params.siteId,
        kind: SiteHistoryEntryKind.REPORT_APPROVED,
        reportId: params.reportId,
        occurredAt: params.occurredAt,
        actor: params.actor,
      }),
      { ...(tx != null ? { tx } : {}), emitSse: false },
    );
  }

  recordReportRejected(
    params: {
      siteId: string;
      reportId: string;
      occurredAt?: Date;
      actor?: SiteHistoryActor | null;
      metadata?: Prisma.InputJsonValue;
    },
    tx?: Prisma.TransactionClient,
  ) {
    return this.writer.write(
      compactSiteHistoryInput({
        siteId: params.siteId,
        kind: SiteHistoryEntryKind.REPORT_REJECTED,
        reportId: params.reportId,
        occurredAt: params.occurredAt,
        actor: params.actor,
        metadata: params.metadata,
      }),
      { ...(tx != null ? { tx } : {}), emitSse: false },
    );
  }

  recordReportMerged(
    params: {
      siteId: string;
      reportId: string;
      occurredAt?: Date;
      actor?: SiteHistoryActor | null;
      metadata?: Prisma.InputJsonValue;
    },
    tx?: Prisma.TransactionClient,
  ) {
    return this.writer.write(
      compactSiteHistoryInput({
        siteId: params.siteId,
        kind: SiteHistoryEntryKind.REPORT_MERGED,
        reportId: params.reportId,
        occurredAt: params.occurredAt,
        actor: params.actor,
        metadata: params.metadata,
      }),
      { ...(tx != null ? { tx } : {}), emitSse: false },
    );
  }
}
