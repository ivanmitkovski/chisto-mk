/// <reference types="jest" />
import { NotificationStateService } from '../../src/notifications/notification-state.service';

function makePrisma() {
  return {
    userNotification: {
      findFirst: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
    },
  };
}

describe('NotificationStateService', () => {
  it('markOneRead skips already-read notifications', async () => {
    const prisma = makePrisma() as any;
    prisma.userNotification.findFirst.mockResolvedValue({ id: 'n1', isRead: true });

    const service = new NotificationStateService(prisma);
    await service.markOneRead({ userId: 'u1' } as any, 'n1');

    expect(prisma.userNotification.update).not.toHaveBeenCalled();
  });

  it('markOneRead updates unread notification', async () => {
    const prisma = makePrisma() as any;
    prisma.userNotification.findFirst.mockResolvedValue({ id: 'n1', isRead: false });
    prisma.userNotification.update.mockResolvedValue({});

    const service = new NotificationStateService(prisma);
    await service.markOneRead({ userId: 'u1' } as any, 'n1');

    expect(prisma.userNotification.update).toHaveBeenCalledWith({
      where: { id: 'n1' },
      data: { isRead: true },
    });
  });

  it('markOneRead throws for non-existent notification', async () => {
    const prisma = makePrisma() as any;
    prisma.userNotification.findFirst.mockResolvedValue(null);

    const service = new NotificationStateService(prisma);
    await expect(service.markOneRead({ userId: 'u1' } as any, 'n99'))
      .rejects
      .toThrow();
  });

  it('markOneUnread reverts read notification to unread', async () => {
    const prisma = makePrisma() as any;
    prisma.userNotification.findFirst.mockResolvedValue({ id: 'n1', isRead: true });
    prisma.userNotification.update.mockResolvedValue({});

    const service = new NotificationStateService(prisma);
    await service.markOneUnread({ userId: 'u1' } as any, 'n1');

    expect(prisma.userNotification.update).toHaveBeenCalledWith({
      where: { id: 'n1' },
      data: { isRead: false },
    });
  });

  it('markAllRead updates all unread', async () => {
    const prisma = makePrisma() as any;
    prisma.userNotification.updateMany.mockResolvedValue({ count: 5 });

    const service = new NotificationStateService(prisma);
    const result = await service.markAllRead({ userId: 'u1' } as any);

    expect(result.updated).toBe(5);
  });

  it('archiveOne sets archivedAt', async () => {
    const prisma = makePrisma() as any;
    prisma.userNotification.findFirst.mockResolvedValue({ id: 'n1' });
    prisma.userNotification.update.mockResolvedValue({});

    const service = new NotificationStateService(prisma);
    await service.archiveOne({ userId: 'u1' } as any, 'n1');

    expect(prisma.userNotification.update).toHaveBeenCalledWith({
      where: { id: 'n1' },
      data: expect.objectContaining({ archivedAt: expect.any(Date) }),
    });
  });

  it('archiveAllRead batch archives read items', async () => {
    const prisma = makePrisma() as any;
    prisma.userNotification.updateMany.mockResolvedValue({ count: 3 });

    const service = new NotificationStateService(prisma);
    const result = await service.archiveAllRead({ userId: 'u1' } as any);

    expect(result.updated).toBe(3);
    expect(prisma.userNotification.updateMany).toHaveBeenCalledWith({
      where: { userId: 'u1', isRead: true, archivedAt: null },
      data: expect.objectContaining({ archivedAt: expect.any(Date) }),
    });
  });
});
