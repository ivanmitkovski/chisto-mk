/// <reference types="jest" />
import { ConflictException } from '@nestjs/common';
import { ModerationService } from '../../src/moderation/services/moderation.service';
import { Role } from '../../src/prisma-client';
import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';

describe('ModerationService', () => {
  const user: AuthenticatedUser = {
    userId: 'u-blocker',
    email: 'blocker@test.mk',
    phoneNumber: '+38970000001',
    role: Role.USER,
  };

  it('blockedUserIdsFor returns blocked user ids', async () => {
    const prisma = {
      userBlock: {
        findMany: jest.fn().mockResolvedValue([
          { blockedUserId: 'u-b1' },
          { blockedUserId: 'u-b2' },
        ]),
      },
    };
    const svc = new ModerationService(prisma as never);
    await expect(svc.blockedUserIdsFor(user.userId)).resolves.toEqual(['u-b1', 'u-b2']);
    expect(prisma.userBlock.findMany).toHaveBeenCalledWith({
      where: { blockerId: user.userId },
      select: { blockedUserId: true },
    });
  });

  it('blockUser rejects self-block', async () => {
    const prisma = { userBlock: { upsert: jest.fn() } };
    const svc = new ModerationService(prisma as never);
    await expect(
      svc.blockUser(user, { blockedUserId: user.userId }),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(prisma.userBlock.upsert).not.toHaveBeenCalled();
  });

  it('blockUser upserts block row', async () => {
    const prisma = {
      userBlock: {
        upsert: jest.fn().mockResolvedValue({
          id: 'blk1',
          blockedUserId: 'u-peer',
          createdAt: new Date(),
        }),
      },
    };
    const svc = new ModerationService(prisma as never);
    await svc.blockUser(user, { blockedUserId: 'u-peer' });
    expect(prisma.userBlock.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        create: expect.objectContaining({
          blockerId: user.userId,
          blockedUserId: 'u-peer',
        }),
      }),
    );
  });

  it('unblock deletes matching row', async () => {
    const prisma = {
      userBlock: { deleteMany: jest.fn().mockResolvedValue({ count: 1 }) },
    };
    const svc = new ModerationService(prisma as never);
    await svc.unblock(user, 'u-peer');
    expect(prisma.userBlock.deleteMany).toHaveBeenCalledWith({
      where: { blockerId: user.userId, blockedUserId: 'u-peer' },
    });
  });
});
