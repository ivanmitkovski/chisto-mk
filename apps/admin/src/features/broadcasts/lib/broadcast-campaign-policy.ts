import type { BroadcastAudience, BroadcastCampaign, BroadcastCampaignStatus } from '../types';

export type BroadcastFormValidationError =
  | 'titleRequired'
  | 'bodyRequired'
  | 'usersRequired'
  | 'deeplinkInvalid'
  | 'scheduleInvalid'
  | 'scheduleInPast';

/** @deprecated Use selected user IDs from form state directly. */
export function parseAudienceUserIds(text: string): string[] {
  return text
    .split(/[\s,]+/)
    .map((id) => id.trim())
    .filter(Boolean);
}

export function isBroadcastEditable(status: string): boolean {
  return status === 'draft' || status === 'scheduled';
}

export function isBroadcastDeletable(status: string): boolean {
  return status !== 'sent';
}

export function isBroadcastSendable(campaign: BroadcastCampaign): boolean {
  return campaign.status === 'draft' || campaign.status === 'scheduled';
}

export function isBroadcastCancellable(status: BroadcastCampaignStatus | string): boolean {
  return status === 'draft' || status === 'scheduled';
}

export function validateBroadcastForm(input: {
  title: string;
  body: string;
  audience: string;
  audienceUserIds: string[];
  deeplink?: string;
  scheduledAt?: string;
}): BroadcastFormValidationError | null {
  if (!input.title.trim()) return 'titleRequired';
  if (!input.body.trim()) return 'bodyRequired';
  if (input.audience === 'users' && input.audienceUserIds.length === 0) {
    return 'usersRequired';
  }
  const deeplink = input.deeplink?.trim() ?? '';
  if (deeplink && !/^\/[a-zA-Z0-9/_-]*$/.test(deeplink)) {
    return 'deeplinkInvalid';
  }
  const scheduledAt = input.scheduledAt?.trim() ?? '';
  if (scheduledAt) {
    const parsed = new Date(scheduledAt);
    if (Number.isNaN(parsed.getTime())) {
      return 'scheduleInvalid';
    }
    if (parsed.getTime() <= Date.now()) {
      return 'scheduleInPast';
    }
  }
  return null;
}

export function toDatetimeLocalValue(iso?: string): string {
  if (!iso) return '';
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return '';
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

export function fromDatetimeLocalValue(value: string): string | undefined {
  const trimmed = value.trim();
  if (!trimmed) return undefined;
  const date = new Date(trimmed);
  if (Number.isNaN(date.getTime())) return undefined;
  return date.toISOString();
}

type AudiencePreviewTranslator = {
  audienceLabel: (audience: BroadcastAudience) => string;
  recipientCap: (label: string) => string;
  userCount: (label: string, count: number) => string;
};

export function formatAudiencePreview(
  campaign: Pick<BroadcastCampaign, 'audience' | 'audienceUserIds'>,
  translate: AudiencePreviewTranslator,
): string {
  const label = translate.audienceLabel(campaign.audience as BroadcastAudience);
  if (campaign.audience === 'users' && campaign.audienceUserIds?.length) {
    return translate.userCount(label, campaign.audienceUserIds.length);
  }
  if (campaign.audience === 'active' || campaign.audience === 'all') {
    return translate.recipientCap(label);
  }
  return label;
}

export type BroadcastStatusFilter = 'all' | BroadcastCampaignStatus;

export function filterCampaignsByStatus<T extends { status: string }>(
  campaigns: T[],
  filter: BroadcastStatusFilter,
): T[] {
  if (filter === 'all') return campaigns;
  return campaigns.filter((campaign) => campaign.status === filter);
}
