import { apiFetch } from '@/lib/api';
import { getAdminAuthTokenFromCookies } from '@/features/auth/lib/admin-auth-server';

export type CleanupEventModerationStatus = 'PENDING' | 'APPROVED' | 'DECLINED';

export type EcoEventLifecycleStatusKey =
  | 'UPCOMING'
  | 'IN_PROGRESS'
  | 'COMPLETED'
  | 'CANCELLED';

export type CleanupEventRow = {
  id: string;
  /** ISO8601; present from API for moderation queue ordering. */
  createdAt?: string;
  title: string;
  description: string;
  siteId: string;
  scheduledAt: string;
  /** ISO8601 when set; legacy rows may omit null. */
  endAt?: string | null;
  completedAt: string | null;
  organizerId: string | null;
  participantCount: number;
  status: CleanupEventModerationStatus;
  lifecycleStatus: EcoEventLifecycleStatusKey;
  recurrenceRule: string | null;
  site: {
    id: string;
    latitude: number;
    longitude: number;
    description: string | null;
    status: string;
  };
};

export type CleanupEventDetail = CleanupEventRow & {
  site: CleanupEventRow['site'];
};

export type EventsStats = {
  total: number;
  upcoming: number;
  completed: number;
  pending: number;
  totalParticipants: number;
};

export type CheckInRiskSignalRow = {
  id: string;
  createdAt: string;
  expiresAt: string;
  eventId: string;
  eventTitle: string;
  userId: string;
  userDisplayName: string;
  signalType: string;
  metadata: unknown;
};

export type CheckInRiskSignalsResponse = {
  data: CheckInRiskSignalRow[];
  page: number;
  limit: number;
  total: number;
};

type ListResponse = {
  data: CleanupEventRow[];
  meta: { page: number; limit: number; total: number };
};

export async function getEventsStats(): Promise<EventsStats> {
  const token = await getAdminAuthTokenFromCookies();
  const overview = await apiFetch<{
    cleanupEvents: { upcoming: number; completed: number; pending?: number };
  }>('/admin/overview', { method: 'GET', authToken: token });
  const upcoming = overview.cleanupEvents?.upcoming ?? 0;
  const completed = overview.cleanupEvents?.completed ?? 0;
  const pending = overview.cleanupEvents?.pending ?? 0;
  return {
    total: upcoming + completed,
    upcoming,
    completed,
    pending,
    totalParticipants: 0,
  };
}

export async function getCleanupEvents(params?: {
  page?: number;
  limit?: number;
  status?: 'upcoming' | 'completed';
  moderationStatus?: CleanupEventModerationStatus;
}): Promise<ListResponse> {
  const token = await getAdminAuthTokenFromCookies();
  const page = params?.page ?? 1;
  const limit = params?.limit ?? 20;
  const search = new URLSearchParams({ page: String(page), limit: String(limit) });
  if (params?.status) {
    search.set('status', params.status);
  }
  if (params?.moderationStatus) {
    search.set('moderationStatus', params.moderationStatus);
  }
  return apiFetch<ListResponse>(`/admin/cleanup-events?${search.toString()}`, {
    method: 'GET',
    authToken: token,
  });
}

export async function getCleanupEventDetail(id: string): Promise<CleanupEventDetail> {
  const token = await getAdminAuthTokenFromCookies();
  return apiFetch<CleanupEventDetail>(`/admin/cleanup-events/${id}`, {
    method: 'GET',
    authToken: token,
  });
}

export async function getCheckInRiskSignals(params?: {
  page?: number;
  limit?: number;
}): Promise<CheckInRiskSignalsResponse> {
  const token = await getAdminAuthTokenFromCookies();
  const page = params?.page ?? 1;
  const limit = Math.min(100, Math.max(1, params?.limit ?? 50));
  const search = new URLSearchParams({
    page: String(page),
    limit: String(limit),
  });
  return apiFetch<CheckInRiskSignalsResponse>(
    `/admin/cleanup-events/check-in-risk-signals?${search.toString()}`,
    {
      method: 'GET',
      authToken: token,
    },
  );
}
