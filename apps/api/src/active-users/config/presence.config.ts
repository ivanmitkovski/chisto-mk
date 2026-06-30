export const PRESENCE_CONFIG = {
  /** User is "online" when foreground + heartbeat within this window (default 5 min). */
  onlineWindowMs: Number(process.env.PRESENCE_ONLINE_WINDOW_MS ?? 5 * 60 * 1000),
  /** Redis TTL / ZSET score expiry — covers missed heartbeats + background grace. */
  ttlMs: Number(process.env.PRESENCE_TTL_MS ?? 90 * 1000),
  /** Debounce admin SSE publish after presence changes. */
  sseDebounceMs: 300,
  /** Debounce DB writes for lastActiveAt / lastSeenAt. */
  dbWriteDebounceMs: 60_000,
  /** Activity event retention (days). */
  activityRetentionDays: Number(process.env.ACTIVITY_RETENTION_DAYS ?? 30),
  /** Concurrent sampler interval. */
  samplerIntervalMs: 15_000,
} as const;

export const PRESENCE_REDIS_KEYS = {
  zset: 'presence:active',
  metaPrefix: 'presence:meta:',
  peakToday: 'presence:peak:today',
  peakWeek: 'presence:peak:week',
  avgStats: 'presence:avg:stats',
  trendSamples: 'presence:trend:samples',
  trendPrefix: 'presence:trend:',
  dauPrefix: 'presence:dau:',
  wauKey: 'presence:wau',
  mauKey: 'presence:mau',
} as const;

export function presenceMemberKey(userId: string, deviceId: string): string {
  return `${userId}:${deviceId}`;
}

export function presenceMetaKey(member: string): string {
  return `${PRESENCE_REDIS_KEYS.metaPrefix}${member}`;
}
