/// <reference types="jest" />
import { NotificationDispatcherService } from '../../src/notifications/services/notification-dispatcher.service';
import { NotificationType } from '../../src/prisma-client';

function makeEvent() {
  return {
    title: 'Test title',
    body: 'Test body',
    type: NotificationType.SYSTEM,
    data: { kind: 'test_push' },
  };
}

function makeService(overrides: {
  fcmEnabled?: boolean;
  fcmReady?: boolean;
  tokens?: Array<{ token: string; platform: 'IOS' | 'ANDROID' }>;
} = {}) {
  const {
    fcmEnabled = true,
    fcmReady = true,
    tokens = [{ token: 'device-token-1', platform: 'IOS' as const }],
  } = overrides;

  const prisma = {
    userNotification: {
      count: jest.fn().mockResolvedValue(1),
      findUnique: jest.fn().mockResolvedValue(null),
      update: jest.fn().mockResolvedValue({}),
    },
    notificationOutbox: {
      createMany: jest.fn().mockResolvedValue({ count: 1 }),
    },
    userNotificationPreference: {
      findFirst: jest.fn().mockResolvedValue(null),
    },
    $executeRawUnsafe: jest.fn(),
  };

  const writer = {
    createNotification: jest.fn().mockResolvedValue({
      id: 'notif_1',
      updated: false,
    }),
  };

  const deviceTokens = {
    getActiveTokensForUser: jest.fn().mockResolvedValue(tokens),
  };

  const fcm = {
    isEnabled: jest.fn(() => fcmEnabled),
    isReady: jest.fn(() => fcmReady),
  };

  const emailOutbox = {
    enqueue: jest.fn().mockResolvedValue(undefined),
  };

  const roomEmitter = {
    emitNotificationNew: jest.fn(),
    emitNotificationUpdated: jest.fn(),
  };

  const featureFlags = {
    isPushRealtimeSocketEnabled: jest.fn().mockResolvedValue(false),
    isPushQuietHoursEnabled: jest.fn().mockResolvedValue(false),
  };

  const service = new NotificationDispatcherService(
    prisma as never,
    writer as never,
    deviceTokens as never,
    fcm as never,
    emailOutbox as never,
    roomEmitter as never,
    featureFlags as never,
  );

  return {
    service,
    prisma,
    writer,
    deviceTokens,
    fcm,
    emailOutbox,
  };
}

describe('NotificationDispatcherService push gate', () => {
  it('enqueues outbox rows when FCM is enabled, ready, and user has tokens', async () => {
    const { service, prisma, emailOutbox } = makeService();

    await service.dispatchToUser('user_1', makeEvent());

    expect(prisma.notificationOutbox.createMany).toHaveBeenCalledWith(
      expect.objectContaining({
        data: [
          expect.objectContaining({
            userNotificationId: 'notif_1',
            deviceToken: 'device-token-1',
            payload: expect.objectContaining({
              title: 'Test title',
              body: 'Test body',
              platform: 'IOS',
            }),
          }),
        ],
      }),
    );
    expect(emailOutbox.enqueue).toHaveBeenCalledWith('user_1', 'notif_1', makeEvent());
  });

  it('skips outbox when FCM is disabled and falls back to email only', async () => {
    const { service, prisma, emailOutbox } = makeService({ fcmEnabled: false });

    await service.dispatchToUser('user_1', makeEvent());

    expect(prisma.notificationOutbox.createMany).not.toHaveBeenCalled();
    expect(emailOutbox.enqueue).toHaveBeenCalledWith('user_1', 'notif_1', makeEvent());
  });

  it('skips outbox when FCM is not ready and falls back to email only', async () => {
    const { service, prisma, emailOutbox } = makeService({ fcmReady: false });

    await service.dispatchToUser('user_1', makeEvent());

    expect(prisma.notificationOutbox.createMany).not.toHaveBeenCalled();
    expect(emailOutbox.enqueue).toHaveBeenCalledWith('user_1', 'notif_1', makeEvent());
  });

  it('skips outbox when user has no active device tokens', async () => {
    const { service, prisma, emailOutbox } = makeService({ tokens: [] });

    await service.dispatchToUser('user_1', makeEvent());

    expect(prisma.notificationOutbox.createMany).not.toHaveBeenCalled();
    expect(emailOutbox.enqueue).toHaveBeenCalledWith('user_1', 'notif_1', makeEvent());
  });
});
