import { randomBytes } from 'node:crypto';
import type { BroadcastAudience, BroadcastCampaign as BroadcastCampaignRow, BroadcastCampaignStatus } from '../../prisma-client';
import type { BroadcastCampaign, BroadcastCampaignStatus as ApiBroadcastCampaignStatus } from '../types/admin-broadcasts.types';

export function newBroadcastCampaignId(): string {
  return `bc_${Date.now()}_${randomBytes(4).toString('hex')}`;
}

const STATUS_TO_API: Record<BroadcastCampaignStatus, ApiBroadcastCampaignStatus> = {
  DRAFT: 'draft',
  SCHEDULED: 'scheduled',
  SENT: 'sent',
  CANCELLED: 'cancelled',
};

const STATUS_FROM_API: Record<ApiBroadcastCampaignStatus, BroadcastCampaignStatus> = {
  draft: 'DRAFT',
  scheduled: 'SCHEDULED',
  sent: 'SENT',
  cancelled: 'CANCELLED',
};

const AUDIENCE_TO_API: Record<BroadcastAudience, BroadcastCampaign['audience']> = {
  ALL: 'all',
  ACTIVE: 'active',
  AREA: 'area',
  USERS: 'users',
};

const AUDIENCE_FROM_API: Record<BroadcastCampaign['audience'], BroadcastAudience> = {
  all: 'ALL',
  active: 'ACTIVE',
  area: 'AREA',
  users: 'USERS',
};

export function toApiCampaign(row: BroadcastCampaignRow): BroadcastCampaign {
  return {
    id: row.id,
    title: row.title,
    body: row.body,
    type: row.type,
    deeplink: row.deeplink ?? undefined,
    audience: AUDIENCE_TO_API[row.audience],
    audienceUserIds: row.audienceUserIds.length > 0 ? row.audienceUserIds : undefined,
    status: STATUS_TO_API[row.status],
    scheduledAt: row.scheduledAt?.toISOString(),
    sentAt: row.sentAt?.toISOString(),
    sentCount: row.sentCount ?? undefined,
    createdAt: row.createdAt.toISOString(),
    updatedAt: row.updatedAt.toISOString(),
  };
}

export function audienceFromApi(audience: BroadcastCampaign['audience']): BroadcastAudience {
  return AUDIENCE_FROM_API[audience];
}

export function statusFromApi(status: ApiBroadcastCampaignStatus): BroadcastCampaignStatus {
  return STATUS_FROM_API[status];
}

export function parseOptionalDate(value: string | null | undefined): Date | null | undefined {
  if (value === undefined) return undefined;
  if (value === null || value.trim() === '') return null;
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    throw new Error('Invalid date');
  }
  return parsed;
}
