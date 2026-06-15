/// <reference types="jest" />

import { NotFoundException } from '@nestjs/common';
import { SiteStatus } from '../../src/prisma-client';
import { SitesShareCardQueryService } from '../../src/sites/services/sites-share-card-query.service';
import type { PrismaService } from '../../src/prisma/prisma.service';

describe('SitesShareCardQueryService.findPublicShareCard', () => {
  function buildService(prisma: Pick<PrismaService, 'site'>): SitesShareCardQueryService {
    return new SitesShareCardQueryService(prisma as PrismaService);
  }

  it('throws NotFound when site is missing or not shareable', async () => {
    const prisma = {
      site: { findFirst: jest.fn().mockResolvedValue(null) },
    } as unknown as PrismaService;
    const svc = buildService(prisma);

    await expect(svc.findPublicShareCard('missing-id')).rejects.toBeInstanceOf(NotFoundException);
  });

  it('returns share payload with hero title and address-based site label', async () => {
    const prisma = {
      site: {
        findFirst: jest.fn().mockResolvedValue({
          id: 'site1',
          address: 'Skopje',
          description: 'Riverside litter',
          status: SiteStatus.VERIFIED,
          heroReport: { title: 'Illegal dump near river' },
          reports: [{ title: 'Fallback title' }],
        }),
      },
    } as unknown as PrismaService;
    const svc = buildService(prisma);

    const card = await svc.findPublicShareCard('site1');

    expect(card).toEqual({
      id: 'site1',
      title: 'Illegal dump near river',
      siteLabel: 'Skopje',
      status: SiteStatus.VERIFIED,
    });
    expect(prisma.site.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          id: 'site1',
          status: { not: SiteStatus.REPORTED },
          isArchivedByAdmin: false,
        }),
      }),
    );
  });

  it('falls back to first approved report title when hero report is absent', async () => {
    const prisma = {
      site: {
        findFirst: jest.fn().mockResolvedValue({
          id: 'site2',
          address: null,
          description: 'Park area',
          status: SiteStatus.CLEANED,
          heroReport: null,
          reports: [{ title: 'Park cleanup needed' }],
        }),
      },
    } as unknown as PrismaService;
    const svc = buildService(prisma);

    const card = await svc.findPublicShareCard('site2');

    expect(card.title).toBe('Park cleanup needed');
    expect(card.siteLabel).toBe('Park area');
    expect(card.status).toBe(SiteStatus.CLEANED);
  });
});
