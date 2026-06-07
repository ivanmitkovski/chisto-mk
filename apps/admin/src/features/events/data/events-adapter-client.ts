/**
 * Browser-only cleanup event API calls (uses document cookie auth).
 * Do not import from Server Components; use events-adapter.ts there instead.
 */
import { adminBrowserFetch } from '@/lib/api';
import type {
  AuditLogAdminRow,
  CheckInRiskSignalRow,
  CheckInRiskSignalStatusFilter,
  CleanupEventDetail,
  CleanupEventModerationNoteRow,
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

export async function removeEventParticipantClient(
  eventId: string,
  userId: string,
): Promise<CleanupEventDetail> {
  return adminBrowserFetch<CleanupEventDetail>(
    `/admin/cleanup-events/${eventId}/participants/${userId}`,
    { method: 'DELETE' },
  );
}

export async function fetchEventNotesClient(
  eventId: string,
): Promise<{ data: CleanupEventModerationNoteRow[] }> {
  return adminBrowserFetch(`/admin/cleanup-events/${eventId}/notes`, { method: 'GET' });
}

export async function createEventNoteClient(
  eventId: string,
  body: string,
): Promise<CleanupEventModerationNoteRow> {
  return adminBrowserFetch(`/admin/cleanup-events/${eventId}/notes`, {
    method: 'POST',
    body: { body },
  });
}

export async function deleteEventNoteClient(
  eventId: string,
  noteId: string,
): Promise<{ deleted: boolean; noteId: string }> {
  return adminBrowserFetch(`/admin/cleanup-events/${eventId}/notes/${noteId}`, {
    method: 'DELETE',
  });
}

export async function fetchEventRiskSignalsClient(params: {
  eventId: string;
  page?: number;
  limit?: number;
  status?: CheckInRiskSignalStatusFilter;
}): Promise<{ data: CheckInRiskSignalRow[]; page: number; limit: number; total: number }> {
  const search = new URLSearchParams({
    page: String(params.page ?? 1),
    limit: String(params.limit ?? 50),
    eventId: params.eventId,
  });
  if (params.status) {
    search.set('status', params.status);
  }
  return adminBrowserFetch(`/admin/cleanup-events/check-in-risk-signals?${search.toString()}`, {
    method: 'GET',
  });
}

export async function patchEventRiskSignalClient(
  signalId: string,
  action: 'resolve' | 'dismiss',
): Promise<CheckInRiskSignalRow> {
  return adminBrowserFetch(`/admin/cleanup-events/check-in-risk-signals/${signalId}`, {
    method: 'PATCH',
    body: { action },
  });
}
