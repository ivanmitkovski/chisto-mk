/// <reference types="jest" />
import { UserStatus } from '../../src/prisma-client';
import { AccountErasureService } from '../../src/auth/account-erasure.service';

describe('AccountErasureService', () => {
  it('anonymizes user and clears device tokens', async () => {
    const sessionRevocation = { revokeAllForUser: jest.fn().mockResolvedValue(undefined) };
    const tx = {
      userDeviceToken: { deleteMany: jest.fn().mockResolvedValue({ count: 1 }) },
      userNotification: {
        findMany: jest.fn().mockResolvedValue([{ id: 'n1' }]),
        deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      notificationOutbox: { deleteMany: jest.fn().mockResolvedValue({ count: 0 }) },
      siteComment: { updateMany: jest.fn().mockResolvedValue({ count: 0 }) },
      eventChatMessage: { updateMany: jest.fn().mockResolvedValue({ count: 0 }) },
      user: { update: jest.fn().mockResolvedValue({}) },
    };
    const prisma = {
      $transaction: jest.fn(async (fn: (t: typeof tx) => Promise<void>) => fn(tx)),
    };
    const svc = new AccountErasureService(prisma as never, sessionRevocation as never);
    await svc.eraseUserAccount('user-1');
    expect(sessionRevocation.revokeAllForUser).toHaveBeenCalledWith('user-1', 'account_deleted');
    expect(tx.user.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'user-1' },
        data: expect.objectContaining({ status: UserStatus.DELETED }),
      }),
    );
  });
});
