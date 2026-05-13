/// <reference types="jest" />
import { DeviceTokenService } from '../../src/notifications/device-token.service';

function makePrisma() {
  return {
    userDeviceToken: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
  };
}

describe('DeviceTokenService', () => {
  it('registerDeviceToken creates new token', async () => {
    const prisma = makePrisma() as any;
    prisma.userDeviceToken.findUnique.mockResolvedValue(null);
    prisma.userDeviceToken.create.mockResolvedValue({ id: 'dt1' });

    const service = new DeviceTokenService(prisma);
    const result = await service.registerDeviceToken(
      { userId: 'u1' } as any,
      { token: 'fcm_token_abc', platform: 'ANDROID' } as any,
    );

    expect(result.id).toBe('dt1');
    expect(prisma.userDeviceToken.create).toHaveBeenCalled();
  });

  it('registerDeviceToken updates existing token for same user', async () => {
    const prisma = makePrisma() as any;
    prisma.userDeviceToken.findUnique.mockResolvedValue({
      id: 'dt1', userId: 'u1', revokedAt: null,
    });
    prisma.userDeviceToken.update.mockResolvedValue({ id: 'dt1' });

    const service = new DeviceTokenService(prisma);
    const result = await service.registerDeviceToken(
      { userId: 'u1' } as any,
      { token: 'fcm_token_abc', platform: 'ANDROID' } as any,
    );

    expect(result.id).toBe('dt1');
    expect(prisma.userDeviceToken.update).toHaveBeenCalled();
  });

  it('registerDeviceToken rejects token owned by different user', async () => {
    const prisma = makePrisma() as any;
    prisma.userDeviceToken.findUnique.mockResolvedValue({
      id: 'dt1', userId: 'u2', revokedAt: null,
    });

    const service = new DeviceTokenService(prisma);
    await expect(
      service.registerDeviceToken(
        { userId: 'u1' } as any,
        { token: 'fcm_token_abc', platform: 'ANDROID' } as any,
      ),
    ).rejects.toThrow();
  });

  it('unregisterDeviceToken revokes owned token', async () => {
    const prisma = makePrisma() as any;
    prisma.userDeviceToken.findUnique.mockResolvedValue({
      id: 'dt1', userId: 'u1',
    });
    prisma.userDeviceToken.update.mockResolvedValue({});

    const service = new DeviceTokenService(prisma);
    await service.unregisterDeviceToken({ userId: 'u1' } as any, 'fcm_token_abc');

    expect(prisma.userDeviceToken.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ revokedAt: expect.any(Date) }),
      }),
    );
  });

  it('unregisterDeviceToken ignores token owned by another user', async () => {
    const prisma = makePrisma() as any;
    prisma.userDeviceToken.findUnique.mockResolvedValue({
      id: 'dt1', userId: 'u2',
    });

    const service = new DeviceTokenService(prisma);
    await service.unregisterDeviceToken({ userId: 'u1' } as any, 'fcm_token_abc');

    expect(prisma.userDeviceToken.update).not.toHaveBeenCalled();
  });

  it('getActiveTokensForUser returns active tokens', async () => {
    const prisma = makePrisma() as any;
    prisma.userDeviceToken.findMany.mockResolvedValue([
      { id: 'dt1', token: 'tok1', platform: 'ANDROID' },
    ]);

    const service = new DeviceTokenService(prisma);
    const result = await service.getActiveTokensForUser('u1');

    expect(result).toHaveLength(1);
    expect(prisma.userDeviceToken.findMany).toHaveBeenCalledWith({
      where: { userId: 'u1', revokedAt: null },
      select: { id: true, token: true, platform: true },
    });
  });
});
