export const OPS_POLL_INTERVAL_MS = 60_000;
export const OPS_PROBE_TIMEOUT_MS = 8_000;
export const OPS_MAP_DEEP_TIMEOUT_MS = 15_000;
export const OPS_DEAD_LETTERS_PAGE_SIZE = 5;

export const OPS_THRESHOLDS = {
  pushQueueDepthWarn: 25,
  pushQueueDepthCritical: 100,
  pushDeadLettersWarn: 1,
  mapOutboxPendingWarn: 50,
  mapOutboxPendingCritical: 100,
  mapDeepLatencyWarnMs: 250,
  sideEffectsPendingWarn: 10,
  sideEffectsPendingCritical: 50,
  openRateWarn: 0.05,
  emailDeadLettersWarn: 1,
  emailQueueDepthWarn: 10,
  emailQueueDepthCritical: 50,
} as const;

export const METRIC_HISTORY_STORAGE_KEY = 'chisto_admin_ops_metric_history';
export const METRIC_HISTORY_MAX_POINTS = 60;

export const METRIC_HISTORY_KEYS = [
  'pushSendsSuccess',
  'pushSendsFailure',
  'pushQueueDepth',
  'pushDeadLetterCount',
  'mapOutboxPending',
  'requestsFailed',
  'emailQueueDepth',
] as const;

export type MetricHistoryKey = (typeof METRIC_HISTORY_KEYS)[number];
