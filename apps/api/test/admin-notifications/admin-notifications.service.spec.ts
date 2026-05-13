/// <reference types="jest" />

import { NotFoundException } from '@nestjs/common';
import { Role } from '../../src/prisma-client';
import { AdminNotificationsService } from '../../src/admin-notifications/admin-notifications.service';
import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';
import type { ListAdminNotificationsQueryDto } from '../../src/admin-notifications/dto/list-admin-notifications.dto';

describe('AdminNotificationsService', () => {
  const admin: AuthenticatedUser = {
    userId: 'admin-1',
    email: 'a@chisto.mk',
    phoneNumber: '+38970000001',
    role: Role.ADMIN,
  };

  it('listForAdmin returns data and meta', async () => {
    const createdAt = new Date('2026-01-01T12:00:00.000Z');
    const prisma = {
      $transaction: jest.fn((ops: [Promise<unknown>, Promise<unknown>, Promise<unknown>]) =>
        Promise.all(ops),
      ),
      adminNotification: {
        findMany: jest.fn().mockResolvedValue([
          {
            id: 'n1',
            title: 'T',
            message: 'M',
            timeLabel: 'legacy',
            tone: 'INFO',
            category: 'SYSTEM',
            isUnread: true,
            href: null,
            messageTemplateKey: null,
            messageTemplateParams: null,
            createdAt,
          },
        ]),
        count: jest.fn().mockResolvedValueOnce(1).mockResolvedValueOnce(1),
      },
    } as never;
    const svc = new AdminNotificationsService(prisma);
    const query = { page: 1, limit: 20 } as ListAdminNotificationsQueryDto;
    const out = await svc.listForAdmin(admin, query, 'en');
    expect(out.data).toHaveLength(1);
    expect(out.meta.total).toBe(1);
    expect(out.meta.unreadCount).toBe(1);
  });

  it('markOneRead throws when notification missing', async () => {
    const prisma = {
      adminNotification: {
        findFirst: jest.fn().mockResolvedValue(null),
      },
    } as never;
    const svc = new AdminNotificationsService(prisma);
    await expect(svc.markOneRead(admin, 'missing')).rejects.toBeInstanceOf(NotFoundException);
  });

  it('markOneRead skips update when already read', async () => {
    const update = jest.fn();
    const prisma = {
      adminNotification: {
        findFirst: jest.fn().mockResolvedValue({ id: 'n1', isUnread: false }),
        update,
      },
    } as never;
    const svc = new AdminNotificationsService(prisma);
    await svc.markOneRead(admin, 'n1');
    expect(update).not.toHaveBeenCalled();
  });
});
