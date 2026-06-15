/// <reference types="jest" />
import { PushDeliveryWorkerService } from '../../src/notifications/services/push-delivery-worker.service';
import { PushDeliveryOutboxService } from '../../src/notifications/services/push-delivery-outbox.service';
import { PushDeliverySenderService } from '../../src/notifications/services/push-delivery-sender.service';

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
  const userDeviceToken = {
    findMany: jest.fn().mockResolvedValue([]),
  };
  return {
    notificationOutbox,
    userNotification,
    userDeviceToken,
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
    maybeSendBadgeSync: jest.fn(),
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

    const sender = new PushDeliverySenderService(prisma, fcm);
    const outbox = new PushDeliveryOutboxService(prisma, fcm, sender);
    const service = new PushDeliveryWorkerService(fcm, outbox);
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

    const sender = new PushDeliverySenderService(prisma, fcm);
    const outbox = new PushDeliveryOutboxService(prisma, fcm, sender);
    const service = new PushDeliveryWorkerService(fcm, outbox);
    await service.processOutbox();

    expect(fcm.incrementFailureCount).toHaveBeenCalledWith('token-abcdefgh');
    expect(prisma.notificationOutbox.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'out_2' },
        data: expect.objectContaining({
          nextRetryAt: expect.any(Date),
          lastErrorCode: 'FCM_SEND_FAILED',
          lastErrorMessage: 'FCM error FCM_SEND_FAILED after attempt 2',
          processingAt: null,
          leaseOwner: null,
        }),
      }),
    );
  });

  it('persists real FCM error code on transient send failure', async () => {
    const prisma = makePrisma() as any;
    const fcm = makeFcm() as any;

    prisma.notificationOutbox.count.mockResolvedValue(0);
    prisma.notificationOutbox.findMany
      .mockResolvedValueOnce([
        {
          id: 'out_3',
          userNotificationId: 'n_3',
          deviceToken: 'token-servererr',
          payload: { title: 'T', body: 'B', data: {} },
          attempts: 2,
          lastAttemptAt: null,
          deliveredAt: null,
          failedPermanently: false,
        },
      ])
      .mockResolvedValueOnce([
        {
          id: 'out_3',
          userNotificationId: 'n_3',
          deviceToken: 'token-servererr',
          payload: { title: 'T', body: 'B', data: {} },
          attempts: 2,
          lastAttemptAt: null,
          deliveredAt: null,
          failedPermanently: false,
        },
      ]);
    prisma.notificationOutbox.updateMany.mockResolvedValue({ count: 1 });
    fcm.sendToToken.mockResolvedValue({
      success: false,
      shouldRevoke: false,
      errorCode: 'messaging/server-unavailable',
    });

    const sender = new PushDeliverySenderService(prisma, fcm);
    const outbox = new PushDeliveryOutboxService(prisma, fcm, sender);
    const service = new PushDeliveryWorkerService(fcm, outbox);
    await service.processOutbox();

    expect(prisma.notificationOutbox.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'out_3' },
        data: expect.objectContaining({
          lastErrorCode: 'messaging/server-unavailable',
          lastErrorMessage: 'FCM error messaging/server-unavailable after attempt 3',
        }),
      }),
    );
  });

  it('revokes token immediately on mismatched-credential without retry increment path', async () => {
    const prisma = makePrisma() as any;
    const fcm = makeFcm() as any;

    prisma.notificationOutbox.count.mockResolvedValue(0);
    prisma.notificationOutbox.findMany
      .mockResolvedValueOnce([
        {
          id: 'out_4',
          userNotificationId: 'n_4',
          deviceToken: 'token-mismatch',
          payload: { title: 'T', body: 'B', data: {} },
          attempts: 0,
          lastAttemptAt: null,
          deliveredAt: null,
          failedPermanently: false,
        },
      ])
      .mockResolvedValueOnce([
        {
          id: 'out_4',
          userNotificationId: 'n_4',
          deviceToken: 'token-mismatch',
          payload: { title: 'T', body: 'B', data: {} },
          attempts: 0,
          lastAttemptAt: null,
          deliveredAt: null,
          failedPermanently: false,
        },
      ]);
    prisma.notificationOutbox.updateMany.mockResolvedValue({ count: 1 });
    fcm.sendToToken.mockResolvedValue({
      success: false,
      shouldRevoke: true,
      errorCode: 'messaging/mismatched-credential',
    });

    const sender = new PushDeliverySenderService(prisma, fcm);
    const outbox = new PushDeliveryOutboxService(prisma, fcm, sender);
    const service = new PushDeliveryWorkerService(fcm, outbox);
    await service.processOutbox();

    expect(fcm.revokeToken).toHaveBeenCalledWith('token-mismatch');
    expect(fcm.incrementFailureCount).not.toHaveBeenCalled();
    expect(prisma.notificationOutbox.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'out_4' },
        data: expect.objectContaining({
          failedPermanently: true,
          lastErrorCode: 'messaging/mismatched-credential',
          lastErrorMessage: 'Push token revoked or invalid (messaging/mismatched-credential)',
        }),
      }),
    );
  });

  it('fails permanently on third-party-auth-error without retrying or revoking token', async () => {
    const prisma = makePrisma() as any;
    const fcm = makeFcm() as any;

    prisma.notificationOutbox.count.mockResolvedValue(0);
    prisma.notificationOutbox.findMany
      .mockResolvedValueOnce([
        {
          id: 'out_5',
          userNotificationId: 'n_5',
          deviceToken: 'token-apns',
          payload: { title: 'T', body: 'B', data: {} },
          attempts: 0,
          lastAttemptAt: null,
          deliveredAt: null,
          failedPermanently: false,
        },
      ])
      .mockResolvedValueOnce([
        {
          id: 'out_5',
          userNotificationId: 'n_5',
          deviceToken: 'token-apns',
          payload: { title: 'T', body: 'B', data: {} },
          attempts: 0,
          lastAttemptAt: null,
          deliveredAt: null,
          failedPermanently: false,
        },
      ]);
    prisma.notificationOutbox.updateMany.mockResolvedValue({ count: 1 });
    prisma.userDeviceToken.findMany.mockResolvedValue([
      { token: 'token-apns', platform: 'IOS' },
    ]);
    fcm.sendToToken.mockResolvedValue({
      success: false,
      isConfigError: true,
      errorCode: 'messaging/third-party-auth-error',
    });

    const sender = new PushDeliverySenderService(prisma, fcm);
    const outbox = new PushDeliveryOutboxService(prisma, fcm, sender);
    const service = new PushDeliveryWorkerService(fcm, outbox);
    await service.processOutbox();

    expect(fcm.revokeToken).not.toHaveBeenCalled();
    expect(fcm.incrementFailureCount).not.toHaveBeenCalled();
    expect(prisma.notificationOutbox.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'out_5' },
        data: expect.objectContaining({
          failedPermanently: true,
          attempts: 1,
          lastErrorCode: 'messaging/third-party-auth-error',
          lastErrorMessage: expect.stringContaining('FCM misconfiguration'),
        }),
      }),
    );
  });
});
