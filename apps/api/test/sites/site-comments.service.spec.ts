/// <reference types="jest" />
import { BadRequestException } from '@nestjs/common';
import { SiteCommentsService } from '../../src/sites/site-comments.service';
import { SiteCommentsSort } from '../../src/sites/dto/list-site-comments-query.dto';
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
    const uploads = { signPrivateObjectKey: jest.fn().mockResolvedValue(null) } as never;
    const svc = new SiteCommentsService(prisma, engagement, uploads);

    await expect(
      svc.createSiteComment('site-1', { body: '   ', parentId: null } as never, user),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('paginates direct replies when parentId is set (page 2)', async () => {
    const t3 = new Date('2026-01-01T03:00:00.000Z');
    const prisma = {
      siteComment: {
        count: jest.fn(async () => 3),
        findMany: jest.fn(async () => [
          {
            id: 'c3',
            parentId: 'root1',
            body: 'third',
            createdAt: t3,
            authorId: 'u1',
            likesCount: 0,
            author: { firstName: 'A', lastName: 'B' },
            likes: [],
          },
        ]),
      },
    } as never;
    const engagement = { ensureSiteExists: jest.fn().mockResolvedValue(undefined) } as never;
    const uploads = { signPrivateObjectKey: jest.fn().mockResolvedValue(null) } as never;
    const svc = new SiteCommentsService(prisma, engagement, uploads);

    const out = await svc.findSiteComments(
      'site-1',
      { parentId: 'root1', page: 2, limit: 2, sort: SiteCommentsSort.NEW } as never,
      user,
    );

    expect((prisma as { siteComment: { count: jest.Mock } }).siteComment.count).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ parentId: 'root1', siteId: 'site-1', isDeleted: false }),
      }),
    );
    expect((prisma as { siteComment: { findMany: jest.Mock } }).siteComment.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ parentId: 'root1' }),
        skip: 2,
        take: 2,
      }),
    );
    expect(out.meta).toEqual({ page: 2, limit: 2, total: 3 });
    expect(out.data).toHaveLength(1);
    expect(out.data[0]?.id).toBe('c3');
  });

  it('builds comment tree from a single findMany in tree mode', async () => {
    const root = {
      id: 'r1',
      parentId: null,
      body: 'root',
      createdAt: new Date('2026-01-02T00:00:00.000Z'),
      authorId: 'u1',
      likesCount: 1,
      author: { firstName: 'A', lastName: 'B' },
      likes: [{ id: 'l1' }],
    };
    const child = {
      id: 'c1',
      parentId: 'r1',
      body: 'reply',
      createdAt: new Date('2026-01-02T01:00:00.000Z'),
      authorId: 'u2',
      likesCount: 0,
      author: { firstName: 'C', lastName: 'D' },
      likes: [],
    };
    const prisma = {
      siteComment: {
        findMany: jest.fn(async () => [root, child]),
        count: jest.fn(async () => 1),
      },
    } as never;
    const engagement = { ensureSiteExists: jest.fn().mockResolvedValue(undefined) } as never;
    const uploads = { signPrivateObjectKey: jest.fn().mockResolvedValue(null) } as never;
    const svc = new SiteCommentsService(prisma, engagement, uploads);

    const out = await svc.findSiteComments(
      'site-1',
      { page: 1, limit: 10, sort: SiteCommentsSort.NEW } as never,
      user,
    );

    expect((prisma as { siteComment: { findMany: jest.Mock } }).siteComment.findMany).toHaveBeenCalledTimes(1);
    expect(out.meta.total).toBe(1);
    expect(out.data).toHaveLength(1);
    expect(out.data[0]?.replies).toHaveLength(1);
    expect(out.data[0]?.replies[0]?.id).toBe('c1');
  });
});
