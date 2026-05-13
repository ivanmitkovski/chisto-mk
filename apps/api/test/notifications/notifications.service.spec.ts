/// <reference types="jest" />
import { NotificationInboxService } from '../../src/notifications/notification-inbox.service';

function makePrisma() {
  return {
    userNotification: {
      findMany: jest.fn(),
      count: jest.fn(),
      create: jest.fn(),
      findFirst: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
      groupBy: jest.fn(),
    },
    userDeviceToken: {
      findUnique: jest.fn(),
      update: jest.fn(),
      create: jest.fn(),
      findMany: jest.fn(),
    },
    notificationOutbox: {
      findMany: jest.fn(),
      count: jest.fn(),
    },
    featureFlag: {
      findUnique: jest.fn(),
    },
    $transaction: jest.fn(async (ops: Promise<unknown>[]) => Promise.all(ops)),
  };
}

function makeInboxFlags(inboxEnabled: boolean) {
  return {
    isNotificationsInboxEnabled: jest.fn().mockResolvedValue(inboxEnabled),
  };
}

describe('NotificationInboxService', () => {
  it('lists dead letters with masked token suffix', async () => {
    const prisma = makePrisma() as any;
    prisma.notificationOutbox.findMany.mockResolvedValue([
      {
        id: 'dl_1',
        userNotificationId: 'n_1',
        deviceToken: 'fcm_device_token_ABCDEFGH',
        attempts: 5,
        lastErrorCode: 'FCM_SEND_FAILED',
        lastErrorMessage: 'timeout',
        lastAttemptAt: new Date('2026-03-27T10:00:00.000Z'),
        createdAt: new Date('2026-03-27T09:00:00.000Z'),
      },
    ]);
    prisma.notificationOutbox.count.mockResolvedValue(1);

    const service = new NotificationInboxService(prisma, makeInboxFlags(true) as any);
    const result = await service.listDeadLetters(1, 20);

    expect(result.meta.total).toBe(1);
    expect(result.data[0].deviceTokenSuffix).toBe('ABCDEFGH');
    expect(result.data[0].lastErrorCode).toBe('FCM_SEND_FAILED');
  });

  it('returns empty list when inbox feature is disabled', async () => {
    const prisma = makePrisma() as any;

    const service = new NotificationInboxService(prisma, makeInboxFlags(false) as any);
    const result = await service.listForUser(
      { userId: 'u1' } as any,
      { page: 1, limit: 20 } as any,
    );

    expect(result.data).toEqual([]);
    expect(result.meta.unreadCount).toBe(0);
    expect(prisma.userNotification.findMany).not.toHaveBeenCalled();
  });
});
