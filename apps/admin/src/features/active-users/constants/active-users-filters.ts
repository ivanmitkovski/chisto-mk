export const ACTIVE_USERS_STATUS_OPTIONS = [
  { value: '', labelKey: 'filters.allStatuses' },
  { value: 'online', labelKey: 'status.online' },
  { value: 'away', labelKey: 'status.away' },
  { value: 'offline', labelKey: 'status.offline' },
] as const;

export const ACTIVE_USERS_PLATFORM_OPTIONS = [
  { value: '', labelKey: 'filters.allPlatforms' },
  { value: 'IOS', labelKey: 'platform.ios' },
  { value: 'ANDROID', labelKey: 'platform.android' },
] as const;

export const ACTIVE_USERS_FEED_TYPE_OPTIONS = [
  { value: '', labelKey: 'feed.allTypes' },
  { value: 'LOGIN', labelKey: 'feed.types.login' },
  { value: 'LOGOUT', labelKey: 'feed.types.logout' },
  { value: 'APP_OPENED', labelKey: 'feed.types.appOpened' },
  { value: 'SCREEN_VIEW', labelKey: 'feed.types.screenView' },
  { value: 'REPORT_SUBMITTED', labelKey: 'feed.types.reportSubmitted' },
  { value: 'REPORT_CREATED', labelKey: 'feed.types.reportCreated' },
  { value: 'EVENT_JOINED', labelKey: 'feed.types.eventJoined' },
  { value: 'CHECK_IN', labelKey: 'feed.types.checkIn' },
] as const;

export const ACTIVE_USERS_PAGE_SIZE = 25;

export const ADMIN_ALERT_METRICS = [
  'CONCURRENT',
  'TRAFFIC_SPIKE',
  'ERROR_RATE',
  'REPORT_ACTIVITY',
  'API_DEGRADATION',
] as const;

export type AdminAlertMetricValue = (typeof ADMIN_ALERT_METRICS)[number];
