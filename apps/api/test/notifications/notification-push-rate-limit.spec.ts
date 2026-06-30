import {
  resetPushRateLimitForTest,
  shouldDeferVisiblePush,
} from '../../src/notifications/util/notification-push-rate-limit';

describe('notification-push-rate-limit', () => {
  beforeEach(() => {
    resetPushRateLimitForTest();
  });

  it('allows first pushes under limit', () => {
    expect(shouldDeferVisiblePush('user-1')).toBe(false);
    expect(shouldDeferVisiblePush('user-1')).toBe(false);
  });

  it('defers after max per window', () => {
    for (let i = 0; i < 5; i++) {
      expect(shouldDeferVisiblePush('user-2')).toBe(false);
    }
    expect(shouldDeferVisiblePush('user-2')).toBe(true);
  });
});
