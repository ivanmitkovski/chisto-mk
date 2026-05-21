import {
  buildApnsConfig,
  buildAndroidFcmOptions,
  isEventChatClientDisplayed,
  resolveCollapseId,
  resolveThreadId,
} from '../../src/notifications/fcm-apns-payload';

describe('fcm-apns-payload', () => {
  it('EVENT_CHAT uses client-displayed APNS (no alert, wakes app)', () => {
    expect(
      isEventChatClientDisplayed({
        type: 'EVENT_CHAT',
        notificationType: 'EVENT_CHAT',
      }),
    ).toBe(true);
    const apns = buildApnsConfig({
      title: 'Chat',
      body: 'Hello',
      badge: 1,
      data: { type: 'EVENT_CHAT', eventId: 'ev-1', notificationType: 'EVENT_CHAT' },
    });
    expect(apns.headers['apns-push-type']).toBe('background');
    expect(apns.headers['apns-priority']).toBe('10');
    expect(apns.payload.aps['content-available']).toBe(1);
    expect(apns.payload.aps['alert']).toBeUndefined();
    expect(apns.payload.aps['category']).toBeUndefined();
  });

  it('sets time-sensitive interruption for non-chat alerts', () => {
    const apns = buildApnsConfig({
      title: 'Report',
      body: 'Updated',
      badge: 1,
      data: { type: 'REPORT_STATUS', notificationType: 'REPORT_STATUS' },
    });
    expect(apns.headers['apns-push-type']).toBe('alert');
    expect(apns.headers['apns-priority']).toBe('10');
    expect(apns.payload.aps['interruption-level']).toBe('active');
  });

  it('uses background push type for badge_sync', () => {
    const apns = buildApnsConfig({
      title: '',
      body: '',
      badge: 0,
      data: { kind: 'badge_sync' },
    });
    expect(apns.headers['apns-push-type']).toBe('background');
    expect(apns.payload.aps['content-available']).toBe(1);
  });

  it('resolves per-message collapse id for EVENT_CHAT', () => {
    expect(
      resolveCollapseId({
        notificationType: 'EVENT_CHAT',
        messageId: 'msg-abc',
        threadKey: 'event-chat:evt-1:msg-abc',
      }),
    ).toBe('EVENT_CHAT:msg:msg-abc');
  });

  it('android options use messageId tag for EVENT_CHAT', () => {
    const opts = buildAndroidFcmOptions({
      notificationType: 'EVENT_CHAT',
      messageId: 'msg-1',
      threadKey: 'event-chat:evt-1:msg-1',
      groupKey: 'event-chat:evt-1',
    });
    expect(opts.collapseKey).toBe('EVENT_CHAT:msg:msg-1');
    expect(opts.ttl).toBeGreaterThan(0);
    expect(opts.notification?.tag).toBe('msg:msg-1');
  });

  it('resolveThreadId prefers explicit threadId', () => {
    expect(resolveThreadId({ threadId: 'custom' })).toBe('custom');
  });
});
