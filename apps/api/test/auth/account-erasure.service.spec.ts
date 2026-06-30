/// <reference types="jest" />
import { UserStatus } from '../../src/prisma-client';
import { AccountErasureService } from '../../src/auth/services/account-erasure.service';

describe('AccountErasureService', () => {
  const siteCommentsCount = {
    reconcileSitesForAuthor: jest.fn().mockResolvedValue(undefined),
  };

  it('anonymizes user and clears device tokens', async () => {
    const sessionRevocation = { revokeAllForUser: jest.fn().mockResolvedValue(undefined) };
    const reportsUpload = { deleteObjectByKey: jest.fn().mockResolvedValue(undefined) };
    const tx = {
      userDeviceToken: { deleteMany: jest.fn().mockResolvedValue({ count: 1 }) },
      userNotification: {
        findMany: jest
          .fn()
          .mockResolvedValueOnce([{ id: 'n1' }])
          .mockResolvedValue([]),
        deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      notificationOutbox: { deleteMany: jest.fn().mockResolvedValue({ count: 0 }) },
      siteComment: { updateMany: jest.fn().mockResolvedValue({ count: 0 }) },
      eventChatMessage: { updateMany: jest.fn().mockResolvedValue({ count: 0 }) },
      user: { update: jest.fn().mockResolvedValue({}) },
    };
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'user-1',
          status: UserStatus.ACTIVE,
          avatarObjectKey: null,
        }),
      },
      $transaction: jest.fn(async (fn: (t: typeof tx) => Promise<void>) => fn(tx)),
    };
    const svc = new AccountErasureService(
      prisma as never,
      sessionRevocation as never,
      reportsUpload as never,
      siteCommentsCount as never,
    );
    await svc.eraseUserAccount('user-1');
    expect(sessionRevocation.revokeAllForUser).toHaveBeenCalledWith('user-1', 'account_deleted');
    expect(siteCommentsCount.reconcileSitesForAuthor).toHaveBeenCalledWith('user-1');
    expect(tx.user.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'user-1' },
        data: expect.objectContaining({
          status: UserStatus.DELETED,
          firstName: '',
          lastName: '',
        }),
      }),
    );
  });

  it('deletes avatar from object storage when present', async () => {
    const sessionRevocation = { revokeAllForUser: jest.fn().mockResolvedValue(undefined) };
    const reportsUpload = { deleteObjectByKey: jest.fn().mockResolvedValue(undefined) };
    const tx = {
      userDeviceToken: { deleteMany: jest.fn().mockResolvedValue({ count: 0 }) },
      userNotification: { findMany: jest.fn().mockResolvedValue([]) },
      notificationOutbox: { deleteMany: jest.fn().mockResolvedValue({ count: 0 }) },
      siteComment: { updateMany: jest.fn().mockResolvedValue({ count: 0 }) },
      eventChatMessage: { updateMany: jest.fn().mockResolvedValue({ count: 0 }) },
      user: { update: jest.fn().mockResolvedValue({}) },
    };
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'user-1',
          status: UserStatus.ACTIVE,
          avatarObjectKey: 'avatars/user-1.jpg',
        }),
      },
      $transaction: jest.fn(async (fn: (t: typeof tx) => Promise<void>) => fn(tx)),
    };
    const svc = new AccountErasureService(
      prisma as never,
      sessionRevocation as never,
      reportsUpload as never,
      siteCommentsCount as never,
    );
    await svc.eraseUserAccount('user-1');
    expect(reportsUpload.deleteObjectByKey).toHaveBeenCalledWith('avatars/user-1.jpg');
  });

  it('scrubs event chat system messages for the erased user', async () => {
    const sessionRevocation = { revokeAllForUser: jest.fn().mockResolvedValue(undefined) };
    const reportsUpload = { deleteObjectByKey: jest.fn().mockResolvedValue(undefined) };
    const tx = {
      userDeviceToken: { deleteMany: jest.fn().mockResolvedValue({ count: 0 }) },
      userNotification: { findMany: jest.fn().mockResolvedValue([]) },
      notificationOutbox: { deleteMany: jest.fn().mockResolvedValue({ count: 0 }) },
      siteComment: { updateMany: jest.fn().mockResolvedValue({ count: 0 }) },
      eventChatMessage: { updateMany: jest.fn().mockResolvedValue({ count: 1 }) },
      user: { update: jest.fn().mockResolvedValue({}) },
    };
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'user-1',
          status: UserStatus.ACTIVE,
          avatarObjectKey: null,
        }),
      },
      $transaction: jest.fn(async (fn: (t: typeof tx) => Promise<void>) => fn(tx)),
    };
    const svc = new AccountErasureService(
      prisma as never,
      sessionRevocation as never,
      reportsUpload as never,
      siteCommentsCount as never,
    );
    await svc.eraseUserAccount('user-1');
    expect(tx.eventChatMessage.updateMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ authorId: 'user-1' }),
      }),
    );
    expect(tx.eventChatMessage.updateMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          authorId: 'user-1',
          messageType: expect.anything(),
        }),
        data: expect.objectContaining({
          systemPayload: expect.objectContaining({ scrubbed: true }),
        }),
      }),
    );
  });

  it('is idempotent when user is already deleted', async () => {
    const sessionRevocation = { revokeAllForUser: jest.fn().mockResolvedValue(undefined) };
    const reportsUpload = { deleteObjectByKey: jest.fn().mockResolvedValue(undefined) };
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'user-1',
          status: UserStatus.DELETED,
          avatarObjectKey: null,
        }),
      },
      $transaction: jest.fn(),
    };
    const svc = new AccountErasureService(
      prisma as never,
      sessionRevocation as never,
      reportsUpload as never,
      siteCommentsCount as never,
    );
    await svc.eraseUserAccount('user-1');
    expect(prisma.$transaction).not.toHaveBeenCalled();
    expect(sessionRevocation.revokeAllForUser).not.toHaveBeenCalled();
  });
});
