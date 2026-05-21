import { Injectable } from '@nestjs/common';
import { Prisma, SiteHistoryEntryKind } from '../../prisma-client';
import { SiteHistoryWriterService } from './site-history-writer.service';
import { compactSiteHistoryInput, type SiteHistoryActor } from './site-history-write.util';

@Injectable()
export class SiteHistoryEventRecorderService {
  constructor(private readonly writer: SiteHistoryWriterService) {}

  recordEventScheduled(
    params: {
      siteId: string;
      cleanupEventId: string;
      occurredAt?: Date;
      actor?: SiteHistoryActor | null;
    },
    tx?: Prisma.TransactionClient,
  ) {
    return this.writer.write(
      compactSiteHistoryInput({
        siteId: params.siteId,
        kind: SiteHistoryEntryKind.CLEANUP_EVENT_SCHEDULED,
        cleanupEventId: params.cleanupEventId,
        occurredAt: params.occurredAt,
        actor: params.actor,
      }),
      { ...(tx != null ? { tx } : {}), emitSse: false },
    );
  }

  recordEventStarted(
    params: {
      siteId: string;
      cleanupEventId: string;
      occurredAt?: Date;
      actor?: SiteHistoryActor | null;
    },
    tx?: Prisma.TransactionClient,
  ) {
    return this.writer.write(
      compactSiteHistoryInput({
        siteId: params.siteId,
        kind: SiteHistoryEntryKind.CLEANUP_EVENT_STARTED,
        cleanupEventId: params.cleanupEventId,
        occurredAt: params.occurredAt,
        actor: params.actor,
      }),
      { ...(tx != null ? { tx } : {}), emitSse: false },
    );
  }

  recordEventCompleted(
    params: {
      siteId: string;
      cleanupEventId: string;
      occurredAt?: Date;
      actor?: SiteHistoryActor | null;
    },
    tx?: Prisma.TransactionClient,
  ) {
    return this.writer.write(
      compactSiteHistoryInput({
        siteId: params.siteId,
        kind: SiteHistoryEntryKind.CLEANUP_EVENT_COMPLETED,
        cleanupEventId: params.cleanupEventId,
        occurredAt: params.occurredAt,
        actor: params.actor,
      }),
      { ...(tx != null ? { tx } : {}), emitSse: false },
    );
  }

  recordEventCancelled(
    params: {
      siteId: string;
      cleanupEventId: string;
      occurredAt?: Date;
      actor?: SiteHistoryActor | null;
    },
    tx?: Prisma.TransactionClient,
  ) {
    return this.writer.write(
      compactSiteHistoryInput({
        siteId: params.siteId,
        kind: SiteHistoryEntryKind.CLEANUP_EVENT_CANCELLED,
        cleanupEventId: params.cleanupEventId,
        occurredAt: params.occurredAt,
        actor: params.actor,
      }),
      { ...(tx != null ? { tx } : {}), emitSse: false },
    );
  }
}
