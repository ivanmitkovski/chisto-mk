import { serverAuthenticatedFetch } from '@/lib/auth/server-api-with-refresh';
import type { BroadcastCampaign } from '../types';

export async function listBroadcastCampaigns(): Promise<BroadcastCampaign[]> {
  return serverAuthenticatedFetch<BroadcastCampaign[]>('/admin/broadcasts', {
    method: 'GET',
  });
}

export async function getBroadcastCampaign(id: string): Promise<BroadcastCampaign> {
  return serverAuthenticatedFetch<BroadcastCampaign>(`/admin/broadcasts/${encodeURIComponent(id)}`, {
    method: 'GET',
  });
}
