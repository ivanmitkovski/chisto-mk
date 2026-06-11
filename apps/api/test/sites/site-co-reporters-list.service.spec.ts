import { NotFoundException } from '@nestjs/common';
import { SiteCoReportersListService } from '../../src/sites/services/site-co-reporters-list.service';

describe('SiteCoReportersListService', () => {
  const siteEngagement = { ensureSiteExists: jest.fn(async () => undefined) };
  const reportsUploadService = {
    resolveUserAvatarUrl: jest.fn(async (key: string | null) =>
      key ? `https://signed/${key}` : null,
    ),
  };
  const siteDetailRepository = {
    findSiteStatusById: jest.fn(async () => ({ status: 'VERIFIED' })),
    viewerCanAccessReportedSite: jest.fn(async () => false),
  };

  beforeEach(() => {
    jest.clearAllMocks();
    siteDetailRepository.findSiteStatusById.mockResolvedValue({ status: 'VERIFIED' });
    siteDetailRepository.viewerCanAccessReportedSite.mockResolvedValue(false);
  });

  it('returns original reporter first on page 1 then merged co-reporters', async () => {
    const prisma = {
      report: {
        findFirst: jest.fn(async () => ({
          reporterId: 'user-original',
          createdAt: new Date('2026-01-01T00:00:00.000Z'),
          reporter: {
            firstName: 'Ana',
            lastName: 'Original',
            avatarObjectKey: 'avatar-o',
          },
        })),
      },
      reportCoReporter: {
        groupBy: jest.fn(async () => [
          { userId: 'user-co', _min: { reportedAt: new Date('2026-02-01T00:00:00.000Z') } },
        ]),
      },
      user: {
        findMany: jest.fn(async () => [
          {
            id: 'user-original',
            firstName: 'Ana',
            lastName: 'Original',
            avatarObjectKey: 'avatar-o',
          },
          {
            id: 'user-co',
            firstName: 'Ben',
            lastName: 'Co',
            avatarObjectKey: 'avatar-c',
          },
        ]),
      },
    };

    const service = new SiteCoReportersListService(
      prisma as any,
      siteEngagement as any,
      reportsUploadService as any,
      siteDetailRepository as any,
    );

    const result = await service.findSiteCoReporters('site-1', { page: 1, limit: 50 });

    expect(result.meta.total).toBe(2);
    expect(result.data).toHaveLength(2);
    expect(result.data[0]).toMatchObject({
      firstName: 'Ana',
      lastName: 'Original',
      isOriginalReporter: true,
    });
    expect(result.data[1]).toMatchObject({
      firstName: 'Ben',
      lastName: 'Co',
      isOriginalReporter: false,
    });
    expect(result.data[0].id).not.toBe('user-original');
    expect(result.meta.hasMore).toBe(false);
  });

  it('paginates co-reporters after original reporter slot on page 1', async () => {
    const prisma = {
      report: {
        findFirst: jest.fn(async () => ({
          reporterId: 'user-original',
          createdAt: new Date('2026-01-01T00:00:00.000Z'),
          reporter: {
            firstName: 'Ana',
            lastName: 'Original',
            avatarObjectKey: null,
          },
        })),
      },
      reportCoReporter: {
        groupBy: jest.fn(async () => [
          { userId: 'user-co-1', _min: { reportedAt: new Date('2026-02-01T00:00:00.000Z') } },
          { userId: 'user-co-2', _min: { reportedAt: new Date('2026-03-01T00:00:00.000Z') } },
        ]),
      },
      user: {
        findMany: jest.fn(async ({ where }: { where: { id: { in: string[] } } }) =>
          where.id.in.map((id) => ({
            id,
            firstName: id,
            lastName: 'User',
            avatarObjectKey: null,
          })),
        ),
      },
    };

    const service = new SiteCoReportersListService(
      prisma as any,
      siteEngagement as any,
      reportsUploadService as any,
      siteDetailRepository as any,
    );

    const page1 = await service.findSiteCoReporters('site-1', { page: 1, limit: 1 });
    expect(page1.data).toHaveLength(1);
    expect(page1.data[0].isOriginalReporter).toBe(true);
    expect(page1.meta.hasMore).toBe(true);

    const page2 = await service.findSiteCoReporters('site-1', { page: 2, limit: 1 });
    expect(page2.data).toHaveLength(1);
    expect(page2.data[0].isOriginalReporter).toBe(false);
    expect(page2.meta.hasMore).toBe(true);
  });

  describe('REPORTED site visibility gate', () => {
    const prisma = {
      report: { findFirst: jest.fn(async () => null) },
      reportCoReporter: { groupBy: jest.fn(async () => []) },
      user: { findMany: jest.fn(async () => []) },
    };

    const buildService = () =>
      new SiteCoReportersListService(
        prisma as any,
        siteEngagement as any,
        reportsUploadService as any,
        siteDetailRepository as any,
      );

    it('hides REPORTED site co-reporters from anonymous viewers', async () => {
      siteDetailRepository.findSiteStatusById.mockResolvedValue({ status: 'REPORTED' });

      await expect(
        buildService().findSiteCoReporters('site-1', { page: 1, limit: 50 }),
      ).rejects.toThrow(NotFoundException);
    });

    it('hides REPORTED site co-reporters from non-reporter viewers', async () => {
      siteDetailRepository.findSiteStatusById.mockResolvedValue({ status: 'REPORTED' });
      siteDetailRepository.viewerCanAccessReportedSite.mockResolvedValue(false);

      await expect(
        buildService().findSiteCoReporters('site-1', { page: 1, limit: 50 }, {
          userId: 'stranger',
        } as any),
      ).rejects.toThrow(NotFoundException);
      expect(siteDetailRepository.viewerCanAccessReportedSite).toHaveBeenCalledWith(
        'site-1',
        'stranger',
      );
    });

    it('allows the reporter to list co-reporters on their REPORTED site', async () => {
      siteDetailRepository.findSiteStatusById.mockResolvedValue({ status: 'REPORTED' });
      siteDetailRepository.viewerCanAccessReportedSite.mockResolvedValue(true);

      const result = await buildService().findSiteCoReporters(
        'site-1',
        { page: 1, limit: 50 },
        { userId: 'reporter' } as any,
      );
      expect(result.meta.total).toBe(0);
    });
  });
});
