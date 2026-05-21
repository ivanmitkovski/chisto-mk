/** APNS / FCM payload helpers (Instagram/Slack-style delivery metadata). */

const APNS_TTL_SECONDS = 4 * 60 * 60;

export type FcmPushData = Record<string, string> | undefined;

export function isSilentBadgeSync(data?: FcmPushData): boolean {
  return data?.['kind'] === 'badge_sync';
}

/** EVENT_CHAT banners are shown by the mobile app (inline reply requires local notifications). */
export function isEventChatClientDisplayed(data?: FcmPushData): boolean {
  if (isSilentBadgeSync(data)) {
    return false;
  }
  const type = data?.['notificationType'] ?? data?.['type'];
  return type === 'EVENT_CHAT';
}

export function resolveCollapseId(data?: FcmPushData): string | undefined {
  const explicit = data?.['collapseId'];
  if (explicit && explicit.length > 0) {
    return explicit.slice(0, 64);
  }
  const type = data?.['notificationType'] ?? data?.['type'];
  const messageId = data?.['messageId'];
  if (type === 'EVENT_CHAT' && messageId && messageId.length > 0) {
    return `EVENT_CHAT:msg:${messageId}`.slice(0, 64);
  }
  if (data?.['notificationId']) {
    return `notif:${data['notificationId']}`.slice(0, 64);
  }
  const threadKey = data?.['threadKey'] ?? data?.['groupKey'];
  if (threadKey && type) {
    return `${type}:${threadKey}`.slice(0, 64);
  }
  return undefined;
}

export function resolveThreadId(data?: FcmPushData): string | undefined {
  const explicit = data?.['threadId'];
  if (explicit) return explicit.slice(0, 128);
  const eventId = data?.['eventId'];
  const type = data?.['notificationType'] ?? data?.['type'];
  if (type === 'EVENT_CHAT' && eventId) {
    return `event_chat:${eventId}`.slice(0, 128);
  }
  const threadKey = data?.['threadKey'] ?? data?.['groupKey'];
  if (threadKey) return threadKey.slice(0, 128);
  return type ? String(type).slice(0, 128) : undefined;
}

export function resolveInterruptionLevel(data?: FcmPushData): string {
  if (isSilentBadgeSync(data)) return 'passive';
  const type = data?.['notificationType'] ?? data?.['type'];
  switch (type) {
    case 'EVENT_CHAT':
      return 'time-sensitive';
    case 'SYSTEM':
    case 'ACHIEVEMENT':
    case 'WELCOME':
      return 'passive';
    default:
      return 'active';
  }
}

export function resolveRelevanceScore(data?: FcmPushData): number {
  if (isSilentBadgeSync(data)) return 0;
  const type = data?.['notificationType'] ?? data?.['type'];
  switch (type) {
    case 'EVENT_CHAT':
      return 0.9;
    case 'REPORT_STATUS':
    case 'NEARBY_REPORT':
      return 0.75;
    case 'CLEANUP_EVENT':
      return 0.7;
    case 'UPVOTE':
    case 'COMMENT':
      return 0.5;
    default:
      return 0.6;
  }
}

export function resolveApnsCategory(data?: FcmPushData): string | undefined {
  const type = data?.['notificationType'] ?? data?.['type'];
  switch (type) {
    case 'EVENT_CHAT':
      return 'EVENT_CHAT_MESSAGE';
    case 'REPORT_STATUS':
    case 'NEARBY_REPORT':
      return 'REPORT_UPDATE';
    case 'CLEANUP_EVENT':
      return 'CLEANUP_EVENT';
    default:
      return type ? `CHISTO_${type}` : undefined;
  }
}

export function apnsExpirationUnix(): string {
  return String(Math.floor(Date.now() / 1000) + APNS_TTL_SECONDS);
}

export function buildApnsConfig(input: {
  title: string;
  body: string;
  subtitle?: string;
  badge: number;
  data?: FcmPushData;
  /** When true, no APNS alert — client shows the visible banner with reply actions. */
  clientDisplayed?: boolean;
}): {
  headers: Record<string, string>;
  payload: { aps: Record<string, unknown> };
  fcmOptions?: { imageUrl?: string };
} {
  const silent = isSilentBadgeSync(input.data);
  const clientDisplayed =
    input.clientDisplayed === true || isEventChatClientDisplayed(input.data);
  const headers: Record<string, string> = {
    'apns-push-type': silent || clientDisplayed ? 'background' : 'alert',
    'apns-priority': silent ? '5' : '10',
    'apns-expiration': apnsExpirationUnix(),
  };
  const collapseId = resolveCollapseId(input.data);
  if (collapseId) {
    headers['apns-collapse-id'] = collapseId;
  }

  if (silent || clientDisplayed) {
    return {
      headers,
      payload: {
        aps: {
          'content-available': 1,
          badge: input.badge,
        },
      },
    };
  }

  const threadId = resolveThreadId(input.data);
  const aps: Record<string, unknown> = {
    alert: {
      title: input.title,
      ...(input.subtitle ? { subtitle: input.subtitle } : {}),
      body: input.body,
    },
    sound: 'default',
    badge: input.badge,
    'mutable-content': 1,
    'interruption-level': resolveInterruptionLevel(input.data),
    'relevance-score': resolveRelevanceScore(input.data),
  };
  if (threadId) {
    aps['thread-id'] = threadId;
  }
  const category = resolveApnsCategory(input.data);
  if (category) {
    aps.category = category;
  }

  return { headers, payload: { aps } };
}

export function buildAndroidFcmOptions(data?: FcmPushData): {
  collapseKey?: string;
  ttl: number;
  notification?: { tag?: string };
} {
  const collapseKey = resolveCollapseId(data);
  const type = data?.['notificationType'] ?? data?.['type'];
  const messageId = data?.['messageId'];
  const tag =
    type === 'EVENT_CHAT' && messageId && messageId.length > 0
      ? `msg:${messageId}`.slice(0, 64)
      : (data?.['threadKey'] ?? data?.['groupKey'])?.slice(0, 64);
  return {
    ...(collapseKey ? { collapseKey } : {}),
    ttl: APNS_TTL_SECONDS * 1000,
    ...(tag ? { notification: { tag } } : {}),
  };
}
