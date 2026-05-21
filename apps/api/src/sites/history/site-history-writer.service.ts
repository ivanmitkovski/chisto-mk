import { Injectable } from '@nestjs/common';
import {
  Prisma,
  SiteHistoryEntryKind,
  SiteStatus,
} from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { SiteEventsService } from '../../admin-realtime/site-events.service';
import {
  compactSiteHistoryInput,
  type SiteHistoryActor,
  type SiteHistoryWriteInput,
} from './site-history-write.util';

export type { SiteHistoryActor, SiteHistoryWriteInput } from './site-history-write.util';

@Injectable()
export class SiteHistoryWriterService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly siteEventsService: SiteEventsService,
  ) {}

  private client(tx?: Prisma.TransactionClient): Prisma.TransactionClient | PrismaService {
    return tx ?? this.prisma;
  }

  async write(
    input: SiteHistoryWriteInput,
    options?: { tx?: Prisma.TransactionClient; emitSse?: boolean },
  ): Promise<{ id: string }> {
    const compact = input;
    const db = this.client(options?.tx);
    const entry = await db.siteHistoryEntry.create({
      data: {
        siteId: compact.siteId,
        kind: compact.kind,
        occurredAt: compact.occurredAt ?? new Date(),
        fromStatus: compact.fromStatus ?? null,
        toStatus: compact.toStatus ?? null,
        reportId: compact.reportId ?? null,
        cleanupEventId: compact.cleanupEventId ?? null,
        actorUserId: compact.actor?.userId ?? null,
        actorRole: compact.actor?.role ?? null,
        note: compact.note ?? null,
        ...(compact.metadata !== undefined ? { metadata: compact.metadata } : {}),
      },
      select: { id: true, siteId: true },
    });

    if (options?.emitSse !== false && !options?.tx) {
      this.emitHistoryAppended(entry.siteId, entry.id);
    }

    return entry;
  }

  emitHistoryAppended(siteId: string, _entryId: string): void {
    this.siteEventsService.emitSiteUpdated(siteId, { kind: 'updated' });
  }

  async recordSiteCreated(
    params: {
      siteId: string;
      occurredAt?: Date;
      actor?: SiteHistoryActor | null;
    },
    tx?: Prisma.TransactionClient,
  ): Promise<{ id: string }> {
    return this.write(
      compactSiteHistoryInput({
        siteId: params.siteId,
        kind: SiteHistoryEntryKind.SITE_CREATED,
        occurredAt: params.occurredAt,
        toStatus: SiteStatus.REPORTED,
        actor: params.actor,
      }),
      { ...(tx != null ? { tx } : {}), emitSse: false },
    );
  }

  async recordStatusChanged(
    params: {
      siteId: string;
      fromStatus: SiteStatus;
      toStatus: SiteStatus;
      occurredAt?: Date;
      actor?: SiteHistoryActor | null;
      reportId?: string | null;
      cleanupEventId?: string | null;
      metadata?: Prisma.InputJsonValue;
      note?: string | null;
    },
    tx?: Prisma.TransactionClient,
  ): Promise<{ id: string }> {
    return this.write(
      compactSiteHistoryInput({
        siteId: params.siteId,
        kind: SiteHistoryEntryKind.STATUS_CHANGED,
        fromStatus: params.fromStatus,
        toStatus: params.toStatus,
        occurredAt: params.occurredAt,
        actor: params.actor,
        reportId: params.reportId ?? null,
        cleanupEventId: params.cleanupEventId ?? null,
        metadata: params.metadata,
        note: params.note,
      }),
      { ...(tx != null ? { tx } : {}), emitSse: false },
    );
  }

  async recordArchived(
    params: {
      siteId: string;
      occurredAt?: Date;
      actor?: SiteHistoryActor | null;
      note?: string | null;
    },
    tx?: Prisma.TransactionClient,
  ): Promise<{ id: string }> {
    return this.write(
      compactSiteHistoryInput({
        siteId: params.siteId,
        kind: SiteHistoryEntryKind.ARCHIVED_BY_ADMIN,
        occurredAt: params.occurredAt,
        actor: params.actor,
        note: params.note,
      }),
      { ...(tx != null ? { tx } : {}), emitSse: false },
    );
  }

  async recordUnarchived(
    params: {
      siteId: string;
      occurredAt?: Date;
      actor?: SiteHistoryActor | null;
    },
    tx?: Prisma.TransactionClient,
  ): Promise<{ id: string }> {
    return this.write(
      compactSiteHistoryInput({
        siteId: params.siteId,
        kind: SiteHistoryEntryKind.UNARCHIVED_BY_ADMIN,
        occurredAt: params.occurredAt,
        actor: params.actor,
      }),
      { ...(tx != null ? { tx } : {}), emitSse: false },
    );
  }

  async recordAdminNote(
    params: {
      siteId: string;
      note: string;
      occurredAt?: Date;
      actor?: SiteHistoryActor | null;
    },
    tx?: Prisma.TransactionClient,
  ): Promise<{ id: string }> {
    return this.write(
      compactSiteHistoryInput({
        siteId: params.siteId,
        kind: SiteHistoryEntryKind.ADMIN_NOTE,
        note: params.note,
        occurredAt: params.occurredAt,
        actor: params.actor,
      }),
      { ...(tx != null ? { tx } : {}) },
    );
  }
}
