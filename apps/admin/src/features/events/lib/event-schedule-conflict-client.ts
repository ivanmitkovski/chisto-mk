import { adminBrowserFetch } from '@/lib/admin-browser-api';
import { ApiError } from '@/lib/api';

export type ConflictingEventInfo = {
  id: string;
  title: string;
  scheduledAt: string;
};

export type CheckScheduleConflictResponse = {
  hasConflict: boolean;
  conflictingEvent?: ConflictingEventInfo;
};

export async function fetchEventScheduleConflict(params: {
  siteId: string;
  scheduledAtIso: string;
  excludeEventId?: string;
}): Promise<CheckScheduleConflictResponse> {
  const q = new URLSearchParams({
    siteId: params.siteId,
    scheduledAt: params.scheduledAtIso,
  });
  if (params.excludeEventId != null && params.excludeEventId !== '') {
    q.set('excludeEventId', params.excludeEventId);
  }
  return adminBrowserFetch<CheckScheduleConflictResponse>(`/events/check-conflict?${q.toString()}`);
}

export function parseDuplicateEventConflictFromApiError(error: unknown): ConflictingEventInfo | null {
  if (!(error instanceof ApiError) || error.status !== 409 || error.code !== 'DUPLICATE_EVENT') {
    return null;
  }
  const details = error.details;
  if (details == null || typeof details !== 'object' || Array.isArray(details)) {
    return null;
  }
  const conflicting = (details as { conflictingEvent?: unknown }).conflictingEvent;
  if (conflicting == null || typeof conflicting !== 'object' || Array.isArray(conflicting)) {
    return null;
  }
  const row = conflicting as Record<string, unknown>;
  const id = row.id;
  const title = row.title;
  const scheduledAt = row.scheduledAt;
  if (typeof id !== 'string' || typeof title !== 'string' || typeof scheduledAt !== 'string') {
    return null;
  }
  return { id, title, scheduledAt };
}
