import { NotificationType } from '../../src/prisma-client';
import { EventEndSoonNotifierService } from '../../src/events/event-end-soon-notifier.service';
import { NotificationDispatcherService } from '../../src/notifications/notification-dispatcher.service';
import { PrismaService } from '../../src/prisma/prisma.service';

describe(EventEndSoonNotifierService.name, () => {
  it('dispatches once per claimed row', async () => {
    const prisma = {
      $queryRaw: jest.fn().mockResolvedValue([
        {
          id: 'evt-1',
          organizerId: 'org-1',
          title: 'River day',
          endAt: new Date('2026-06-15T12:00:00.000Z'),
        },
      ]),
    } as unknown as PrismaService;
    const dispatchToUser = jest.fn().mockResolvedValue(undefined);
    const dispatcher = {
      dispatchToUser,
    } as unknown as NotificationDispatcherService;

    const svc = new EventEndSoonNotifierService(prisma, dispatcher);
    await svc.tickAt(new Date('2026-06-15T11:49:00.000Z'));

    expect(dispatchToUser).toHaveBeenCalledTimes(1);
    expect(dispatchToUser.mock.calls[0][0]).toBe('org-1');
    expect(dispatchToUser.mock.calls[0][1].type).toBe(NotificationType.CLEANUP_EVENT);
    expect(dispatchToUser.mock.calls[0][1].data).toMatchObject({
      eventId: 'evt-1',
      kind: 'cleanup_ending_soon',
    });
  });

  it('skips rows without organizer', async () => {
    const prisma = {
      $queryRaw: jest.fn().mockResolvedValue([
        {
          id: 'evt-1',
          organizerId: null,
          title: 'X',
          endAt: new Date(),
        },
      ]),
    } as unknown as PrismaService;
    const dispatchToUser = jest.fn();
    const dispatcher = { dispatchToUser } as unknown as NotificationDispatcherService;

    const svc = new EventEndSoonNotifierService(prisma, dispatcher);
    await svc.tickAt(new Date());

    expect(dispatchToUser).not.toHaveBeenCalled();
  });
});
