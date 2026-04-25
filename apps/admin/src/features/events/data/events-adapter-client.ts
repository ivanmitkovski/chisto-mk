/**
 * Browser-only cleanup event API calls (uses document cookie auth).
 * Do not import from Server Components; use events-adapter.ts there instead.
 */
import { adminBrowserFetch } from '@/lib/admin-browser-api';
import type {
  AuditLogAdminRow,
  CleanupEventParticipantAdminRow,
  EventAnalyticsAdminPayload,
} from '@/features/events/data/events-adapter';

export async function fetchCleanupEventAnalyticsClient(
  id: string,
): Promise<EventAnalyticsAdminPayload> {
  return adminBrowserFetch<EventAnalyticsAdminPayload>(`/admin/cleanup-events/${id}/analytics`, {
    method: 'GET',
  });
}

export async function fetchCleanupEventAuditClient(
  id: string,
  page = 1,
  limit = 50,
): Promise<{ data: AuditLogAdminRow[]; meta: { page: number; limit: number; total: number } }> {
  const search = new URLSearchParams({ page: String(page), limit: String(limit) });
  return adminBrowserFetch(`/admin/cleanup-events/${id}/audit?${search.toString()}`, {
    method: 'GET',
  });
}

export async function fetchCleanupEventParticipantsClient(
  id: string,
): Promise<{ data: CleanupEventParticipantAdminRow[] }> {
  return adminBrowserFetch(`/admin/cleanup-events/${id}/participants`, {
    method: 'GET',
  });
}
