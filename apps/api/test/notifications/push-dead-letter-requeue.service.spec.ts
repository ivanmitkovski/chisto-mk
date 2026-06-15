import { PushDeadLetterRequeueService } from '../../src/notifications/services/push-dead-letter-requeue.service';

describe('PushDeadLetterRequeueService', () => {
  const prisma = {
    notificationOutbox: {
      findMany: jest.fn(),
      updateMany: jest.fn(),
      update: jest.fn(),
      deleteMany: jest.fn(),
      findFirst: jest.fn(),
    },
    userDeviceToken: {
      findMany: jest.fn(),
      findFirst: jest.fn(),
    },
  };

  const service = new PushDeadLetterRequeueService(prisma as never);

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('requeues actionable dead letters with active tokens', async () => {
    prisma.notificationOutbox.findMany.mockResolvedValue([
      {
        id: 'dl-1',
        deviceToken: 'token-active',
        lastErrorCode: 'messaging/third-party-auth-error',
      },
      {
        id: 'dl-2',
        deviceToken: 'token-revoked',
        lastErrorCode: 'messaging/registration-token-not-registered',
      },
    ]);
    prisma.userDeviceToken.findMany.mockResolvedValue([{ token: 'token-active' }]);
    prisma.notificationOutbox.updateMany.mockResolvedValue({ count: 1 });

    const result = await service.requeueAll();

    expect(result).toEqual({ requeued: 1 });
    expect(prisma.notificationOutbox.updateMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: { in: ['dl-1'] } },
        data: expect.objectContaining({
          failedPermanently: false,
          attempts: 0,
        }),
      }),
    );
  });

  it('purges dead letters for revoked tokens and revoke error codes', async () => {
    prisma.notificationOutbox.findMany.mockResolvedValue([
      {
        id: 'dl-revoke-code',
        deviceToken: 'token-x',
        lastErrorCode: 'messaging/registration-token-not-registered',
      },
      {
        id: 'dl-revoked-token',
        deviceToken: 'token-revoked',
        lastErrorCode: 'messaging/third-party-auth-error',
      },
    ]);
    prisma.userDeviceToken.findMany.mockResolvedValue([{ token: 'token-revoked' }]);
    prisma.notificationOutbox.deleteMany.mockResolvedValue({ count: 2 });

    const result = await service.purgeTerminal();

    expect(result).toEqual({ purged: 2 });
    expect(prisma.notificationOutbox.deleteMany).toHaveBeenCalledWith({
      where: { id: { in: ['dl-revoke-code', 'dl-revoked-token'] } },
    });
  });

  it('requeues a single actionable dead letter', async () => {
    prisma.notificationOutbox.findFirst.mockResolvedValue({
      id: 'dl-1',
      deviceToken: 'token-active',
      lastErrorCode: 'messaging/third-party-auth-error',
    });
    prisma.userDeviceToken.findFirst.mockResolvedValue({ token: 'token-active' });
    prisma.notificationOutbox.update.mockResolvedValue({});

    const result = await service.requeueOne('dl-1');

    expect(result).toEqual({ requeued: true });
    expect(prisma.notificationOutbox.update).toHaveBeenCalled();
  });
});
