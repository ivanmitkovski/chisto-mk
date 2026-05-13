/// <reference types="jest" />
import { NotificationPreferencesService } from '../../src/notifications/notification-preferences.service';

function makePrisma() {
  return {
    userNotificationPreference: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      upsert: jest.fn(),
      update: jest.fn(),
    },
  };
}

describe('NotificationPreferencesService', () => {
  it('listPreferences returns all notification types with defaults', async () => {
    const prisma = makePrisma() as any;
    prisma.userNotificationPreference.findMany.mockResolvedValue([
      { type: 'UPVOTE', muted: true, mutedUntil: null },
    ]);

    const service = new NotificationPreferencesService(prisma);
    const result = await service.listPreferences({ userId: 'u1' } as any);

    expect(result.data.length).toBeGreaterThanOrEqual(8);
    const upvote = result.data.find((d: any) => d.type === 'UPVOTE');
    expect(upvote?.muted).toBe(true);
    const comment = result.data.find((d: any) => d.type === 'COMMENT');
    expect(comment?.muted).toBe(false);
  });

  it('updatePreference upserts muted state', async () => {
    const prisma = makePrisma() as any;
    prisma.userNotificationPreference.upsert.mockResolvedValue({
      type: 'UPVOTE', muted: true, mutedUntil: null,
    });

    const service = new NotificationPreferencesService(prisma);
    const result = await service.updatePreference(
      { userId: 'u1' } as any,
      'UPVOTE' as any,
      { muted: true },
    );

    expect(result.muted).toBe(true);
    expect(prisma.userNotificationPreference.upsert).toHaveBeenCalled();
  });

  it('isTypeMuted returns false when not muted', async () => {
    const prisma = makePrisma() as any;
    prisma.userNotificationPreference.findUnique.mockResolvedValue(null);

    const service = new NotificationPreferencesService(prisma);
    const result = await service.isTypeMuted('u1', 'UPVOTE' as any);
    expect(result).toBe(false);
  });

  it('isTypeMuted auto-unmutes expired snooze', async () => {
    const prisma = makePrisma() as any;
    const expiredDate = new Date(Date.now() - 60_000);
    prisma.userNotificationPreference.findUnique.mockResolvedValue({
      muted: true, mutedUntil: expiredDate,
    });
    prisma.userNotificationPreference.update.mockResolvedValue({});

    const service = new NotificationPreferencesService(prisma);
    const result = await service.isTypeMuted('u1', 'UPVOTE' as any);

    expect(result).toBe(false);
    expect(prisma.userNotificationPreference.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: { muted: false, mutedUntil: null },
      }),
    );
  });
});
