import { adminBrowserFetch } from '@/lib/api';
import type { BroadcastAudience } from '../types';
import type { BroadcastUserLookupRow } from '../lib/format-user-display-label';

export const BROADCAST_RECIPIENT_CAP = 5000;

export type AudiencePreviewResult = {
  recipientCount: number;
  capped: boolean;
  cap: number;
};

export async function previewBroadcastAudience(input: {
  audience: BroadcastAudience;
  audienceUserIds?: string[];
}): Promise<AudiencePreviewResult> {
  return adminBrowserFetch<AudiencePreviewResult>('/admin/broadcasts/audience-preview', {
    method: 'POST',
    body: input,
  });
}

export async function lookupBroadcastAudienceUsers(
  userIds: string[],
): Promise<{ users: BroadcastUserLookupRow[] }> {
  return adminBrowserFetch<{ users: BroadcastUserLookupRow[] }>('/admin/broadcasts/audience-users/lookup', {
    method: 'POST',
    body: { userIds },
  });
}
