import { ForbiddenException } from '@nestjs/common';
import { FeatureFlagsService } from '../../src/feature-flags/services/feature-flags.service';
import { Role } from '../../src/prisma-client';

describe('FeatureFlagsService', () => {
  it('getPublicMap returns default flag keys after ensureDefaults', async () => {
    const prisma = {
      featureFlag: {
        upsert: jest.fn().mockResolvedValue({}),
        findMany: jest.fn().mockResolvedValue([
          { key: 'email_enabled', enabled: false },
          { key: 'notifications_inbox_enabled', enabled: true },
        ]),
      },
    };
    const service = new FeatureFlagsService(
      prisma as never,
      { log: jest.fn() } as never,
      { get: jest.fn() } as never,
      { emit: jest.fn() } as never,
    );
    const map = await service.getPublicMap();
    expect(map.email_enabled).toBe(false);
    expect(map.notifications_inbox_enabled).toBe(true);
  });

  it('ensureDefaults is idempotent on repeated calls', async () => {
    const upsert = jest.fn().mockResolvedValue({});
    const findMany = jest.fn().mockResolvedValue([]);
    const prisma = { featureFlag: { upsert, findMany } };
    const service = new FeatureFlagsService(
      prisma as never,
      { log: jest.fn() } as never,
      { get: jest.fn() } as never,
      { emit: jest.fn() } as never,
    );
    await service.ensureDefaults();
    await service.ensureDefaults();
    expect(upsert.mock.calls.length).toBeGreaterThan(0);
  });

  it('isNotificationsInboxEnabled respects env and DB flag', async () => {
    const prisma = {
      featureFlag: {
        upsert: jest.fn().mockResolvedValue({}),
        findUnique: jest.fn().mockResolvedValue({
          key: 'notifications_inbox_enabled',
          enabled: true,
        }),
      },
    };
    const config = { get: jest.fn().mockReturnValue('true') };
    const service = new FeatureFlagsService(
      prisma as never,
      { log: jest.fn() } as never,
      config as never,
      { emit: jest.fn() } as never,
    );
    await expect(service.isNotificationsInboxEnabled()).resolves.toBe(true);
  });

  it('applyRemoteFeatureFlagInvalidation clears public map cache', async () => {
    const prisma = {
      featureFlag: {
        upsert: jest.fn().mockResolvedValue({}),
        findMany: jest.fn().mockResolvedValue([{ key: 'email_enabled', enabled: false }]),
      },
    };
    const service = new FeatureFlagsService(
      prisma as never,
      { log: jest.fn() } as never,
      { get: jest.fn() } as never,
      { emit: jest.fn() } as never,
    );
    await service.getPublicMap();
    service.applyRemoteFeatureFlagInvalidation();
    await service.getPublicMap();
    expect(prisma.featureFlag.findMany).toHaveBeenCalledTimes(2);
  });

  it('listForAdmin returns rows after ensureDefaults', async () => {
    const prisma = {
      featureFlag: {
        upsert: jest.fn().mockResolvedValue({}),
        findMany: jest.fn().mockResolvedValue([
          {
            key: 'email_enabled',
            enabled: true,
            metadata: null,
            updatedAt: new Date('2026-01-01'),
          },
        ]),
      },
    };
    const service = new FeatureFlagsService(
      prisma as never,
      { log: jest.fn() } as never,
      { get: jest.fn() } as never,
      { emit: jest.fn() } as never,
    );
    const rows = await service.listForAdmin();
    expect(rows[0]?.key).toBe('email_enabled');
  });

  it('patch updates flag for admin', async () => {
    const prisma = {
      featureFlag: {
        upsert: jest.fn().mockResolvedValue({}),
        update: jest.fn().mockResolvedValue({ key: 'email_enabled', enabled: true }),
      },
    };
    const audit = { log: jest.fn().mockResolvedValue(undefined) };
    const events = { emit: jest.fn() };
    const service = new FeatureFlagsService(
      prisma as never,
      audit as never,
      { get: jest.fn() } as never,
      events as never,
    );
    const result = await service.patch(
      'email_enabled',
      { enabled: true },
      {
        userId: 'admin-1',
        role: Role.ADMIN,
        email: 'admin@example.com',
        phoneNumber: '+38970000001',
      },
    );
    expect(result.enabled).toBe(true);
    expect(events.emit).toHaveBeenCalledWith('feature_flags.patch');
  });

  it('isPushRealtimeSocketEnabled uses env default when row missing', async () => {
    const prisma = {
      featureFlag: {
        upsert: jest.fn().mockResolvedValue({}),
        findUnique: jest.fn().mockResolvedValue(null),
      },
    };
    const config = { get: jest.fn().mockReturnValue('false') };
    const service = new FeatureFlagsService(
      prisma as never,
      { log: jest.fn() } as never,
      config as never,
      { emit: jest.fn() } as never,
    );
    await expect(service.isPushRealtimeSocketEnabled()).resolves.toBe(false);
  });

  it('patch rejects non-admin', async () => {
    const service = new FeatureFlagsService(
      { featureFlag: { upsert: jest.fn() } } as never,
      { log: jest.fn() } as never,
      { get: jest.fn() } as never,
      { emit: jest.fn() } as never,
    );
    await expect(
      service.patch(
        'email_enabled',
        { enabled: true },
        {
          userId: 'u1',
          role: Role.USER,
          email: 'u@example.com',
          phoneNumber: '+38970000002',
        },
      ),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });
});
