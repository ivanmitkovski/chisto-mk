/// <reference types="jest" />
import { PushDeliverySenderService } from '../../src/notifications/services/push-delivery-sender.service';

function makePrisma(platformFromDb: 'IOS' | 'ANDROID' | null = 'IOS') {
  return {
    notificationOutbox: {
      update: jest.fn().mockResolvedValue({}),
    },
    userDeviceToken: {
      findMany: jest.fn().mockResolvedValue(
        platformFromDb
          ? [{ token: 'token-android', platform: platformFromDb }]
          : [],
      ),
    },
  };
}

function makeFcm() {
  return {
    sendToToken: jest.fn().mockResolvedValue({ success: true }),
    maybeSendBadgeSync: jest.fn(),
  };
}

describe('PushDeliverySenderService', () => {
  it('prefers platform from outbox payload over DB token lookup', async () => {
    const prisma = makePrisma('IOS');
    const fcm = makeFcm();
    const sender = new PushDeliverySenderService(prisma as never, fcm as never);

    const delivered = await sender.deliverClaimed(
      [
        {
          id: 'out_1',
          userNotificationId: 'n_1',
          deviceToken: 'token-android',
          attempts: 0,
          lastAttemptAt: null,
          payload: {
            title: 'T',
            body: 'B',
            platform: 'ANDROID',
            unreadCount: 2,
            data: {},
          },
        },
      ],
      new Map([['n_1', 'user_1']]),
    );

    expect(delivered).toBe(1);
    expect(fcm.sendToToken).toHaveBeenCalledWith(
      'token-android',
      expect.objectContaining({ platform: 'ANDROID' }),
    );
  });

  it('falls back to DB token lookup when payload has no platform', async () => {
    const prisma = makePrisma('IOS');
    const fcm = makeFcm();
    const sender = new PushDeliverySenderService(prisma as never, fcm as never);

    await sender.deliverClaimed(
      [
        {
          id: 'out_2',
          userNotificationId: 'n_2',
          deviceToken: 'token-android',
          attempts: 0,
          lastAttemptAt: null,
          payload: { title: 'T', body: 'B', data: {} },
        },
      ],
      new Map(),
    );

    expect(fcm.sendToToken).toHaveBeenCalledWith(
      'token-android',
      expect.objectContaining({ platform: 'IOS' }),
    );
  });
});
