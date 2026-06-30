import { FcmPushService } from '../../src/notifications/services/fcm-push.service';
import { DevicePlatform } from '../../src/prisma-client';

describe('FcmPushService badge count', () => {
  const prisma = {
    userNotification: {
      count: jest.fn(),
    },
  };

  const service = new FcmPushService(null, prisma as never);

  beforeEach(() => {
    jest.clearAllMocks();
    (service as unknown as { app: unknown }).app = {};
  });

  it('uses unread count 0 in APNS payload when user has no unread notifications', async () => {
    prisma.userNotification.count.mockResolvedValue(0);
    const send = jest.fn().mockResolvedValue('msg-id');
    (service as unknown as { app: { messaging: () => { send: typeof send } } }).app = {
      messaging: () => ({ send }),
    };

    await service.sendToToken('token-1', {
      title: 'Test',
      body: 'Body',
      userId: 'user-1',
    });

    expect(send).toHaveBeenCalledTimes(1);
    const message = send.mock.calls[0][0] as {
      apns: { payload: { aps: { badge: number } } };
    };
    expect(message.apns.payload.aps.badge).toBe(0);
  });

  it('omits FCM notification block for EVENT_CHAT (client-displayed)', async () => {
    prisma.userNotification.count.mockResolvedValue(2);
    const send = jest.fn().mockResolvedValue('msg-id');
    (service as unknown as { app: { messaging: () => { send: typeof send } } }).app = {
      messaging: () => ({ send }),
    };

    await service.sendToToken('token-1', {
      title: 'Alice',
      body: 'Hello',
      userId: 'user-1',
      data: {
        type: 'EVENT_CHAT',
        notificationType: 'EVENT_CHAT',
        eventId: 'ev-1',
        messageId: 'msg-1',
      },
    });

    const message = send.mock.calls[0][0] as {
      notification?: { title: string; body: string };
      android: { notification?: { channelId: string } };
      apns: { headers: Record<string, string>; payload: { aps: Record<string, unknown> } };
    };
    expect(message.notification).toBeUndefined();
    expect(message.android.notification).toBeUndefined();
    expect(message.apns.headers['apns-push-type']).toBe('background');
    expect(message.apns.payload.aps['alert']).toBeUndefined();
    expect(message.apns.payload.aps['content-available']).toBe(1);
  });

  it('uses actual unread count when greater than zero', async () => {
    prisma.userNotification.count.mockResolvedValue(3);
    const send = jest.fn().mockResolvedValue('msg-id');
    (service as unknown as { app: { messaging: () => { send: typeof send } } }).app = {
      messaging: () => ({ send }),
    };

    await service.sendToToken('token-1', {
      title: 'Test',
      body: 'Body',
      userId: 'user-1',
    });

    const message = send.mock.calls[0][0] as {
      apns: { payload: { aps: { badge: number } } };
    };
    expect(message.apns.payload.aps.badge).toBe(3);
  });

  it('omits APNS block for ANDROID platform tokens', async () => {
    prisma.userNotification.count.mockResolvedValue(1);
    const send = jest.fn().mockResolvedValue('msg-id');
    (service as unknown as { app: { messaging: () => { send: typeof send } } }).app = {
      messaging: () => ({ send }),
    };

    await service.sendToToken('token-android', {
      title: 'Test',
      body: 'Body',
      userId: 'user-1',
      platform: DevicePlatform.ANDROID,
    });

    const message = send.mock.calls[0][0] as { apns?: unknown; android: unknown };
    expect(message.apns).toBeUndefined();
    expect(message.android).toBeDefined();
  });
});
