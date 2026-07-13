/// <reference types="jest" />

import { NotFoundException } from '@nestjs/common';
import { SiteStatus } from '../../src/prisma-client';
import { SitesShareCardQueryService } from '../../src/sites/services/sites-share-card-query.service';
import type { PrismaService } from '../../src/prisma/prisma.service';
import type { ReportsUploadService } from '../../src/reports/services/reports-upload.service';

describe('SitesShareCardQueryService.findPublicShareCard', () => {
  function buildService(
    prisma: Pick<PrismaService, 'site' | 'cleanupEvent'>,
    upload?: Partial<ReportsUploadService>,
  ): SitesShareCardQueryService {
    const reportsUpload = {
      signUrls: jest.fn(async (urls: string[]) => urls.map((u) => `signed:${u}`)),
      signPrivateObjectKey: jest.fn(async () => 'signed-avatar'),
      getPublicUrlsForKeys: jest.fn((keys: string[]) => keys.map((k) => `https://cdn.example/${k}`)),
      ...upload,
    } as unknown as ReportsUploadService;
    return new SitesShareCardQueryService(prisma as PrismaService, reportsUpload);
  }

  const baseSite = {
    id: 'site1',
    address: 'Skopje',
    description: 'Riverside litter',
    status: SiteStatus.VERIFIED,
    latitude: 41.99,
    longitude: 21.43,
    upvotesCount: 3,
    commentsCount: 1,
    sharesCount: 2,
    savesCount: 0,
    heroReport: {
      title: 'Illegal dump near river',
      description: 'Bags and plastic along the bank',
      mediaUrls: ['https://cdn.example/a.jpg'],
      category: 'ILLEGAL_LANDFILL',
      severity: 3,
      cleanupEffort: 'THREE_TO_FIVE',
      createdAt: new Date('2026-01-15T10:00:00.000Z'),
      reporterId: 'user1',
      reporter: {
        firstName: 'Ana',
        lastName: 'Petrovska',
        avatarObjectKey: 'avatars/u1.jpg',
        status: 'ACTIVE',
      },
    },
    reports: [{ title: 'Fallback title', description: null, mediaUrls: [], category: null, severity: null, cleanupEffort: null, createdAt: new Date(), reporterId: null, reporter: null }],
    events: [],
    resolutions: [],
  };

  it('throws NotFound when site is missing or not shareable', async () => {
    const prisma = {
      site: { findFirst: jest.fn().mockResolvedValue(null) },
      cleanupEvent: { findMany: jest.fn() },
    } as unknown as PrismaService;
    const svc = buildService(prisma);

    await expect(svc.findPublicShareCard('missing-id')).rejects.toBeInstanceOf(NotFoundException);
  });

  it('returns share payload with hero title, address-based site label, and reporter', async () => {
    const prisma = {
      site: {
        findFirst: jest.fn().mockResolvedValue(baseSite),
      },
      cleanupEvent: { findMany: jest.fn() },
    } as unknown as PrismaService;
    const svc = buildService(prisma);

    const card = await svc.findPublicShareCard('site1');

    expect(card.id).toBe('site1');
    expect(card.title).toBe('Illegal dump near river');
    expect(card.siteLabel).toBe('Skopje');
    expect(card.status).toBe(SiteStatus.VERIFIED);
    expect(card.description).toBe('Bags and plastic along the bank');
    expect(card.address).toBe('Skopje');
    expect(card.latitude).toBe(41.99);
    expect(card.longitude).toBe(21.43);
    expect(card.mediaUrls).toEqual(['signed:https://cdn.example/a.jpg']);
    expect(card.category).toBe('ILLEGAL_LANDFILL');
    expect(card.severity).toBe(3);
    expect(card.cleanupEffort).toBe('THREE_TO_FIVE');
    expect(card.upvotesCount).toBe(3);
    expect(card.ogImageUrl).toBe('signed:https://cdn.example/a.jpg');
    expect(card.reporter).toEqual({
      displayLabel: 'Ana Petrovska',
      avatarUrl: 'signed-avatar',
      isDeleted: false,
      isAnonymous: false,
    });
    expect(card.events).toEqual([]);
    expect(card.cleanupEvidenceUrls).toEqual([]);
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
          ...baseSite,
          id: 'site2',
          address: null,
          description: 'Park area',
          status: SiteStatus.CLEANED,
          heroReport: null,
          reports: [
            {
              title: 'Park cleanup needed',
              description: 'Glass bottles',
              mediaUrls: [],
              category: 'OTHER',
              severity: 2,
              cleanupEffort: null,
              createdAt: new Date('2026-02-01T12:00:00.000Z'),
              reporterId: null,
              reporter: null,
            },
          ],
          resolutions: [{ mediaUrls: ['https://cdn.example/after.jpg'] }],
        }),
      },
      cleanupEvent: {
        findMany: jest.fn().mockResolvedValue([
          {
            afterImageKeys: ['events/after1.jpg'],
            evidencePhotos: [{ objectKey: 'events/evidence1.jpg' }],
          },
        ]),
      },
    } as unknown as PrismaService;
    const svc = buildService(prisma);

    const card = await svc.findPublicShareCard('site2');

    expect(card.title).toBe('Park cleanup needed');
    expect(card.siteLabel).toBe('Park area');
    expect(card.status).toBe(SiteStatus.CLEANED);
    expect(card.cleanupEvidenceUrls).toEqual([
      'signed:https://cdn.example/after.jpg',
      'signed:https://cdn.example/events/after1.jpg',
      'signed:https://cdn.example/events/evidence1.jpg',
    ]);
    expect(card.ogImageUrl).toBe('signed:https://cdn.example/after.jpg');
  });

  it('skips cleanup evidence collection when site is not CLEANED', async () => {
    const cleanupEventFindMany = jest.fn();
    const prisma = {
      site: {
        findFirst: jest.fn().mockResolvedValue({
          ...baseSite,
          resolutions: [{ mediaUrls: ['https://cdn.example/should-skip.jpg'] }],
        }),
      },
      cleanupEvent: { findMany: cleanupEventFindMany },
    } as unknown as PrismaService;
    const svc = buildService(prisma);

    const card = await svc.findPublicShareCard('site1');
    expect(card.cleanupEvidenceUrls).toEqual([]);
    expect(cleanupEventFindMany).not.toHaveBeenCalled();
  });

  it('returns empty media and null ogImage when no photos exist', async () => {
    const prisma = {
      site: {
        findFirst: jest.fn().mockResolvedValue({
          ...baseSite,
          heroReport: {
            ...baseSite.heroReport!,
            mediaUrls: [],
            reporter: null,
            reporterId: null,
          },
          reports: [],
        }),
      },
      cleanupEvent: { findMany: jest.fn() },
    } as unknown as PrismaService;
    const svc = buildService(prisma);

    const card = await svc.findPublicShareCard('site1');
    expect(card.mediaUrls).toEqual([]);
    expect(card.ogImageUrl).toBeNull();
    expect(card.reporter).toBeNull();
  });
});
