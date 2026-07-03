import { DevicePlatform, Role } from '../../src/prisma-client';
import { ActiveUsersPresenceService } from '../../src/active-users/services/active-users-presence.service';
import { ActiveUsersRealtimeService } from '../../src/active-users/services/active-users-realtime.service';
import { PresenceStoreService } from '../../src/active-users/services/presence-store.service';
import { UserActivityService } from '../../src/active-users/services/user-activity.service';

describe('ActiveUsersPresenceService', () => {
  const user = {
    userId: 'user-1',
    email: 'u@test.com',
    phoneNumber: '+38970000000',
    role: Role.USER,
    sessionId: 'sess-1',
  };

  let presence: ActiveUsersPresenceService;
  let realtime: ActiveUsersRealtimeService;
  let activity: jest.Mocked<Pick<UserActivityService, 'recordClientEvent'>>;
  let prisma: {
    user: { update: jest.Mock; findMany: jest.Mock };
    userSession: { updateMany: jest.Mock };
  };

  beforeEach(() => {
    delete process.env.REDIS_URL;
    realtime = new ActiveUsersRealtimeService();
    activity = { recordClientEvent: jest.fn().mockResolvedValue(undefined) };
    prisma = {
      user: {
        update: jest.fn().mockResolvedValue({}),
        findMany: jest.fn().mockResolvedValue([
          {
            id: 'user-1',
            firstName: 'Test',
            lastName: 'User',
            email: 'u@test.com',
            role: Role.USER,
            avatarObjectKey: null,
          },
        ]),
      },
      userSession: { updateMany: jest.fn().mockResolvedValue({ count: 1 }) },
    };
    presence = new ActiveUsersPresenceService(
      prisma as never,
      realtime,
      activity as never,
      new PresenceStoreService(),
      {
        signPrivateObjectKey: jest
          .fn()
          .mockImplementation(async (key: string | null) =>
            key ? `https://signed.example/${key}` : null,
          ),
      } as never,
    );
  });

  it('marks foreground heartbeat as online', async () => {
    await presence.heartbeat(user, {
      screen: 'Feed',
      appState: 'foreground',
      platform: DevicePlatform.IOS,
      deviceId: 'dev-1',
      appVersion: '1.0.0',
    });

    const counts = await presence.countByStatus();
    expect(counts.total).toBe(1);
    expect(counts.online).toBe(1);
  });

  it('records screen view on screen change', async () => {
    await presence.heartbeat(user, {
      screen: 'Feed',
      appState: 'foreground',
      platform: DevicePlatform.IOS,
      deviceId: 'dev-1',
    });
    await presence.heartbeat(user, {
      screen: 'Map',
      appState: 'foreground',
      platform: DevicePlatform.IOS,
      deviceId: 'dev-1',
    });

    expect(activity.recordClientEvent).toHaveBeenCalledWith(
      user,
      expect.objectContaining({ type: 'SCREEN_VIEW', screen: 'Map' }),
    );
  });

  it('signs avatar URLs in list rows', async () => {
    prisma.user.findMany.mockResolvedValue([
      {
        id: 'user-1',
        firstName: 'Test',
        lastName: 'User',
        email: 'u@test.com',
        role: Role.USER,
        avatarObjectKey: 'avatars/user-1.jpg',
      },
    ]);

    await presence.heartbeat(user, {
      screen: 'Feed',
      appState: 'foreground',
      platform: DevicePlatform.IOS,
      deviceId: 'dev-1',
    });

    const { rows } = await presence.listActiveRows();
    expect(rows).toHaveLength(1);
    expect(rows[0]?.avatarUrl).toBe('https://signed.example/avatars/user-1.jpg');
  });

  it('removes device on offline beacon', async () => {
    await presence.heartbeat(user, {
      screen: 'Feed',
      appState: 'foreground',
      platform: DevicePlatform.ANDROID,
      deviceId: 'dev-1',
    });
    await presence.offline(user, 'dev-1');
    const counts = await presence.countByStatus();
    expect(counts.total).toBe(0);
  });

  afterEach(async () => {
    await realtime?.onModuleDestroy();
  });
});
