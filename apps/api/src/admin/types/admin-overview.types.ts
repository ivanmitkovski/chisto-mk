export type AdminOverviewStats = {
  reportsByStatus: Record<string, number>;
  sitesByStatus: Record<string, number>;
  duplicateGroupsCount: number;
  cleanupEvents: {
    upcoming: number;
    completed: number;
    pending: number;
    totalParticipants: number;
    upcomingEvents: Array<{ id: string; name: string; date: string }>;
  };
  usersCount: number;
  usersNewLast7d: number;
  sessionsActive: number;
  reportsTrend: Array<{ date: string; count: number }>;
  recentActivity: Array<{
    id: string;
    createdAt: string;
    action: string;
    resourceType: string;
    resourceId: string | null;
    actorEmail: string | null;
  }>;
  feedDiagnostics: {
    reasonCodes: Array<{ code: string; count: number }>;
    rankDriftSnapshot: Array<{ siteId: string; score: number; reasons: string[] }>;
    recentIntegrityDemotions: number;
  };
};

export type AdminSecuritySession = {
  id: string;
  device: string;
  location: string;
  ipAddress: string;
  lastActiveLabel: string;
  isCurrent: boolean;
};

export type AdminSecurityActivityTone = 'success' | 'warning' | 'info';

export type AdminSecurityActivityEvent = {
  id: string;
  title: string;
  detail: string;
  occurredAtLabel: string;
  tone: AdminSecurityActivityTone;
  icon: string;
};

export type AdminSecurityOverview = {
  sessions: AdminSecuritySession[];
  activity: AdminSecurityActivityEvent[];
};
