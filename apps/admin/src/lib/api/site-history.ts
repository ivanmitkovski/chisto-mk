import { adminBrowserFetch } from './admin-browser-api';

export type SiteHistoryEntryRow = {
  id: string;
  kind: string;
  occurredAt: string;
  fromStatus: string | null;
  toStatus: string | null;
  reportId: string | null;
  cleanupEventId: string | null;
  actor: { id: string; displayName: string | null; isDeleted: boolean; role: string | null } | null;
  note: string | null;
  metadata: Record<string, unknown> | null;
};

export type SiteHistoryListResponse = {
  items: SiteHistoryEntryRow[];
  nextBeforeId: string | null;
};

export async function fetchSiteHistory(
  siteId: string,
  params?: { limit?: number; beforeId?: string },
): Promise<SiteHistoryListResponse> {
  const search = new URLSearchParams();
  if (params?.limit != null) search.set('limit', String(params.limit));
  if (params?.beforeId) search.set('beforeId', params.beforeId);
  const qs = search.toString();
  return adminBrowserFetch<SiteHistoryListResponse>(
    `/sites/${siteId}/history${qs ? `?${qs}` : ''}`,
    { method: 'GET' },
  );
}

export async function postSiteHistoryNote(
  siteId: string,
  body: { note: string; occurredAt?: string },
): Promise<SiteHistoryEntryRow> {
  return adminBrowserFetch<SiteHistoryEntryRow>(`/sites/${siteId}/history/notes`, {
    method: 'POST',
    body,
  });
}
