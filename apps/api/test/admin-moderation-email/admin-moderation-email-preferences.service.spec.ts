/// <reference types="jest" />

import { AdminModerationCategory, Role } from '../../src/prisma-client';
import { AdminModerationEmailPreferencesService } from '../../src/admin-moderation-email/services/admin-moderation-email-preferences.service';

describe('AdminModerationEmailPreferencesService', () => {
  it('returns explicit override when preference row exists', async () => {
    const prisma = {
      adminEmailPreference: {
        findMany: jest.fn().mockResolvedValue([
          { category: AdminModerationCategory.NEW_REPORT, enabled: false },
        ]),
        findUnique: jest.fn().mockResolvedValue({ enabled: false }),
        upsert: jest.fn(),
      },
    };
    const service = new AdminModerationEmailPreferencesService(prisma as never);

    const list = await service.listForUser('u1', Role.ADMIN);
    const reportRow = list.find((r) => r.category === AdminModerationCategory.NEW_REPORT);
    expect(reportRow).toEqual({
      category: AdminModerationCategory.NEW_REPORT,
      enabled: false,
      source: 'explicit',
    });

    expect(await service.isEnabledForUser('u1', Role.ADMIN, AdminModerationCategory.NEW_REPORT)).toBe(
      false,
    );
  });

  it('defaults to role permission when no row', async () => {
    const prisma = {
      adminEmailPreference: {
        findMany: jest.fn().mockResolvedValue([]),
        findUnique: jest.fn().mockResolvedValue(null),
        upsert: jest.fn(),
      },
    };
    const service = new AdminModerationEmailPreferencesService(prisma as never);

    expect(
      await service.isEnabledForUser('u1', Role.ADMIN, AdminModerationCategory.NEW_REPORT),
    ).toBe(true);
    expect(
      await service.isEnabledForUser('u1', Role.USER, AdminModerationCategory.NEW_REPORT),
    ).toBe(false);
  });
});
