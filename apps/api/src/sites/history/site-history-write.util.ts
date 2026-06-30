import { Prisma, SiteHistoryEntryKind, SiteStatus } from '../../prisma-client';

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

export function compactSiteHistoryInput(input: {
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
