import { UserActivityService } from '../../src/active-users/services/user-activity.service';
import { ActiveUsersRealtimeService } from '../../src/active-users/services/active-users-realtime.service';

describe('UserActivityService', () => {
  it('publishes feed item after persist', async () => {
    const realtime = new ActiveUsersRealtimeService();
    const publish = jest.spyOn(realtime, 'publishActivityEvent');
    const prisma = {
      userActivityEvent: {
        create: jest.fn().mockResolvedValue({
          id: 'evt-1',
          userId: 'user-1',
          type: 'LOGIN',
          screen: null,
          occurredAt: new Date('2026-06-07T12:00:00Z'),
          user: { firstName: 'Ana', lastName: 'Test' },
        }),
      },
    };
    const service = new UserActivityService(prisma as never, realtime);

    await service.recordSystemEvent({ userId: 'user-1', type: 'LOGIN' });

    expect(publish).toHaveBeenCalledWith(
      expect.objectContaining({
        type: 'activity_event',
        event: expect.objectContaining({ userId: 'user-1', type: 'LOGIN' }),
      }),
    );
  });
});
