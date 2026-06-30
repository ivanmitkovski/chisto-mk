import { adminBrowserFetch } from '@/lib/api';
import type { BroadcastCampaign, BroadcastCampaignFormValues, BroadcastDeliveryReport } from '../types';
import { fromDatetimeLocalValue } from '../lib/broadcast-campaign-policy';

function buildAudiencePayload(values: BroadcastCampaignFormValues, mode: 'create' | 'update' = 'create') {
  const audienceUserIds = values.selectedAudienceUsers.map((user) => user.id);
  const scheduledAt = fromDatetimeLocalValue(values.scheduledAt);
  return {
    title: values.title.trim(),
    body: values.body.trim(),
    audience: values.audience,
    ...(values.deeplink.trim() ? { deeplink: values.deeplink.trim() } : {}),
    ...(values.audience === 'users' ? { audienceUserIds } : {}),
    ...(scheduledAt
      ? { scheduledAt }
      : mode === 'update'
        ? { scheduledAt: null }
        : {}),
  };
}

export async function listBroadcastCampaignsClient(): Promise<BroadcastCampaign[]> {
  return adminBrowserFetch<BroadcastCampaign[]>('/admin/broadcasts', { method: 'GET' });
}

export async function createBroadcastCampaign(values: BroadcastCampaignFormValues): Promise<BroadcastCampaign> {
  return adminBrowserFetch<BroadcastCampaign>('/admin/broadcasts', {
    method: 'POST',
    body: buildAudiencePayload(values),
  });
}

export async function updateBroadcastCampaign(
  id: string,
  values: BroadcastCampaignFormValues,
): Promise<BroadcastCampaign> {
  return adminBrowserFetch<BroadcastCampaign>(`/admin/broadcasts/${encodeURIComponent(id)}`, {
    method: 'PATCH',
    body: buildAudiencePayload(values, 'update'),
  });
}

export async function deleteBroadcastCampaign(id: string): Promise<void> {
  await adminBrowserFetch<{ deleted: boolean }>(`/admin/broadcasts/${encodeURIComponent(id)}`, {
    method: 'DELETE',
  });
}

export async function sendBroadcastCampaign(
  id: string,
  idempotencyKey?: string,
): Promise<BroadcastDeliveryReport> {
  return adminBrowserFetch<BroadcastDeliveryReport>(`/admin/broadcasts/${encodeURIComponent(id)}/send`, {
    method: 'POST',
    ...(idempotencyKey ? { idempotencyKey } : {}),
  });
}

export async function cancelBroadcastCampaign(id: string): Promise<BroadcastCampaign> {
  return adminBrowserFetch<BroadcastCampaign>(`/admin/broadcasts/${encodeURIComponent(id)}/cancel`, {
    method: 'PATCH',
  });
}

export async function fetchBroadcastCampaign(id: string): Promise<BroadcastCampaign> {
  return adminBrowserFetch<BroadcastCampaign>(`/admin/broadcasts/${encodeURIComponent(id)}`, {
    method: 'GET',
  });
}
