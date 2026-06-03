/** Per-user visible push rate limit (digest collapsing). */

const WINDOW_MS = 60_000;
const MAX_VISIBLE_PER_WINDOW = 5;

type WindowState = {
  count: number;
  windowStart: number;
  deferred: Array<{ at: number; eventSummary: string }>;
};

const byUser = new Map<string, WindowState>();

export function shouldDeferVisiblePush(
  userId: string,
  notificationType?: string,
): boolean {
  if (notificationType === 'EVENT_CHAT') {
    return false;
  }
  const now = Date.now();
  let state = byUser.get(userId);
  if (!state || now - state.windowStart >= WINDOW_MS) {
    state = { count: 0, windowStart: now, deferred: [] };
    byUser.set(userId, state);
  }
  if (state.count >= MAX_VISIBLE_PER_WINDOW) {
    return true;
  }
  state.count += 1;
  return false;
}

export function resetPushRateLimitForTest(): void {
  byUser.clear();
}
