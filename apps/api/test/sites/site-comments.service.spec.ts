/// <reference types="jest" />
import { BadRequestException } from '@nestjs/common';
import { SiteCommentsService } from '../../src/sites/site-comments.service';
import { Role } from '../../src/prisma-client';
import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';

describe('SiteCommentsService', () => {
  const user: AuthenticatedUser = {
    userId: 'u1',
    email: 'u@test.mk',
    phoneNumber: '+38970000000',
    role: Role.USER,
  };

  it('rejects empty comment body', async () => {
    const prisma = {} as never;
    const engagement = { ensureSiteExists: jest.fn().mockResolvedValue(undefined) } as never;
    const svc = new SiteCommentsService(prisma, engagement);

    await expect(
      svc.createSiteComment('site-1', { body: '   ', parentId: null } as never, user),
    ).rejects.toBeInstanceOf(BadRequestException);
  });
});
