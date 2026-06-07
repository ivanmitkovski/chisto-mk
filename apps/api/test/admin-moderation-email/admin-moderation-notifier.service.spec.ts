import { AdminModerationCategory, Role, UserStatus } from '../../src/prisma-client';
import { AdminModerationNotifierService } from '../../src/admin-moderation-email/services/admin-moderation-notifier.service';
import { AdminModerationRecipientsService } from '../../src/admin-moderation-email/services/admin-moderation-recipients.service';

describe('AdminModerationNotifierService', () => {
  it('enqueues one outbox row per eligible recipient when feature and email are enabled', async () => {
    const enqueued: unknown[] = [];
    const featureFlags = {
      isAdminModerationEmailEnabled: async () => true,
    };
    const eligibility = {
      isGloballyEnabled: async () => true,
    };
    const recipients = {
      resolveForCategory: async () => [
        {
          userId: 'u1',
          email: 'mod@chisto.mk',
          firstName: 'Mod',
          role: Role.ADMIN,
        },
      ],
    };
    const outbox = {
      enqueueMany: async (rows: unknown[]) => {
        enqueued.push(...rows);
        return rows.length;
      },
    };
    const audit = { log: jest.fn() };

    const service = new AdminModerationNotifierService(
      featureFlags as never,
      eligibility as never,
      recipients as never,
      outbox as never,
      audit as never,
    );

    await service['notifyAsync']({
      category: AdminModerationCategory.NEW_REPORT,
      resourceId: 'rep1',
      deepLinkPath: '/dashboard/reports?reportId=rep1',
      emailContext: { reportNumber: '#1' },
    });

    expect(enqueued).toHaveLength(1);
    expect(enqueued[0]).toMatchObject({
      recipientUserId: 'u1',
      category: AdminModerationCategory.NEW_REPORT,
      resourceId: 'rep1',
    });
    expect(audit.log).toHaveBeenCalledWith(
      expect.objectContaining({ action: 'MODERATION_EMAIL_ENQUEUED' }),
    );
  });

  it('skips enqueue when feature flag is off', async () => {
    const outbox = { enqueueMany: jest.fn() };
    const service = new AdminModerationNotifierService(
      { isAdminModerationEmailEnabled: async () => false } as never,
      { isGloballyEnabled: async () => true } as never,
      { resolveForCategory: async () => [{ userId: 'u1', email: 'a@b.c', firstName: 'A', role: Role.ADMIN }] } as never,
      outbox as never,
    );

    await service['notifyAsync']({
      category: AdminModerationCategory.UGC_REPORT,
      resourceId: 'ugc1',
      deepLinkPath: '/dashboard/moderation/ugc?reportId=ugc1',
      emailContext: {},
    });

    expect(outbox.enqueueMany).not.toHaveBeenCalled();
  });
});

describe('AdminModerationRecipientsService', () => {
  it('filters staff by role permission and explicit preference', async () => {
    const prisma = {
      user: {
        findMany: jest.fn().mockResolvedValue([
          {
            id: 'support1',
            email: 'support@chisto.mk',
            firstName: 'S',
            role: Role.SUPPORT,
          },
          {
            id: 'admin1',
            email: 'admin@chisto.mk',
            firstName: 'A',
            role: Role.ADMIN,
          },
        ]),
      },
    };
    const eligibility = {
      canSendToAddress: async () => true,
    };
    const preferences = {
      isEnabledForUser: async (userId: string, role: Role, _category: AdminModerationCategory) => {
        if (userId === 'support1') return false;
        return role === Role.ADMIN;
      },
    };

    const service = new AdminModerationRecipientsService(
      prisma as never,
      preferences as never,
      eligibility as never,
    );

    const list = await service.resolveForCategory(AdminModerationCategory.NEW_REPORT);
    expect(list.map((r) => r.userId)).toEqual(['admin1']);
    expect(prisma.user.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { role: { in: expect.arrayContaining([Role.SUPPORT, Role.ADMIN]) }, status: UserStatus.ACTIVE },
      }),
    );
  });
});
