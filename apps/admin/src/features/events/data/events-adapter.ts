import { serverAuthenticatedFetch } from '@/lib/auth/server-api-with-refresh';

export type CleanupEventModerationStatus = 'PENDING' | 'APPROVED' | 'DECLINED';

export type EcoEventLifecycleStatusKey =
  | 'UPCOMING'
  | 'IN_PROGRESS'
  | 'COMPLETED'
  | 'CANCELLED';

export type EcoEventCategoryKey =
  | 'GENERAL_CLEANUP'
  | 'RIVER_AND_LAKE'
  | 'TREE_AND_GREEN'
  | 'RECYCLING_DRIVE'
  | 'HAZARDOUS_REMOVAL'
  | 'AWARENESS_AND_EDUCATION'
  | 'OTHER';

export type EcoCleanupScaleKey = 'SMALL' | 'MEDIUM' | 'LARGE' | 'MASSIVE';

export type EcoEventDifficultyKey = 'EASY' | 'MODERATE' | 'HARD';

export type CleanupEventModerator = {
  id: string;
  email: string;
};

export type CleanupEventRow = {
  id: string;
  /** ISO8601; present from API for moderation queue ordering. */
  createdAt?: string;
  updatedAt?: string;
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
  moderatedAt?: string | null;
  moderatedBy?: CleanupEventModerator | null;
  declineReason?: string | null;
  recurrenceRule: string | null;
  category?: EcoEventCategoryKey;
  scale?: EcoCleanupScaleKey | null;
  difficulty?: EcoEventDifficultyKey | null;
  gear?: string[];
  maxParticipants?: number | null;
  checkInOpen?: boolean;
  checkedInCount?: number;
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
  afterImageUrls?: string[];
  afterImageKeys?: string[];
  organizer?: { id: string; displayName: string; email: string } | null;
  parentEventId?: string | null;
  recurrenceIndex?: number | null;
  seriesChildrenCount?: number;
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
  resolvedAt?: string | null;
  resolvedByUserId?: string | null;
  resolutionAction?: 'resolve' | 'dismiss' | null;
  eventId: string;
  eventTitle: string;
  userId: string;
  userDisplayName: string;
  signalType: string;
  metadata: unknown;
};

export type CheckInRiskSignalStatusFilter = 'active' | 'resolved' | 'all';

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
  const overview = await serverAuthenticatedFetch<{
    cleanupEvents: {
      upcoming: number;
      completed: number;
      pending?: number;
      totalParticipants?: number;
    };
  }>('/admin/overview', { method: 'GET' });
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
  return serverAuthenticatedFetch<ListResponse>(`/admin/cleanup-events?${search.toString()}`, {
    method: 'GET',
  });
}

export async function getCleanupEventDetail(id: string): Promise<CleanupEventDetail> {
  return serverAuthenticatedFetch<CleanupEventDetail>(`/admin/cleanup-events/${id}`, {
    method: 'GET',
  });
}

export function extractDeclineReasonFromAuditRows(rows: AuditLogAdminRow[]): string | null {
  for (const row of rows) {
    if (row.action !== 'CLEANUP_EVENT_DECLINED' || row.metadata == null || typeof row.metadata !== 'object') {
      continue;
    }
    const reason = (row.metadata as Record<string, unknown>).declineReason;
    if (typeof reason === 'string' && reason.trim()) {
      return reason.trim();
    }
  }
  return null;
}

export async function getCleanupEventDeclineReason(eventId: string): Promise<string | null> {
  const audit = await serverAuthenticatedFetch<{ data: AuditLogAdminRow[] }>(
    `/admin/cleanup-events/${encodeURIComponent(eventId)}/audit?page=1&limit=20`,
    { method: 'GET' },
  );
  return extractDeclineReasonFromAuditRows(audit.data);
}

export type CleanupEventModerationNoteRow = {
  id: string;
  createdAt: string;
  updatedAt: string;
  body: string;
  authorId: string | null;
  authorEmail: string | null;
};

export type EventAnalyticsAdminPayload = {
  totalJoiners: number;
  checkedInCount: number;
  attendanceRate: number;
  joinersCumulative: Array<{ at: string; cumulativeJoiners: number }>;
  checkInsByHour: Array<{ hour: number; count: number }>;
  generatedAt?: string;
  lastJoinAt?: string | null;
  lastCheckInAt?: string | null;
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
  status?: CheckInRiskSignalStatusFilter;
}): Promise<CheckInRiskSignalsResponse> {
  const page = params?.page ?? 1;
  const limit = Math.min(100, Math.max(1, params?.limit ?? 50));
  const search = new URLSearchParams({
    page: String(page),
    limit: String(limit),
  });
  if (params?.status) {
    search.set('status', params.status);
  }
  return serverAuthenticatedFetch<CheckInRiskSignalsResponse>(
    `/admin/cleanup-events/check-in-risk-signals?${search.toString()}`,
    {
      method: 'GET',
    },
  );
}

export async function patchCheckInRiskSignal(
  id: string,
  action: 'resolve' | 'dismiss',
): Promise<CheckInRiskSignalRow> {
  return serverAuthenticatedFetch<CheckInRiskSignalRow>(`/admin/cleanup-events/check-in-risk-signals/${id}`, {
    method: 'PATCH',
    body: { action },
  });
}
