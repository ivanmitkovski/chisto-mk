/// <reference types="jest" />
import { PushDeliveryWorkerService } from '../../src/notifications/push-delivery-worker.service';

function makePrisma() {
  const notificationOutbox = {
    findMany: jest.fn(),
    updateMany: jest.fn(),
    update: jest.fn(),
    count: jest.fn(),
  };
  const userNotification = {
    findMany: jest.fn().mockResolvedValue([]),
  };
  return {
    notificationOutbox,
    userNotification,
    $transaction: jest.fn(async (ops: Promise<unknown>[]) => Promise.all(ops)),
  };
}

function makeFcm() {
  return {
    isEnabled: jest.fn(() => true),
    isReady: jest.fn(() => true),
    sendToToken: jest.fn(),
    revokeToken: jest.fn(),
    incrementFailureCount: jest.fn(),
  };
}

describe('PushDeliveryWorkerService', () => {
  it('claims, delivers, and clears lease fields on success', async () => {
    const prisma = makePrisma() as any;
    const fcm = makeFcm() as any;

    prisma.notificationOutbox.count.mockResolvedValue(0);
    prisma.notificationOutbox.findMany
      .mockResolvedValueOnce([
        {
          id: 'out_1',
          userNotificationId: 'n_1',
          deviceToken: 'token-12345678',
          payload: { title: 'T', body: 'B', data: {} },
          attempts: 0,
          lastAttemptAt: null,
          deliveredAt: null,
          failedPermanently: false,
        },
      ])
      .mockResolvedValueOnce([
        {
          id: 'out_1',
          userNotificationId: 'n_1',
          deviceToken: 'token-12345678',
          payload: { title: 'T', body: 'B', data: {} },
          attempts: 0,
          lastAttemptAt: null,
          deliveredAt: null,
          failedPermanently: false,
        },
      ]);
    prisma.notificationOutbox.updateMany.mockResolvedValue({ count: 1 });
    fcm.sendToToken.mockResolvedValue({ success: true });

    const service = new PushDeliveryWorkerService(prisma, fcm);
    const delivered = await service.processOutbox();

    expect(delivered).toBe(1);
    expect(prisma.notificationOutbox.updateMany).toHaveBeenCalled();
    expect(prisma.notificationOutbox.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'out_1' },
        data: expect.objectContaining({
          deliveredAt: expect.any(Date),
          processingAt: null,
          leaseOwner: null,
        }),
      }),
    );
  });

  it('schedules retry and tracks failure on transient send error', async () => {
    const prisma = makePrisma() as any;
    const fcm = makeFcm() as any;

    prisma.notificationOutbox.count.mockResolvedValue(0);
    prisma.notificationOutbox.findMany
      .mockResolvedValueOnce([
        {
          id: 'out_2',
          userNotificationId: 'n_2',
          deviceToken: 'token-abcdefgh',
          payload: { title: 'T', body: 'B', data: {} },
          attempts: 1,
          lastAttemptAt: null,
          deliveredAt: null,
          failedPermanently: false,
        },
      ])
      .mockResolvedValueOnce([
        {
          id: 'out_2',
          userNotificationId: 'n_2',
          deviceToken: 'token-abcdefgh',
          payload: { title: 'T', body: 'B', data: {} },
          attempts: 1,
          lastAttemptAt: null,
          deliveredAt: null,
          failedPermanently: false,
        },
      ]);
    prisma.notificationOutbox.updateMany.mockResolvedValue({ count: 1 });
    fcm.sendToToken.mockResolvedValue({ success: false, shouldRevoke: false });

    const service = new PushDeliveryWorkerService(prisma, fcm);
    await service.processOutbox();

    expect(fcm.incrementFailureCount).toHaveBeenCalledWith('token-abcdefgh');
    expect(prisma.notificationOutbox.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'out_2' },
        data: expect.objectContaining({
          nextRetryAt: expect.any(Date),
          lastErrorCode: 'FCM_SEND_FAILED',
          processingAt: null,
          leaseOwner: null,
        }),
      }),
    );
  });
});

