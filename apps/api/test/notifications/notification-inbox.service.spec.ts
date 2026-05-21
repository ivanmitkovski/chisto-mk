/// <reference types="jest" />
import { NotificationInboxService } from '../../src/notifications/notification-inbox.service';

function makePrisma() {
  return {
    userNotification: {
      findMany: jest.fn(),
      count: jest.fn(),
      groupBy: jest.fn(),
    },
    user: {
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

function makeReportsUpload() {
  return {
    signPrivateObjectKey: jest.fn().mockResolvedValue('https://cdn.test/avatar.jpg'),
  };
}

function makeFlags(inboxEnabled: boolean) {
  return {
    isNotificationsInboxEnabled: jest.fn().mockResolvedValue(inboxEnabled),
  };
}

describe('NotificationInboxService', () => {
  it('listForUser returns paginated results excluding archived', async () => {
    const prisma = makePrisma() as any;
    const now = new Date();
    prisma.userNotification.findMany.mockResolvedValue([
      {
        id: 'n1', title: 'Test', body: 'Body', type: 'UPVOTE',
        isRead: false, data: null, createdAt: now, sentAt: null,
        threadKey: null, groupKey: null, archivedAt: null,
      },
    ]);
    prisma.userNotification.count
      .mockResolvedValueOnce(1)
      .mockResolvedValueOnce(1);

    prisma.user.findMany.mockResolvedValue([]);

    const service = new NotificationInboxService(
      prisma,
      makeFlags(true) as any,
      makeReportsUpload() as any,
    );
    const result = await service.listForUser(
      { userId: 'u1' } as any,
      { page: 1, limit: 20 } as any,
    );

    expect(result.data).toHaveLength(1);
    expect(result.meta.unreadCount).toBe(1);
    expect(prisma.userNotification.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ archivedAt: null }),
      }),
    );
  });

  it('getUnreadCount excludes archived', async () => {
    const prisma = makePrisma() as any;
    prisma.userNotification.count.mockResolvedValue(3);

    const service = new NotificationInboxService(
      prisma,
      makeFlags(true) as any,
      makeReportsUpload() as any,
    );
    const result = await service.getUnreadCount({ userId: 'u1' } as any);

    expect(result.unreadCount).toBe(3);
    expect(prisma.userNotification.count).toHaveBeenCalledWith({
      where: { userId: 'u1', isRead: false, archivedAt: null },
    });
  });

  it('returns empty when inbox feature is disabled', async () => {
    const prisma = makePrisma() as any;
    const service = new NotificationInboxService(
      prisma,
      makeFlags(false) as any,
      makeReportsUpload() as any,
    );

    const result = await service.listForUser(
      { userId: 'u1' } as any,
      { page: 1, limit: 20 } as any,
    );
    expect(result.data).toEqual([]);
  });

  it('getSummary groups by type and read status', async () => {
    const prisma = makePrisma() as any;
    prisma.userNotification.groupBy.mockResolvedValue([
      { type: 'UPVOTE', isRead: false, _count: 3 },
      { type: 'UPVOTE', isRead: true, _count: 2 },
      { type: 'COMMENT', isRead: false, _count: 1 },
    ]);

    const service = new NotificationInboxService(
      prisma,
      makeFlags(true) as any,
      makeReportsUpload() as any,
    );
    const result = await service.getSummary({ userId: 'u1' } as any);

    const upvote = result.data.find((d: any) => d.type === 'UPVOTE');
    expect(upvote?.total).toBe(5);
    expect(upvote?.unread).toBe(3);

    const comment = result.data.find((d: any) => d.type === 'COMMENT');
    expect(comment?.total).toBe(1);
    expect(comment?.unread).toBe(1);
  });

  it('listForUser attaches actor when data.actorUserId is set', async () => {
    const prisma = makePrisma() as any;
    const now = new Date();
    prisma.userNotification.findMany.mockResolvedValue([
      {
        id: 'n1',
        title: 'Upvote',
        body: 'Body',
        type: 'UPVOTE',
        isRead: false,
        data: { siteId: 's1', actorUserId: 'actor-1' },
        createdAt: now,
        sentAt: null,
        threadKey: null,
        groupKey: 'UPVOTE:site:s1',
        archivedAt: null,
      },
    ]);
    prisma.userNotification.count
      .mockResolvedValueOnce(1)
      .mockResolvedValueOnce(1);
    prisma.user.findMany.mockResolvedValue([
      {
        id: 'actor-1',
        firstName: 'Ana',
        lastName: 'K',
        avatarObjectKey: 'avatars/a1.jpg',
      },
    ]);

    const upload = makeReportsUpload();
    const service = new NotificationInboxService(
      prisma,
      makeFlags(true) as any,
      upload as any,
    );
    const result = await service.listForUser(
      { userId: 'u1' } as any,
      { page: 1, limit: 20 } as any,
    );

    expect(result.data[0].actor).toEqual({
      id: 'actor-1',
      displayName: 'Ana K',
      avatarUrl: 'https://cdn.test/avatar.jpg',
    });
    expect(upload.signPrivateObjectKey).toHaveBeenCalledWith('avatars/a1.jpg');
  });

  it('listGrouped collapses EVENT_CHAT rows with the same groupKey', async () => {
    const prisma = makePrisma() as any;
    const t1 = new Date('2026-05-20T12:00:00Z');
    const t2 = new Date('2026-05-20T12:01:00Z');
    prisma.userNotification.findMany.mockResolvedValue([
      {
        id: 'c1',
        title: 'Clean it',
        body: 'Ana: hi',
        type: 'EVENT_CHAT',
        isRead: false,
        data: { eventId: 'evt-1', messageCount: 2 },
        createdAt: t1,
        sentAt: null,
        threadKey: 'event-chat:evt-1:msg-2',
        groupKey: 'event-chat:evt-1',
        archivedAt: null,
      },
      {
        id: 'c2',
        title: 'Clean it',
        body: 'Ana: earlier',
        type: 'EVENT_CHAT',
        isRead: false,
        data: { eventId: 'evt-1', messageCount: 1 },
        createdAt: t2,
        sentAt: null,
        threadKey: 'event-chat:evt-1:msg-1',
        groupKey: 'event-chat:evt-1',
        archivedAt: null,
      },
    ]);
    prisma.userNotification.count
      .mockResolvedValueOnce(2)
      .mockResolvedValueOnce(2);
    prisma.user.findMany.mockResolvedValue([]);

    const service = new NotificationInboxService(
      prisma,
      makeFlags(true) as any,
      makeReportsUpload() as any,
    );
    const result = await service.listGrouped(
      { userId: 'u1' } as any,
      { page: 1, limit: 20 } as any,
    );

    expect(result.data).toHaveLength(1);
    expect(result.data[0].groupCount).toBe(2);
  });
});
