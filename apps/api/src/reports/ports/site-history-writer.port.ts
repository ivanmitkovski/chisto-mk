import type { Prisma } from '../../prisma-client';
import type { SiteHistoryActor } from '../../sites/history/site-history-write.util';

export const SITE_HISTORY_WRITER = Symbol('SITE_HISTORY_WRITER');

export interface SiteHistoryWriterPort {
  recordSiteCreated(
    params: {
      siteId: string;
      occurredAt?: Date;
      actor?: SiteHistoryActor | null;
    },
    tx?: Prisma.TransactionClient,
  ): Promise<{ id: string }>;

  emitHistoryAppended(siteId: string, entryId: string): void;
}
