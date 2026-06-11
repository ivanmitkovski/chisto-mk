import { DevicePlatform } from '../../prisma-client';

export type PresenceAppState = 'foreground' | 'background';

export type PresenceMeta = {
  userId: string;
  deviceId: string;
  sessionId: string | null;
  screen: string;
  platform: DevicePlatform | string;
  appVersion: string | null;
  deviceModel: string | null;
  osVersion: string | null;
  sessionStart: string;
  appState: PresenceAppState;
  country: string | null;
  city: string | null;
  lastActivityAt: string;
};

export type PresenceStatus = 'online' | 'away' | 'offline';

export type ActiveUserRow = {
  id: string;
  userId: string;
  deviceId: string;
  firstName: string;
  lastName: string;
  email: string;
  avatarUrl: string | null;
  status: PresenceStatus;
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

export type ActivityFeedItem = {
  id: string;
  userId: string;
  displayName: string;
  type: string;
  screen: string | null;
  message: string;
  occurredAt: string;
};

export type ActiveUsersUpdatedEvent = {
  type: 'active_users_updated';
  summary: Pick<ActiveUsersSummary, 'currentActive' | 'online' | 'away' | 'peakToday'>;
};

export type ActivityEventRealtime = {
  type: 'activity_event';
  event: ActivityFeedItem;
};

export type AlertTriggeredEvent = {
  type: 'alert_triggered';
  ruleId: string;
  metric: string;
  value: number;
  threshold: number;
  message: string;
};
