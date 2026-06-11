import { NotFoundException } from '@nestjs/common';
import { SiteStatus } from '../../src/prisma-client';
import { SitesMediaService } from '../../src/sites/services/sites-media.service';

describe('SitesMediaService visibility', () => {
  const siteDetailRepository = {
    findSiteStatusById: jest.fn(),
    viewerCanAccessReportedSite: jest.fn(),
  };
  const siteMediaRepository = {
    findReportsForSite: jest.fn(),
  };
  const reportsUploadService = {
    signUrls: jest.fn(),
  };

  let service: SitesMediaService;

  beforeEach(() => {
    jest.resetAllMocks();
    service = new SitesMediaService(
      siteMediaRepository as never,
      siteDetailRepository as never,
      reportsUploadService as never,
    );
  });

  it('returns SITE_NOT_FOUND for anonymous viewers on REPORTED sites', async () => {
    siteDetailRepository.findSiteStatusById.mockResolvedValue({
      id: 'site-1',
      status: SiteStatus.REPORTED,
    });

    await expect(
      service.findSiteMedia('site-1', { page: 1, limit: 20 } as never),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(siteMediaRepository.findReportsForSite).not.toHaveBeenCalled();
  });

  it('returns SITE_NOT_FOUND for non-reporters on REPORTED sites', async () => {
    siteDetailRepository.findSiteStatusById.mockResolvedValue({
      id: 'site-1',
      status: SiteStatus.REPORTED,
    });
    siteDetailRepository.viewerCanAccessReportedSite.mockResolvedValue(false);

    await expect(
      service.findSiteMedia(
        'site-1',
        { page: 1, limit: 20 } as never,
        { userId: 'other-user' } as never,
      ),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(siteMediaRepository.findReportsForSite).not.toHaveBeenCalled();
  });

  it('allows reporters to list media on REPORTED sites', async () => {
    siteDetailRepository.findSiteStatusById.mockResolvedValue({
      id: 'site-1',
      status: SiteStatus.REPORTED,
    });
    siteDetailRepository.viewerCanAccessReportedSite.mockResolvedValue(true);
    siteMediaRepository.findReportsForSite.mockResolvedValue([
      {
        id: 'report-1',
        createdAt: new Date('2026-05-01'),
        mediaUrls: ['photo.jpg'],
      },
    ]);
    reportsUploadService.signUrls.mockResolvedValue(['signed.jpg']);

    const result = await service.findSiteMedia(
      'site-1',
      { page: 1, limit: 20 } as never,
      { userId: 'reporter-1' } as never,
    );

    expect(result.data).toHaveLength(1);
    expect(result.data[0]?.url).toBe('signed.jpg');
  });
});
