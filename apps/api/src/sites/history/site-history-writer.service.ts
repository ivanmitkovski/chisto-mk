import { Injectable } from '@nestjs/common';
import {
  Prisma,
  SiteHistoryEntryKind,
  SiteStatus,
} from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { SiteEventsService } from '../../admin-realtime/site-events.service';

export type SiteHistoryActor = {
  userId?: string | null;
  role?: string | null;
};

export type SiteHistoryWriteInput = {
  siteId: string;
  kind: SiteHistoryEntryKind;
  occurredAt?: Date;
  fromStatus?: SiteStatus | null;
  toStatus?: SiteStatus | null;
  reportId?: string | null;
  cleanupEventId?: string | null;
  actor?: SiteHistoryActor | null;
  note?: string | null;
  metadata?: Prisma.InputJsonValue;
};

@Injectable()
export class SiteHistoryWriterService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly siteEventsService: SiteEventsService,
  ) {}

  private client(tx?: Prisma.TransactionClient): Prisma.TransactionClient | PrismaService {
    return tx ?? this.prisma;
  }

  /** Strips undefined optional keys for exactOptionalPropertyTypes. */
  private compactInput(input: {
    siteId: string;
    kind: SiteHistoryEntryKind;
    occurredAt?: Date | undefined;
    fromStatus?: SiteStatus | null | undefined;
    toStatus?: SiteStatus | null | undefined;
    reportId?: string | null | undefined;
    cleanupEventId?: string | null | undefined;
    actor?: SiteHistoryActor | null | undefined;
    note?: string | null | undefined;
    metadata?: Prisma.InputJsonValue | undefined;
  }): SiteHistoryWriteInput {
    const out: SiteHistoryWriteInput = {
      siteId: input.siteId,
      kind: input.kind,
    };
    if (input.occurredAt !== undefined) out.occurredAt = input.occurredAt;
    if (input.fromStatus !== undefined) out.fromStatus = input.fromStatus;
    if (input.toStatus !== undefined) out.toStatus = input.toStatus;
    if (input.reportId !== undefined) out.reportId = input.reportId;
    if (input.cleanupEventId !== undefined) out.cleanupEventId = input.cleanupEventId;
    if (input.actor !== undefined) out.actor = input.actor;
    if (input.note !== undefined) out.note = input.note;
    if (input.metadata !== undefined) out.metadata = input.metadata;
    return out;
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
      this.compactInput({
        siteId: params.siteId,
        kind: SiteHistoryEntryKind.SITE_CREATED,
        occurredAt: params.occurredAt,
        toStatus: SiteStatus.REPORTED,
        actor: params.actor,
      }),
      { ...(tx != null ? { tx } : {}), emitSse: false },
    );
  }

  async recordReportSubmitted(
    params: {
      siteId: string;
      reportId: string;
      occurredAt?: Date;
      actor?: SiteHistoryActor | null;
    },
    tx?: Prisma.TransactionClient,
  ): Promise<{ id: string }> {
    return this.write(
      this.compactInput({
        siteId: params.siteId,
        kind: SiteHistoryEntryKind.REPORT_SUBMITTED,
        reportId: params.reportId,
        occurredAt: params.occurredAt,
        actor: params.actor,
      }),
      { ...(tx != null ? { tx } : {}), emitSse: false },
    );
  }

  async recordReportApproved(
    params: {
      siteId: string;
      reportId: string;
      occurredAt?: Date;
      actor?: SiteHistoryActor | null;
    },
    tx?: Prisma.TransactionClient,
  ): Promise<{ id: string }> {
    return this.write(
      this.compactInput({
        siteId: params.siteId,
        kind: SiteHistoryEntryKind.REPORT_APPROVED,
        reportId: params.reportId,
        occurredAt: params.occurredAt,
        actor: params.actor,
      }),
      { ...(tx != null ? { tx } : {}), emitSse: false },
    );
  }

  async recordReportRejected(
    params: {
      siteId: string;
      reportId: string;
      occurredAt?: Date;
      actor?: SiteHistoryActor | null;
      metadata?: Prisma.InputJsonValue;
    },
    tx?: Prisma.TransactionClient,
  ): Promise<{ id: string }> {
    return this.write(
      this.compactInput({
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

  async recordReportMerged(
    params: {
      siteId: string;
      reportId: string;
      occurredAt?: Date;
      actor?: SiteHistoryActor | null;
      metadata?: Prisma.InputJsonValue;
    },
    tx?: Prisma.TransactionClient,
  ): Promise<{ id: string }> {
    return this.write(
      this.compactInput({
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
      this.compactInput({
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

  async recordEventScheduled(
    params: {
      siteId: string;
      cleanupEventId: string;
      occurredAt?: Date;
      actor?: SiteHistoryActor | null;
    },
    tx?: Prisma.TransactionClient,
  ): Promise<{ id: string }> {
    return this.write(
      this.compactInput({
        siteId: params.siteId,
        kind: SiteHistoryEntryKind.CLEANUP_EVENT_SCHEDULED,
        cleanupEventId: params.cleanupEventId,
        occurredAt: params.occurredAt,
        actor: params.actor,
      }),
      { ...(tx != null ? { tx } : {}), emitSse: false },
    );
  }

  async recordEventStarted(
    params: {
      siteId: string;
      cleanupEventId: string;
      occurredAt?: Date;
      actor?: SiteHistoryActor | null;
    },
    tx?: Prisma.TransactionClient,
  ): Promise<{ id: string }> {
    return this.write(
      this.compactInput({
        siteId: params.siteId,
        kind: SiteHistoryEntryKind.CLEANUP_EVENT_STARTED,
        cleanupEventId: params.cleanupEventId,
        occurredAt: params.occurredAt,
        actor: params.actor,
      }),
      { ...(tx != null ? { tx } : {}), emitSse: false },
    );
  }

  async recordEventCompleted(
    params: {
      siteId: string;
      cleanupEventId: string;
      occurredAt?: Date;
      actor?: SiteHistoryActor | null;
    },
    tx?: Prisma.TransactionClient,
  ): Promise<{ id: string }> {
    return this.write(
      this.compactInput({
        siteId: params.siteId,
        kind: SiteHistoryEntryKind.CLEANUP_EVENT_COMPLETED,
        cleanupEventId: params.cleanupEventId,
        occurredAt: params.occurredAt,
        actor: params.actor,
      }),
      { ...(tx != null ? { tx } : {}), emitSse: false },
    );
  }

  async recordEventCancelled(
    params: {
      siteId: string;
      cleanupEventId: string;
      occurredAt?: Date;
      actor?: SiteHistoryActor | null;
    },
    tx?: Prisma.TransactionClient,
  ): Promise<{ id: string }> {
    return this.write(
      this.compactInput({
        siteId: params.siteId,
        kind: SiteHistoryEntryKind.CLEANUP_EVENT_CANCELLED,
        cleanupEventId: params.cleanupEventId,
        occurredAt: params.occurredAt,
        actor: params.actor,
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
      this.compactInput({
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
      this.compactInput({
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
      this.compactInput({
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
