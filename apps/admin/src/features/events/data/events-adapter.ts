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
    cleanupEvents: {
      upcoming: number;
      completed: number;
      pending?: number;
      totalParticipants?: number;
    };
  }>('/admin/overview', { method: 'GET', authToken: token });
  const upcoming = overview.cleanupEvents?.upcoming ?? 0;
  const completed = overview.cleanupEvents?.completed ?? 0;
  const pending = overview.cleanupEvents?.pending ?? 0;
  return {
    /** Counts every cleanup row represented in the overview buckets (excludes declined-only, etc.). */
    total: upcoming + completed + pending,
    upcoming,
    completed,
    pending,
    totalParticipants: overview.cleanupEvents?.totalParticipants ?? 0,
  };
}

export async function getCleanupEvents(params?: {
  page?: number;
  limit?: number;
  status?: 'upcoming' | 'completed';
  moderationStatus?: CleanupEventModerationStatus;
  /** Min length 2; passed as `q` to admin list (ILIKE title/description). */
  q?: string;
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
  const trimmedQ = params?.q?.trim();
  if (trimmedQ != null && trimmedQ.length >= 2) {
    search.set('q', trimmedQ);
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

export type EventAnalyticsAdminPayload = {
  totalJoiners: number;
  checkedInCount: number;
  attendanceRate: number;
  joinersCumulative: Array<{ at: string; cumulativeJoiners: number }>;
  checkInsByHour: Array<{ hour: number; count: number }>;
};

export type AuditLogAdminRow = {
  id: string;
  createdAt: string;
  action: string;
  resourceType: string;
  resourceId: string | null;
  actorEmail: string | null;
  metadata: unknown;
};

export type CleanupEventParticipantAdminRow = {
  userId: string;
  joinedAt: string;
  displayName: string;
  email: string;
};

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
