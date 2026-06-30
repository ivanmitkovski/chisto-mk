export type ActiveUsersSummary = {
  currentActive: number;
  online: number;
  away: number;
  offlineUsersEstimate: number;
  trend5m: number[];
  trend15m: number[];
  trend1h: number[];
  peakToday: number;
  peakWeek: number;
  avgConcurrent: number;
};

export type ActiveUserRow = {
  id: string;
  userId: string;
  deviceId: string;
  firstName: string;
  lastName: string;
  email: string;
  avatarUrl?: string | null;
  status: 'online' | 'away' | 'offline';
  currentScreen: string | null;
  platform: string | null;
  appVersion: string | null;
  lastActivity: string;
  sessionDurationSeconds: number;
  deviceModel: string | null;
  country: string | null;
  city: string | null;
  role: string;
};

export type ActivityFeedItem = {
  id: string;
  userId: string;
  displayName: string;
  type: string;
  screen: string | null;
  message: string;
  occurredAt: string;
};

export type EngagementAnalytics = {
  dau: number;
  wau: number;
  mau: number;
  dauMauRatio: number;
  avgSessionDurationMinutes: number;
  sessionsPerUser: number;
  reportsSubmittedToday: number;
  history: Array<{
    date: string;
    dau: number;
    wau: number;
    mau: number;
    peakConcurrent: number;
    avgConcurrent: number;
  }>;
};

export const EMPTY_ENGAGEMENT_ANALYTICS: EngagementAnalytics = {
  dau: 0,
  wau: 0,
  mau: 0,
  dauMauRatio: 0,
  avgSessionDurationMinutes: 0,
  sessionsPerUser: 0,
  reportsSubmittedToday: 0,
  history: [],
};

export type RealtimeAnalytics = {
  concurrent: number;
  activeReportDrafts: number;
  activeCleanupParticipants: number;
  reportsSubmittedToday: number;
  registrationsToday: number;
};

export const EMPTY_REALTIME_ANALYTICS: RealtimeAnalytics = {
  concurrent: 0,
  activeReportDrafts: 0,
  activeCleanupParticipants: 0,
  reportsSubmittedToday: 0,
  registrationsToday: 0,
};

export type GeoCluster = {
  country: string | null;
  city: string | null;
  count: number;
};

export type AdminAlertRule = {
  id: string;
  metric: string;
  comparator: string;
  threshold: number;
  windowSeconds: number;
  enabled: boolean;
  lastTriggeredAt: string | null;
};
